package dev.rgal.brackety.event.sport;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

interface SportVersionRepository extends JpaRepository<SportVersion, UUID> {

    /** The latest version of each sport, in the order they are listed. */
    @Query("""
            select v from SportVersion v join fetch v.template t
            where v.version = (select max(o.version) from SportVersion o where o.template = t)
            order by t.position""")
    List<SportVersion> findLatest();
}
