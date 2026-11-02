package dev.rgal.brackety.participant.importing;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface ParticipantImportRepository extends JpaRepository<ParticipantImport, UUID> {}
