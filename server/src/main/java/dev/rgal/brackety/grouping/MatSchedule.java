package dev.rgal.brackety.grouping;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import java.time.Duration;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/** Current load of every mat of an event, from its matches. */
@Component
class MatSchedule {

    record MatState(Mat mat, int groups, int pendingMatches, boolean matchInProgress, Duration remaining) {}

    private final MatRepository mats;
    private final FightGroupRepository groups;
    private final MatchRepository matches;

    MatSchedule(MatRepository mats, FightGroupRepository groups, MatchRepository matches) {
        this.mats = mats;
        this.groups = groups;
        this.matches = matches;
    }

    List<MatState> states(Event event, Instant now) {
        var matchesByMat =
                matches.findByEventId(event.getId()).stream().collect(Collectors.groupingBy(Match::getMatId));
        var groupsByMat = groups.findByEventId(event.getId()).stream()
                .collect(Collectors.groupingBy(FightGroup::getMatId, Collectors.counting()));
        return mats.findByEventIdOrderByNumber(event.getId()).stream()
                .map(mat -> state(
                        event,
                        mat,
                        groupsByMat.getOrDefault(mat.getId(), 0L).intValue(),
                        matchesByMat.getOrDefault(mat.getId(), List.of()),
                        now))
                .toList();
    }

    /** Where new groups go: the mat with a referee that will be free first; on a tie, the lowest number. */
    Optional<Mat> soonestFree(Event event, Instant now) {
        return states(event, now).stream()
                .filter(s -> s.mat().getRefereeAccountId() != null)
                .min(Comparator.comparing(MatState::remaining)
                        .thenComparingInt(s -> s.mat().getNumber()))
                .map(MatState::mat);
    }

    private static MatState state(Event event, Mat mat, int groupCount, List<Match> onMat, Instant now) {
        var match = Duration.ofSeconds(event.getMatchSeconds());
        var pending = (int) onMat.stream()
                .filter(m -> m.getStatus() == Match.Status.PENDING)
                .count();
        var current = onMat.stream()
                .filter(m -> m.getStatus() == Match.Status.IN_PROGRESS)
                .findFirst();
        var lastFinished = onMat.stream()
                .map(Match::getFinishedAt)
                .filter(Objects::nonNull)
                .max(Comparator.naturalOrder());
        var remaining = MatEstimate.remaining(
                pending,
                current.map(m -> m.clockLeft(now, match)).orElse(null),
                lastFinished.map(f -> Duration.between(f, now)).orElse(null),
                match,
                Duration.ofSeconds(event.getChangeoverSeconds()));
        return new MatState(mat, groupCount, pending, current.isPresent(), remaining);
    }
}
