package dev.rgal.brackety.auth;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface ConsentRepository extends JpaRepository<Consent, UUID> {

    List<Consent> findByAccountId(UUID accountId);
}
