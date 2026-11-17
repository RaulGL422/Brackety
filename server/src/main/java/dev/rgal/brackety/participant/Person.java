package dev.rgal.brackety.participant;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import org.hibernate.annotations.BatchSize;

/**
 * A student, once (docs/producto/modelo-datos.md): every entry of theirs, in any phase, reads the name and birth date
 * from here. The id is given, not generated: an event package carries it so the same person comes back.
 */
@Entity
@BatchSize(size = 100)
public class Person {

    @Id
    private UUID id;

    private String firstName;
    private String lastName;
    private LocalDate birthDate;

    @Enumerated(EnumType.STRING)
    private Sex sex;

    /** The latest measured, in any event. */
    private Integer heightCm;

    private BigDecimal weightKg;
    private Instant createdAt;

    protected Person() {}

    public Person(UUID id, Instant now) {
        this.id = id;
        this.createdAt = now;
    }

    public UUID getId() {
        return id;
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

    public Sex getSex() {
        return sex;
    }

    public Integer getHeightCm() {
        return heightCm;
    }

    public BigDecimal getWeightKg() {
        return weightKg;
    }

    void update(String firstName, String lastName, LocalDate birthDate) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.birthDate = birthDate;
    }

    void setSex(Sex sex) {
        this.sex = sex;
    }

    /** What was not measured keeps the latest value. */
    void measured(Integer heightCm, BigDecimal weightKg) {
        if (heightCm != null) {
            this.heightCm = heightCm;
        }
        if (weightKg != null) {
            this.weightKg = weightKg;
        }
    }
}
