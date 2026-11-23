package dev.rgal.brackety.event.sport;

import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.util.UUID;
import org.hibernate.annotations.Immutable;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** One version of a sport, never changed: an event keeps the one it was made with. */
@Entity
@Immutable
@Table(name = "sport_template_version")
public class SportVersion {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "template_id")
    private SportTemplate template;

    private int version;

    @JdbcTypeCode(SqlTypes.JSON)
    private SportRules rules;

    protected SportVersion() {}

    public UUID getId() {
        return id;
    }

    public SportTemplate getTemplate() {
        return template;
    }

    public String code() {
        return template.getCode();
    }

    public int getVersion() {
        return version;
    }

    public SportRules rules() {
        return rules;
    }

    /** The same sport, whichever its version. */
    public boolean sameSport(SportVersion other) {
        return template.getId().equals(other.template.getId());
    }
}
