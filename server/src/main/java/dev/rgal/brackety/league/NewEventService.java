package dev.rgal.brackety.league;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventRepository;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventStaff;
import dev.rgal.brackety.event.EventStaffRepository;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.event.sport.SportCatalog;
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
public class NewEventService {

    private final LeagueRepository leagues;
    private final EventRepository events;
    private final EventStaffRepository staff;
    private final MatRepository mats;
    private final SportCatalog sports;
    private final Clock clock;

    NewEventService(
            LeagueRepository leagues,
            EventRepository events,
            EventStaffRepository staff,
            MatRepository mats,
            SportCatalog sports,
            Clock clock) {
        this.leagues = leagues;
        this.events = events;
        this.staff = staff;
        this.mats = mats;
        this.sports = sports;
        this.clock = clock;
    }

    @Transactional
    public PhaseResponse create(UUID accountId, NewEventRequest request) {
        var sport = sports.playable(request.discipline());
        var name = request.name().strip();
        var now = clock.instant();
        var league = leagues.save(new League(accountId, name, now));
        // No attendance points: they only make sense across the phases of a league.
        var event = events.save(new Event(
                accountId,
                league.getId(),
                1,
                sport,
                name,
                request.date(),
                0,
                sport.rules().modality(),
                now));
        staff.save(new EventStaff(event.getId(), accountId, EventRole.CLUB));
        for (int number = 1; number <= request.mats(); number++) {
            mats.save(new Mat(event.getId(), number, null));
        }
        return new PhaseResponse(event.getId(), 1, name, event.getEventDate(), sport.code(), 0);
    }
}
