package dev.rgal.brackety.ranking;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.util.UUID;

/** A custom export with personal or minors' columns: who, when, which sheet and which of those columns. */
@Entity
class ExportAudit {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID eventId;
    private UUID accountId;
    private String accountName;
    private Instant at;
    private String sheet;
    private String columns;

    protected ExportAudit() {}

    ExportAudit(UUID eventId, UUID accountId, String accountName, Instant at, String sheet, String columns) {
        this.eventId = eventId;
        this.accountId = accountId;
        this.accountName = accountName;
        this.at = at;
        this.sheet = sheet;
        this.columns = columns;
    }

    String getAccountName() {
        return accountName;
    }

    Instant getAt() {
        return at;
    }

    String getSheet() {
        return sheet;
    }

    String getColumns() {
        return columns;
    }
}
