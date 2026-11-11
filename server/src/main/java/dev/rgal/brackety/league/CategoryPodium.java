package dev.rgal.brackety.league;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

/** A category's own podium in a league, by category name (categories are copied from phase to phase). */
@Entity
@Table(name = "league_category_podium")
public class CategoryPodium {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID leagueId;
    private String categoryName;
    private int firsts;
    private int seconds;
    private int thirds;

    protected CategoryPodium() {}

    public CategoryPodium(UUID leagueId, String categoryName, Podium podium) {
        this.leagueId = leagueId;
        this.categoryName = categoryName;
        this.firsts = podium.firsts();
        this.seconds = podium.seconds();
        this.thirds = podium.thirds();
    }

    public String getCategoryName() {
        return categoryName;
    }

    public Podium getPodium() {
        return new Podium(firsts, seconds, thirds);
    }
}
