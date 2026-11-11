package dev.rgal.brackety.league;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.util.UUID;

/**
 * A league by phases: each phase is an event of the league ({@code event.league_id}). The podium says how many
 * firsts, seconds and thirds each category has on the final standings, unless a category has its own.
 */
@Entity
public class League {

    public static final Podium DEFAULT_PODIUM = new Podium(2, 2, 3);

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID ownerAccountId;
    private String name;
    private int podiumFirsts;
    private int podiumSeconds;
    private int podiumThirds;
    private Instant createdAt;

    protected League() {}

    public League(UUID ownerAccountId, String name, Instant now) {
        this.ownerAccountId = ownerAccountId;
        this.name = name;
        this.createdAt = now;
        setPodium(DEFAULT_PODIUM);
    }

    public UUID getId() {
        return id;
    }

    public UUID getOwnerAccountId() {
        return ownerAccountId;
    }

    public String getName() {
        return name;
    }

    public Podium getPodium() {
        return new Podium(podiumFirsts, podiumSeconds, podiumThirds);
    }

    public void update(String name, Podium podium) {
        this.name = name;
        setPodium(podium);
    }

    private void setPodium(Podium podium) {
        this.podiumFirsts = podium.firsts();
        this.podiumSeconds = podium.seconds();
        this.podiumThirds = podium.thirds();
    }
}
