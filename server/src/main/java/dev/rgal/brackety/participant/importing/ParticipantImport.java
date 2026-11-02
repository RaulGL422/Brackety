package dev.rgal.brackety.participant.importing;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.util.UUID;

/** Who imported how many participants, under which consent text. No names, no files. */
@Entity
class ParticipantImport {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID eventId;
    private UUID accountId;
    private int participants;
    private String consentVersion;
    private Instant createdAt;

    protected ParticipantImport() {}

    ParticipantImport(UUID eventId, UUID accountId, int participants, String consentVersion, Instant now) {
        this.eventId = eventId;
        this.accountId = accountId;
        this.participants = participants;
        this.consentVersion = consentVersion;
        this.createdAt = now;
    }
}
