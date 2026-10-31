package dev.rgal.brackety.auth.admin;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface AdminAuditRepository extends JpaRepository<AdminAudit, UUID> {}
