package dev.rgal.brackety.auth.account;

import dev.rgal.brackety.auth.account.Identity.Provider;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface IdentityRepository extends JpaRepository<Identity, UUID> {

    Optional<Identity> findByProviderAndSubject(Provider provider, String subject);

    List<Identity> findByAccountIdOrderByCreatedAt(UUID accountId);
}
