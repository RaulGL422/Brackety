package dev.rgal.brackety.league;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRepository;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventStaff;
import dev.rgal.brackety.event.EventStaffRepository;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.league.dto.LeagueDtos.NewEventRequest;
import dev.rgal.brackety.league.dto.LeagueDtos.PhaseResponse;
import java.time.Clock;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * A standalone event (docs/producto/grappling.md, G4): a league of one phase, so the club panel, standings and
 * downloads work as for any phase. Its creator is its club; it starts from its sport's rules.
 */
@Service
class NewEventService {

    private final LeagueRepository leagues;
    private final EventRepository events;
    private final EventStaffRepository staff;
    private final MatRepository mats;
    private final Clock clock;

    NewEventService(
            LeagueRepository leagues,
            EventRepository events,
            EventStaffRepository staff,
            MatRepository mats,
            Clock clock) {
        this.leagues = leagues;
        this.events = events;
        this.staff = staff;
        this.mats = mats;
        this.clock = clock;
    }

    @Transactional
    PhaseResponse create(UUID accountId, NewEventRequest request) {
        if (!request.discipline().isAvailable()) {
            throw EventException.invalid("That discipline has no scoreboard yet.");
        }
        var name = request.name().strip();
        var now = clock.instant();
        var league = leagues.save(new League(accountId, name, now));
        // No attendance points: they only make sense across the phases of a league.
        var event = events.save(new Event(
                accountId,
                league.getId(),
                1,
                request.discipline(),
                name,
                request.date(),
                0,
                request.discipline().defaultModality(),
                now));
        staff.save(new EventStaff(event.getId(), accountId, EventRole.CLUB));
        for (int number = 1; number <= request.mats(); number++) {
            mats.save(new Mat(event.getId(), number, null));
        }
        return new PhaseResponse(event.getId(), 1, name, event.getEventDate(), event.getDiscipline(), 0);
    }
}
