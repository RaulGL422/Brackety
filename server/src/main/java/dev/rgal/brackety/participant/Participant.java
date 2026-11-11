package dev.rgal.brackety.participant;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventCategory;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Entity
public class Participant {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID eventId;
    private UUID personId;
    private String firstName;
    private String lastName;
    private LocalDate birthDate;
    private Integer heightCm;
    private boolean guardianConsent;
    private UUID categoryId;
    private UUID organizationId;
    private Instant createdAt;

    protected Participant() {}

    public Participant(UUID eventId, Instant now) {
        this(eventId, UUID.randomUUID(), now);
    }

    /** {@code personId}: the same person in another phase of the league, or a new one. */
    public Participant(UUID eventId, UUID personId, Instant now) {
        this.eventId = eventId;
        this.personId = personId;
        this.createdAt = now;
    }

    public UUID getId() {
        return id;
    }

    public UUID getEventId() {
        return eventId;
    }

    /** The same person in every phase of a league: their points add up. */
    public UUID getPersonId() {
        return personId;
    }

    public UUID getOrganizationId() {
        return organizationId;
    }

    public void setOrganizationId(UUID organizationId) {
        this.organizationId = organizationId;
    }

    public String getFirstName() {
        return firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public LocalDate getBirthDate() {
        return birthDate;
    }

    public Integer getHeightCm() {
        return heightCm;
    }

    public boolean hasGuardianConsent() {
        return guardianConsent;
    }

    /** The category chosen for them, or null to follow their age. */
    public UUID getCategoryId() {
        return categoryId;
    }

    /**
     * The one place that says which category a participant competes in: the chosen one, or the
     * one their age on the event day falls in.
     */
    public Optional<EventCategory> categoryIn(Event event, List<EventCategory> categories) {
        if (categoryId != null) {
            return categories.stream().filter(c -> c.getId().equals(categoryId)).findFirst();
        }
        var age = event.ageOf(birthDate);
        return categories.stream().filter(c -> c.contains(age)).findFirst();
    }

    public void update(
            String firstName, String lastName, LocalDate birthDate, Integer heightCm, boolean guardianConsent) {
        update(firstName, lastName, birthDate, heightCm, guardianConsent, null);
    }

    public void update(
            String firstName,
            String lastName,
            LocalDate birthDate,
            Integer heightCm,
            boolean guardianConsent,
            UUID categoryId) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.birthDate = birthDate;
        this.heightCm = heightCm;
        this.guardianConsent = guardianConsent;
        this.categoryId = categoryId;
    }
}
