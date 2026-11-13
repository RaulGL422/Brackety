package dev.rgal.brackety.event;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** The phase's full rulebook as the club uploaded it: one PDF per event. */
@Entity
@Table(name = "event_rulebook")
public class Rulebook {

    @Id
    private UUID eventId;

    private String fileName;
    private byte[] content;
    private Instant uploadedAt;

    protected Rulebook() {}

    public Rulebook(UUID eventId, String fileName, byte[] content, Instant uploadedAt) {
        this.eventId = eventId;
        this.fileName = fileName;
        this.content = content;
        this.uploadedAt = uploadedAt;
    }

    public UUID getEventId() {
        return eventId;
    }

    public String getFileName() {
        return fileName;
    }

    public byte[] getContent() {
        return content;
    }

    public Instant getUploadedAt() {
        return uploadedAt;
    }
}
