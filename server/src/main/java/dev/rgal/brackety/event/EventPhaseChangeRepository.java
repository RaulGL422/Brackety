package dev.rgal.brackety.event;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface EventPhaseChangeRepository extends JpaRepository<EventPhaseChange, UUID> {}
