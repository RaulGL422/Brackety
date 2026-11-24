package dev.rgal.brackety.ranking;

import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventOrganizationRepository;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.grouping.CompetitorDirectory;
import dev.rgal.brackety.grouping.FightGroup;
import dev.rgal.brackety.grouping.FightGroupRepository;
import dev.rgal.brackety.grouping.GroupMemberRepository;
import dev.rgal.brackety.grouping.Match;
import dev.rgal.brackety.grouping.MatchRepository;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import dev.rgal.brackety.participant.ParticipantService;
import java.util.Comparator;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.springframework.stereotype.Component;

/** Loads what the sheets read; the caller has checked who asks. */
@Component
class SheetSource {

    private final ParticipantRepository participants;
    private final CompetitorDirectory directory;
    private final EventCategoryRepository categories;
    private final EventOrganizationRepository organizations;
    private final FightGroupRepository groups;
    private final GroupMemberRepository members;
    private final MatchRepository matches;
    private final MatRepository mats;
    private final AccountRepository accounts;
    private final EventService events;

    SheetSource(
            ParticipantRepository participants,
            CompetitorDirectory directory,
            EventCategoryRepository categories,
            EventOrganizationRepository organizations,
            FightGroupRepository groups,
            GroupMemberRepository members,
            MatchRepository matches,
            MatRepository mats,
            AccountRepository accounts,
            EventService events) {
        this.participants = participants;
        this.directory = directory;
        this.categories = categories;
        this.organizations = organizations;
        this.groups = groups;
        this.members = members;
        this.matches = matches;
        this.mats = mats;
        this.accounts = accounts;
        this.events = events;
    }

    SheetData load(UUID eventId) {
        var eventCategories = categories.findByEventIdOrderByMinAge(eventId);
        var eventMats = mats.findByEventIdOrderByNumber(eventId);
        var eventParticipants = participants.findByEventIdOrderByFirstNameAscLastNameAsc(eventId);
        return new SheetData(
                events.get(eventId),
                eventParticipants,
                eventParticipants.stream().collect(Collectors.toMap(Participant::getId, Function.identity())),
                ParticipantService.organizationNames(organizations, eventId),
                eventCategories,
                eventCategories.stream().collect(Collectors.toMap(EventCategory::getId, EventCategory::getName)),
                directory.of(eventId),
                directory.teamNumbers(eventId),
                groups.findByEventId(eventId).stream()
                        .collect(Collectors.toMap(FightGroup::getId, Function.identity())),
                members.findByEventId(eventId),
                matches.findByEventId(eventId).stream()
                        .sorted(Comparator.comparing(Match::getMatId, Comparator.nullsLast(Comparator.naturalOrder()))
                                .thenComparing(Match::getOrderIndex))
                        .toList(),
                eventMats.stream().collect(Collectors.toMap(Mat::getId, Mat::getNumber)),
                eventMats);
    }

    /** The sign-in of each account, for the columns that say who did something. */
    Map<UUID, String> usernames(Stream<UUID> ids) {
        Set<UUID> wanted = ids.filter(Objects::nonNull).collect(Collectors.toSet());
        return accounts.findAllById(wanted).stream().collect(Collectors.toMap(Account::getId, Account::getEmail));
    }
}
