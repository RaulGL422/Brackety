package dev.rgal.brackety.event;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrganizationRepository extends JpaRepository<Organization, UUID> {

    Optional<Organization> findByOwnerAccountIdAndNameIgnoreCase(UUID ownerAccountId, String name);

    /** The owner's club with that name (case aside), or a new one: the same club is never stored twice. */
    default Organization named(UUID ownerAccountId, String name, String shortName, Instant now) {
        return findByOwnerAccountIdAndNameIgnoreCase(ownerAccountId, name)
                .orElseGet(() -> save(new Organization(ownerAccountId, name, shortName, now)));
    }
}
