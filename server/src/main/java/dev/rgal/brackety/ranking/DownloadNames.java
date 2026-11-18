package dev.rgal.brackety.ranking;

import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.eventpackage.EventPackageService;
import dev.rgal.brackety.league.League;
import dev.rgal.brackety.league.LeagueRepository;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * Names of what the club downloads: league, phase and what it is ("liga-yoseikan-2027_fase-2_combates.csv"), so a
 * file sent by email or left in Descargas still says where it comes from.
 */
@Component
class DownloadNames {

    private final EventService events;
    private final LeagueRepository leagues;

    DownloadNames(EventService events, LeagueRepository leagues) {
        this.events = events;
        this.leagues = leagues;
    }

    /** "liga-yoseikan-2027_fase-2_" + what. */
    String of(UUID eventId, String what) {
        var event = events.get(eventId);
        var league = leagues.findById(event.getLeagueId()).map(League::getName).orElse(event.getName());
        return EventPackageService.slug(league) + "_fase-" + event.getPhaseNumber() + "_" + what;
    }
}
