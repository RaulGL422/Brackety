package dev.rgal.brackety.auth.account;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ConsentRepository extends JpaRepository<Consent, UUID> {

    List<Consent> findByAccountId(UUID accountId);
}
