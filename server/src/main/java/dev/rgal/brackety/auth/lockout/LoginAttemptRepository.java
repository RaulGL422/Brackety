package dev.rgal.brackety.auth.lockout;

import jakarta.persistence.LockModeType;
import java.time.Instant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

public interface LoginAttemptRepository extends JpaRepository<LoginAttempt, String> {

    @Modifying
    @Query(value = "insert into login_attempt (attempt_key) values (:key) on conflict do nothing", nativeQuery = true)
    void createIfMissing(String key);

    // The row lock serialises concurrent logins on the same key, so parallel guesses cannot skip the counter.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from LoginAttempt a where a.attemptKey = :key")
    LoginAttempt lockByKey(String key);

    @Modifying
    @Query("delete from LoginAttempt a where (a.lastFailureAt is null or a.lastFailureAt < :windowStart)"
            + " and (a.lockedUntil is null or a.lockedUntil <= :now)")
    int deleteFinished(Instant windowStart, Instant now);
}
