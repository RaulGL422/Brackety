package dev.rgal.brackety.event.sport;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import java.util.UUID;

/**
 * A sport (docs/producto/plantillas-deporte.md): its rules live in its versions ({@link SportVersion}). {@code code}
 * names it in the API and the event packages (TAMBO, GRAPPLING…).
 */
@Entity
public class SportTemplate {

    @Id
    private UUID id;

    private String code;
    private int position;

    protected SportTemplate() {}

    public UUID getId() {
        return id;
    }

    public String getCode() {
        return code;
    }

    public int getPosition() {
        return position;
    }
}
