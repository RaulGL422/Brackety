package dev.rgal.brackety.auth;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

interface AccountRepository extends JpaRepository<Account, UUID> {

    Optional<Account> findByEmail(String email);

    @Query("select a from Account a where a.emailVerified = false"
            + " and a.verificationReminderSentAt is null and a.createdAt <= :createdBefore")
    List<Account> findUnverifiedNeedingReminder(Instant createdBefore);

    // Profiles, consents, tokens, sessions and login attempts go with it (on delete cascade).
    @Modifying
    @Query("delete from Account a where a.emailVerified = false and a.createdAt <= :createdBefore")
    int deleteUnverified(Instant createdBefore);
}
