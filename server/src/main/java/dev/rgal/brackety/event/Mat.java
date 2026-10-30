package dev.rgal.brackety.event;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.util.UUID;

@Entity
public class Mat {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID eventId;
    private int number;
    private UUID refereeAccountId;

    protected Mat() {}

    public Mat(UUID eventId, int number, UUID refereeAccountId) {
        this.eventId = eventId;
        this.number = number;
        this.refereeAccountId = refereeAccountId;
    }

    public UUID getId() {
        return id;
    }

    public int getNumber() {
        return number;
    }

    public UUID getRefereeAccountId() {
        return refereeAccountId;
    }

    void assignReferee(UUID refereeAccountId) {
        this.refereeAccountId = refereeAccountId;
    }
}
