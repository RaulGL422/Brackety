package dev.rgal.brackety.auth.account;

import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

public interface AccountRepository extends JpaRepository<Account, UUID> {

    Optional<Account> findByEmail(String email);

    // Row lock for the once-a-minute email limits: concurrent requests for one account queue up
    // here, so only the first sees the limit free and sends.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from Account a where a.email = :email")
    Optional<Account> lockByEmail(String email);

    // Row lock so two changes to the sign-in methods at once cannot leave the account with none.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from Account a where a.id = :id")
    Optional<Account> lockById(UUID id);

    @Query("select a from Account a where a.emailVerified = false"
            + " and a.verificationReminderSentAt is null and a.createdAt <= :createdBefore")
    List<Account> findUnverifiedNeedingReminder(Instant createdBefore);

    // Profiles, consents, tokens, sessions and login attempts go with it (on delete cascade).
    @Modifying
    @Query("delete from Account a where a.emailVerified = false and a.createdAt <= :createdBefore")
    int deleteUnverified(Instant createdBefore);

    // Same cascade as above: everything the account owns goes with it.
    @Modifying
    @Query("delete from Account a where a.deletedAt <= :deletedBefore")
    int deleteDeletedBefore(Instant deletedBefore);
}
