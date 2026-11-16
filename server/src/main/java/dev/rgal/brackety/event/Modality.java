package dev.rgal.brackety.event;

import dev.rgal.brackety.event.EventCategory.Format;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Embeddable;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.MapKeyColumn;
import jakarta.persistence.MapKeyEnumerated;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import org.hibernate.annotations.BatchSize;

/**
 * What an event is fought in, with its rules (docs/producto/modelo-datos.md): the rest and the changeover between
 * matches, and the length and points limit of a match per format. The only place match rules live.
 */
@Entity
public class Modality {

    /** {@code pointsLimit}: 0 = no limit. */
    @Embeddable
    public record FormatRules(int matchSeconds, int pointsLimit) {}

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private int position;
    private String name;
    private int minRestSeconds;
    private int changeoverSeconds;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "modality_rules", joinColumns = @JoinColumn(name = "modality_id"))
    @MapKeyEnumerated(EnumType.STRING)
    @MapKeyColumn(name = "format")
    @BatchSize(size = 50)
    private Map<Format, FormatRules> rules = new HashMap<>();

    protected Modality() {}

    Modality(int position, FormatRules individual, FormatRules team, int minRestSeconds, int changeoverSeconds) {
        this.position = position;
        this.minRestSeconds = minRestSeconds;
        this.changeoverSeconds = changeoverSeconds;
        rules.put(Format.INDIVIDUAL, individual);
        rules.put(Format.TEAM, team);
    }

    /**
     * Liga Yoseikan tambo, Fase 1 (Raul, 2026-11-13): individual 1 min and 15 points end it; teams 3 min with no
     * points limit; 30 s of rest at least between two matches of a fighter; 30 s to change over. The club can change
     * all of it in the settings.
     */
    public static Modality tambo() {
        return new Modality(1, new FormatRules(60, 15), new FormatRules(180, 0), 30, 30);
    }

    public static Modality of(
            int matchSeconds,
            int pointsLimit,
            int teamMatchSeconds,
            int teamPointsLimit,
            int minRestSeconds,
            int changeoverSeconds) {
        return new Modality(
                1,
                new FormatRules(matchSeconds, pointsLimit),
                new FormatRules(teamMatchSeconds, teamPointsLimit),
                minRestSeconds,
                changeoverSeconds);
    }

    /** The same rules, for the next phase of a league. */
    Modality copy() {
        return new Modality(position, individual(), team(), minRestSeconds, changeoverSeconds);
    }

    public UUID getId() {
        return id;
    }

    public int getPosition() {
        return position;
    }

    public String getName() {
        return name;
    }

    public int getMinRestSeconds() {
        return minRestSeconds;
    }

    public int getChangeoverSeconds() {
        return changeoverSeconds;
    }

    public FormatRules rules(boolean teams) {
        return teams ? team() : individual();
    }

    public int matchSeconds(boolean teams) {
        return rules(teams).matchSeconds();
    }

    /** 0 = no limit. */
    public int pointsLimit(boolean teams) {
        return rules(teams).pointsLimit();
    }

    public FormatRules individual() {
        return rules.get(Format.INDIVIDUAL);
    }

    public FormatRules team() {
        return rules.get(Format.TEAM);
    }

    void update(FormatRules individual, FormatRules team, int minRestSeconds) {
        rules.put(Format.INDIVIDUAL, individual);
        rules.put(Format.TEAM, team);
        this.minRestSeconds = minRestSeconds;
    }
}
