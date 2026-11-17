package dev.rgal.brackety.event;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.BatchSize;

/**
 * A club, once per account that runs events (docs/producto/modelo-datos.md): every event it takes part in links it
 * through {@link EventOrganization}, so a new name reaches all of them. {@code shortName} is optional.
 */
@Entity
@BatchSize(size = 100)
public class Organization {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID ownerAccountId;
    private String name;
    private String shortName;
    private Instant createdAt;

    protected Organization() {}

    Organization(UUID ownerAccountId, String name, String shortName, Instant now) {
        this.ownerAccountId = ownerAccountId;
        this.createdAt = now;
        update(name, shortName);
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

    public String getShortName() {
        return shortName;
    }

    void update(String name, String shortName) {
        this.name = name;
        this.shortName = shortName;
    }
}
