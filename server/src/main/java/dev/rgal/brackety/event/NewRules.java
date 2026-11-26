package dev.rgal.brackety.event;

import dev.rgal.brackety.event.dto.EventSettingsRequest;
import java.util.Objects;

/** The match rules a settings change asks for: what it leaves out stays as it is. */
record NewRules(Modality.FormatRules individual, Modality.FormatRules team, int minRestSeconds, int superiorityGap) {

    static NewRules of(Modality modality, EventSettingsRequest request) {
        return new NewRules(
                new Modality.FormatRules(
                        Objects.requireNonNullElse(
                                request.matchSeconds(), modality.individual().matchSeconds()),
                        Objects.requireNonNullElse(
                                request.pointsLimit(), modality.individual().pointsLimit())),
                new Modality.FormatRules(
                        Objects.requireNonNullElse(
                                request.teamMatchSeconds(), modality.team().matchSeconds()),
                        Objects.requireNonNullElse(
                                request.teamPointsLimit(), modality.team().pointsLimit())),
                Objects.requireNonNullElse(request.minRestSeconds(), modality.getMinRestSeconds()),
                Objects.requireNonNullElse(
                        request.superiorityGap(), modality.scoring().superiorityGap()));
    }

    boolean changeLength(Modality modality) {
        return individual.matchSeconds() != modality.individual().matchSeconds()
                || team.matchSeconds() != modality.team().matchSeconds();
    }

    boolean changeHowAMatchEnds(Modality modality) {
        return individual.pointsLimit() != modality.individual().pointsLimit()
                || team.pointsLimit() != modality.team().pointsLimit()
                || superiorityGap != modality.scoring().superiorityGap();
    }
}
