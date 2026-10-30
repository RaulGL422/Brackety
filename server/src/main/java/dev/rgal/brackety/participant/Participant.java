package dev.rgal.brackety.participant;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
public class Participant {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID eventId;
    private String firstName;
    private String lastName;
    private LocalDate birthDate;
    private Integer heightCm;
    private boolean guardianConsent;
    private Instant createdAt;

    protected Participant() {}

    public Participant(UUID eventId, Instant now) {
        this.eventId = eventId;
        this.createdAt = now;
    }

    public UUID getId() {
        return id;
    }

    public UUID getEventId() {
        return eventId;
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

    public void update(
            String firstName, String lastName, LocalDate birthDate, Integer heightCm, boolean guardianConsent) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.birthDate = birthDate;
        this.heightCm = heightCm;
        this.guardianConsent = guardianConsent;
    }
}
