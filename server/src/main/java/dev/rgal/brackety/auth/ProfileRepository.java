package dev.rgal.brackety.auth;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface ProfileRepository extends JpaRepository<Profile, UUID> {

    List<Profile> findByAccountId(UUID accountId);
}
