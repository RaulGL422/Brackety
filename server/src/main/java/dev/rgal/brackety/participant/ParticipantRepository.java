package dev.rgal.brackety.participant;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ParticipantRepository extends JpaRepository<Participant, UUID> {

    List<Participant> findByEventIdOrderByFirstNameAscLastNameAsc(UUID eventId);
}
