package dev.rgal.brackety.staff;

import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.ProfileRepository;
import dev.rgal.brackety.auth.account.ProfileType;
import dev.rgal.brackety.common.crypto.RandomTokens;
import dev.rgal.brackety.common.crypto.Sha256;
import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRepository;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventStaff;
import dev.rgal.brackety.event.EventStaffRepository;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.staff.dto.InvitationResponse;
import dev.rgal.brackety.staff.dto.InvitationView;
import java.time.Clock;
import java.time.Duration;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * The event's helpers and referees with their own accounts (F1-5, docs/modulos/ayudantes-permisos.md): the club
 * invites them by email, they accept with that same email, and the club can take them out again.
 */
@Service
public class StaffService {

    /** Pending invitations an event may have at once: enough for any club, not for a mail cannon. */
    static final int MAX_PENDING = 50;

    /** Between two emails of the same invitation, so nobody floods an inbox. */
    static final Duration RESEND_INTERVAL = Duration.ofSeconds(60);

    private final StaffInvitationRepository invitations;
    private final EventStaffRepository staff;
    private final EventRepository events;
    private final MatRepository mats;
    private final AccountRepository accounts;
    private final ProfileRepository profiles;
    private final EventAccess access;
    private final StaffEmails emails;
    private final Clock clock;

    StaffService(
            StaffInvitationRepository invitations,
            EventStaffRepository staff,
            EventRepository events,
            MatRepository mats,
            AccountRepository accounts,
            ProfileRepository profiles,
            EventAccess access,
            StaffEmails emails,
            Clock clock) {
        this.invitations = invitations;
        this.staff = staff;
        this.events = events;
        this.mats = mats;
        this.accounts = accounts;
        this.profiles = profiles;
        this.access = access;
        this.emails = emails;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public List<InvitationResponse> pending(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        var now = clock.instant();
        return invitations.findByEventIdAndAcceptedAtIsNullOrderBySentAt(eventId).stream()
                .map(i -> InvitationResponse.of(i, now))
                .toList();
    }

    /** Sends the link; inviting the same address for the same role again sends a new one. */
    @Transactional
    public InvitationResponse invite(UUID eventId, UUID accountId, String email, EventRole role) {
        access.require(eventId, accountId, EventRole.CLUB);
        if (role == EventRole.CLUB) {
            throw EventException.invalid("Invite a helper or a referee.");
        }
        var address = Account.normalizeEmail(email);
        var invited = accounts.findByEmail(address);
        if (invited.isPresent() && access.roles(eventId, invited.get().getId()).contains(role)) {
            throw EventException.conflict("ALREADY_STAFF", "They already have this role in the event.");
        }
        var now = clock.instant();
        var raw = RandomTokens.newToken();
        var invitation = invitations
                .findByEventIdAndEmailAndRoleAndAcceptedAtIsNull(eventId, address, role)
                .map(i -> {
                    if (i.getSentAt().plus(RESEND_INTERVAL).isAfter(now)) {
                        throw EventException.conflict("INVITATION_TOO_SOON", "Wait a minute before sending it again.");
                    }
                    i.resend(Sha256.hex(raw), now);
                    return i;
                })
                .orElseGet(() -> {
                    if (invitations.countByEventIdAndAcceptedAtIsNull(eventId) >= MAX_PENDING) {
                        throw EventException.conflict(
                                "TOO_MANY_INVITATIONS", "Too many pending invitations: cancel some first.");
                    }
                    return invitations.save(new StaffInvitation(eventId, address, role, Sha256.hex(raw), now));
                });
        var event = event(eventId);
        var locale = invited.map(a -> Locale.forLanguageTag(a.getLocale())).orElse(Locale.forLanguageTag("es"));
        emails.invitation(address, locale, event, organizer(event), role, raw);
        return InvitationResponse.of(invitation, now);
    }

    @Transactional
    public void cancel(UUID eventId, UUID accountId, UUID invitationId) {
        access.require(eventId, accountId, EventRole.CLUB);
        var invitation = invitations
                .findById(invitationId)
                .filter(i -> i.getEventId().equals(eventId))
                .orElseThrow(EventException::notFound);
        invitations.delete(invitation);
    }

    /** What the link offers, for whoever signed in with it; a used, expired or unknown one is 404 alike. */
    @Transactional(readOnly = true)
    public InvitationView view(String token, UUID accountId) {
        var invitation = usable(token);
        var event = event(invitation.getEventId());
        var account = accounts.findById(accountId).orElseThrow(EventException::notFound);
        return new InvitationView(
                event.getName(),
                event.getEventDate(),
                organizer(event),
                invitation.getRole(),
                invitation.getEmail(),
                invitation.getEmail().equals(account.getEmail()));
    }

    /** Adds the account to the staff. Only with the invited email: a forwarded link is no use to anyone else. */
    @Transactional
    public UUID accept(String token, UUID accountId) {
        var invitation = usable(token);
        var account = accounts.findById(accountId).orElseThrow(EventException::notFound);
        if (!invitation.getEmail().equals(account.getEmail())) {
            throw EventException.conflict("INVITATION_OTHER_EMAIL", "This invitation is for another email.");
        }
        var eventId = invitation.getEventId();
        if (!access.roles(eventId, accountId).contains(invitation.getRole())) {
            staff.save(new EventStaff(eventId, accountId, invitation.getRole()));
        }
        invitation.accept(accountId, clock.instant());
        return eventId;
    }

    /** Takes a helper or referee out of the event; a referee must leave their mat first. */
    @Transactional
    public void remove(UUID eventId, UUID accountId, UUID memberId, EventRole role) {
        access.require(eventId, accountId, EventRole.CLUB);
        if (role == EventRole.CLUB) {
            throw EventException.invalid("The club stays in its event.");
        }
        var member = staff.findByEventIdAndAccountId(eventId, memberId).stream()
                .filter(s -> s.getRole() == role)
                .findFirst()
                .orElseThrow(EventException::notFound);
        if (role == EventRole.REFEREE
                && !mats.findByEventIdAndRefereeAccountIdOrderByNumber(eventId, memberId)
                        .isEmpty()) {
            throw EventException.conflict("REFEREE_ON_MAT", "Take them off their mat first.");
        }
        staff.delete(member);
    }

    private StaffInvitation usable(String token) {
        return invitations
                .findByTokenHash(Sha256.hex(token == null ? "" : token))
                .filter(i -> i.isUsable(clock.instant()))
                .orElseThrow(EventException::notFound);
    }

    private Event event(UUID eventId) {
        return events.findById(eventId).orElseThrow(EventException::notFound);
    }

    // The club's name, as it registered; its sign-in if it has none.
    private String organizer(Event event) {
        return profiles.findByAccountId(event.getOwnerAccountId()).stream()
                .filter(p -> p.getType() == ProfileType.CLUB || p.getType() == ProfileType.EXTERNAL_ENTITY)
                .map(p -> p.getOrganizationName())
                .filter(n -> n != null && !n.isBlank())
                .findFirst()
                .orElseGet(() -> accounts.findById(event.getOwnerAccountId())
                        .map(Account::getEmail)
                        .orElse(""));
    }
}
