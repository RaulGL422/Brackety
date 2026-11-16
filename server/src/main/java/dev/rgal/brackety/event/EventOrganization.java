package dev.rgal.brackety.event;

import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import java.util.UUID;

/** A club taking part in the event: only the link; the club itself is an {@link Organization}. */
@Entity
public class EventOrganization {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID eventId;

    @ManyToOne(fetch = FetchType.EAGER, optional = false)
    @JoinColumn(name = "organization_id")
    private Organization organization;

    protected EventOrganization() {}

    public EventOrganization(UUID eventId, Organization organization) {
        this.eventId = eventId;
        this.organization = organization;
    }

    public UUID getId() {
        return id;
    }

    public UUID getEventId() {
        return eventId;
    }

    public Organization getOrganization() {
        return organization;
    }

    public String getName() {
        return organization.getName();
    }

    public String getShortName() {
        return organization.getShortName();
    }

    void link(Organization organization) {
        this.organization = organization;
    }
}
