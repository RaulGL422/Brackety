package dev.rgal.brackety.event;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MatRepository extends JpaRepository<Mat, UUID> {

    List<Mat> findByEventIdOrderByNumber(UUID eventId);

    List<Mat> findByEventIdAndRefereeAccountIdOrderByNumber(UUID eventId, UUID refereeAccountId);
}
