package dev.rgal.brackety.staff;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.TemporarySignIn;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.Profile;
import dev.rgal.brackety.auth.account.ProfileRepository;
import dev.rgal.brackety.auth.account.ProfileType;
import dev.rgal.brackety.auth.session.SessionService;
import dev.rgal.brackety.auth.session.SessionService.Session;
import dev.rgal.brackety.common.crypto.RandomTokens;
import dev.rgal.brackety.common.crypto.Sha256;
import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventPhase;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.event.EventStaff;
import dev.rgal.brackety.event.EventStaffRepository;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.event.PhaseFinished;
import dev.rgal.brackety.event.StaffNames;
import dev.rgal.brackety.staff.dto.TemporaryAccessResponse;
import java.security.SecureRandom;
import java.time.Clock;
import java.util.List;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Access by QR (Raul, 2026-11-20): someone without an account helps on the day. The club types their name and shows
 * a QR; scanning it signs them in to a temporary account that only exists in this event, with the permissions of its
 * role, while the phase lasts. The code works once and signing in closes any other session of that account; the
 * club renews it (a new code, the old device out) or ends it at any moment.
 */
@Service
class TemporaryAccessService implements TemporarySignIn {

    /** QR accesses an event may create: a whole hall's staff, not an account factory. */
    static final int MAX_PER_EVENT = 60;

    static final String LINK_PATH = "/qr?code=";

    private static final String SIGN_IN_PREFIX = "qr-";
    private static final char[] SIGN_IN_CHARS = "abcdefghjkmnpqrstuvwxyz23456789".toCharArray();
    private static final SecureRandom RANDOM = new SecureRandom();

    private final TemporaryAccessRepository accesses;
    private final AccountRepository accounts;
    private final ProfileRepository profiles;
    private final EventStaffRepository staff;
    private final MatRepository mats;
    private final EventAccess access;
    private final EventPhase phase;
    private final EventService events;
    private final StaffNames names;
    private final SessionService sessions;
    private final Clock clock;
    private final String baseUrl;

    TemporaryAccessService(
            TemporaryAccessRepository accesses,
            AccountRepository accounts,
            ProfileRepository profiles,
            EventStaffRepository staff,
            MatRepository mats,
            EventAccess access,
            EventPhase phase,
            EventService events,
            StaffNames names,
            SessionService sessions,
            Clock clock,
            @Value("${brackety.public-base-url}") String baseUrl) {
        this.accesses = accesses;
        this.accounts = accounts;
        this.profiles = profiles;
        this.staff = staff;
        this.mats = mats;
        this.access = access;
        this.phase = phase;
        this.events = events;
        this.names = names;
        this.sessions = sessions;
        this.clock = clock;
        this.baseUrl = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
    }

    @Transactional(readOnly = true)
    public List<TemporaryAccessResponse> list(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        var eventMats = mats.findByEventIdOrderByNumber(eventId);
        return accesses.findByEventIdOrderByCreatedAt(eventId).stream()
                .map(a -> response(a, eventMats, null))
                .toList();
    }

    /** {@code mat}: for a referee, the mat they take (it may have had another). */
    @Transactional
    public TemporaryAccessResponse create(UUID eventId, UUID accountId, String name, EventRole role, Integer mat) {
        access.require(eventId, accountId, EventRole.CLUB);
        phase.requireNotFinished(eventId);
        if (role == EventRole.CLUB) {
            throw EventException.invalid("A QR access is for a helper or a referee.");
        }
        if (mat != null && role != EventRole.REFEREE) {
            throw EventException.invalid("Only a referee takes a mat.");
        }
        if (accesses.countByEventId(eventId) >= MAX_PER_EVENT) {
            throw EventException.conflict("TOO_MANY_QR_ACCESSES", "This event has too many QR accesses.");
        }
        var now = clock.instant();
        var account = accounts.save(Account.temporary(newSignIn(), now));
        profiles.save(new Profile(account.getId(), ProfileType.HELPER, now));
        staff.save(new EventStaff(eventId, account.getId(), role));
        staff.flush();
        names.put(eventId, account.getId(), name.strip());
        if (mat != null) {
            events.assignReferee(eventId, mat, account.getId());
        }
        var raw = RandomTokens.newToken();
        var created = accesses.save(
                new TemporaryAccess(eventId, account.getId(), name.strip(), role, Sha256.hex(raw), accountId, now));
        return response(created, mats.findByEventIdOrderByNumber(eventId), raw);
    }

