package dev.rgal.brackety.event;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface RulebookRepository extends JpaRepository<Rulebook, UUID> {

    /** Without the PDF itself, for the settings screen. */
    interface Info {
        String getFileName();

        int getSizeBytes();
    }

    // Native: JPQL has no length for binary columns.
    @Query(
            value = "select file_name as fileName, octet_length(content) as sizeBytes"
                    + " from event_rulebook where event_id = :eventId",
            nativeQuery = true)
    Optional<Info> findInfo(UUID eventId);
}
