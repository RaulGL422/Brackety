package dev.rgal.brackety.auth.account;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProfileRepository extends JpaRepository<Profile, UUID> {

    List<Profile> findByAccountId(UUID accountId);
}