    /** A new code, at once: whoever was signed in with the old one is out. Also brings back an ended access. */
    @Transactional
    public TemporaryAccessResponse renew(UUID eventId, UUID accountId, UUID accessId) {
        access.require(eventId, accountId, EventRole.CLUB);
        phase.requireNotFinished(eventId);
        var temporary = find(eventId, accessId);
        var account = account(temporary);
        var raw = RandomTokens.newToken();
        temporary.renew(Sha256.hex(raw), clock.instant());
        account.unsuspend(clock.instant());
        sessions.closeAll(account);
        return response(temporary, mats.findByEventIdOrderByNumber(eventId), raw);
    }

    @Transactional
    public TemporaryAccessResponse end(UUID eventId, UUID accountId, UUID accessId) {
        access.require(eventId, accountId, EventRole.CLUB);
        var temporary = find(eventId, accessId);
        end(temporary);
        return response(temporary, mats.findByEventIdOrderByNumber(eventId), null);
    }

    /** Unknown, used, renewed or ended codes are all the same 401. */
    @Override
    @Transactional(noRollbackFor = AuthException.class)
    public Session signIn(String token) {
        var temporary = accesses.findByTokenHash(Sha256.hex(token == null ? "" : token))
                .filter(a -> !a.isEnded())
                .orElseThrow(AuthException::invalidLink);
        var account = account(temporary);
        temporary.signedIn(clock.instant());
        // One device at a time: the new one replaces any other.
        sessions.closeAll(account);
        return sessions.start(account);
    }

    /** The accesses live as long as the phase: once it finishes nobody signs in with them. */
    @EventListener
    void phaseFinished(PhaseFinished finished) {
        accesses.findByEventIdAndEndedAtIsNull(finished.eventId()).forEach(this::end);
    }

    private void end(TemporaryAccess temporary) {
        var account = account(temporary);
        temporary.end(clock.instant());
        account.suspend(clock.instant());
        sessions.closeAll(account);
    }

    private TemporaryAccess find(UUID eventId, UUID accessId) {
        return accesses.findById(accessId)
                .filter(a -> a.getEventId().equals(eventId))
                .orElseThrow(EventException::notFound);
    }

    private Account account(TemporaryAccess temporary) {
        return accounts.findById(temporary.getAccountId()).orElseThrow(EventException::notFound);
    }

    // Short and readable, since it shows in lists: "Juan Pérez (qr-k3f9a2)".
    private String newSignIn() {
        while (true) {
            var signIn = new StringBuilder(SIGN_IN_PREFIX);
            for (int i = 0; i < 6; i++) {
                signIn.append(SIGN_IN_CHARS[RANDOM.nextInt(SIGN_IN_CHARS.length)]);
            }
            if (accounts.findByEmail(signIn.toString()).isEmpty()) {
                return signIn.toString();
            }
        }
    }

    private TemporaryAccessResponse response(TemporaryAccess a, List<Mat> eventMats, String rawToken) {
        var mat = eventMats.stream()
                .filter(m -> a.getAccountId().equals(m.getRefereeAccountId()))
                .map(Mat::getNumber)
                .findFirst()
                .orElse(null);
        return new TemporaryAccessResponse(
                a.getId(),
                a.getAccountId(),
                a.getName(),
                a.getRole(),
                mat,
                a.isWaiting(),
                a.getSignedInAt(),
                a.isEnded(),
                rawToken == null ? null : baseUrl + LINK_PATH + rawToken);
    }
}
