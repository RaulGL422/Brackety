package dev.rgal.brackety.auth;

import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

interface EmailTokenRepository extends JpaRepository<EmailToken, UUID> {

    // Locked so two clicks on the same link cannot both use it.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<EmailToken> findByTokenHash(String tokenHash);

    boolean existsByAccountIdAndPurposeAndCreatedAtAfter(UUID accountId, EmailToken.Purpose purpose, Instant after);

    @Modifying
    @Query("delete from EmailToken t where t.accountId = :accountId and t.purpose = :purpose")
    int deleteByAccountIdAndPurpose(UUID accountId, EmailToken.Purpose purpose);
}
