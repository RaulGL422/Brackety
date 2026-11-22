package dev.rgal.brackety.event;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.util.UUID;

@Entity
public class Mat {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID eventId;
    private int number;
    private UUID refereeAccountId;

    /** Out of use since then (F1-1); null while in use. */
    private Instant disabledAt;

    /** The referee it had when put out of use: "Enable" gives it back. */
    private UUID disabledRefereeAccountId;

    protected Mat() {}

    public Mat(UUID eventId, int number, UUID refereeAccountId) {
        this.eventId = eventId;
        this.number = number;
        this.refereeAccountId = refereeAccountId;
    }

    public UUID getId() {
        return id;
    }

    public UUID getEventId() {
        return eventId;
    }

    public int getNumber() {
        return number;
    }

    public UUID getRefereeAccountId() {
        return refereeAccountId;
    }

    public Instant getDisabledAt() {
        return disabledAt;
    }

    public UUID getDisabledRefereeAccountId() {
        return disabledRefereeAccountId;
    }

    public boolean isDisabled() {
        return disabledAt != null;
    }

    /** A referee assigned in the settings also puts a mat out of use back in use. */
    void assignReferee(UUID refereeAccountId) {
        this.refereeAccountId = refereeAccountId;
        if (refereeAccountId != null) {
            this.disabledAt = null;
            this.disabledRefereeAccountId = null;
        }
    }

    /**
     * Out of use: it gets no groups and takes no team matches until it is enabled again or gets a referee in the
     * settings. A mat that just has no referee yet is still in use (Raul, 2026-11-22).
     */
    public void disable(Instant at) {
        this.disabledRefereeAccountId = refereeAccountId;
        this.disabledAt = at;
        this.refereeAccountId = null;
    }

    /** Back in use with the referee it had. */
    public void enable() {
        this.refereeAccountId = disabledRefereeAccountId;
        this.disabledAt = null;
        this.disabledRefereeAccountId = null;
    }
}
