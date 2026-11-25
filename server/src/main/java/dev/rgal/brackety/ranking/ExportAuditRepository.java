package dev.rgal.brackety.ranking;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface ExportAuditRepository extends JpaRepository<ExportAudit, UUID> {

    List<ExportAudit> findTop100ByEventIdOrderByAtDesc(UUID eventId);
}
