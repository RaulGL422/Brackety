package dev.rgal.brackety.participant;

import static org.assertj.core.api.Assertions.assertThat;

import io.zonky.test.db.postgres.embedded.EmbeddedPostgres;
import java.time.LocalDate;
import java.util.UUID;
import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.simple.JdbcClient;

/** M2a (docs/producto/modelo-datos-migracion.md): the F1 entries reach production through this migration. */
class PersonMigrationTest {

    @Test
    void eachPersonKeepsTheDataOfTheirLatestPhase() throws Exception {
        try (var postgres = EmbeddedPostgres.builder().start()) {
            var dataSource = postgres.getPostgresDatabase();
            var jdbc = JdbcClient.create(dataSource);
            flyway(dataSource, "20261116.1100").migrate();
            var account = UUID.randomUUID();
            var league = UUID.randomUUID();
            jdbc.sql("insert into account (id, email, email_verified, locale, status, created_at, updated_at)"
                            + " values (?, 'club@example.test', true, 'es', 'ACTIVE', now(), now())")
                    .param(account)
                    .update();
            jdbc.sql("insert into league (id, owner_account_id, name, podium_firsts, podium_seconds, podium_thirds,"
                            + " created_at) values (?, ?, 'Liga', 1, 1, 1, now())")
                    .params(league, account)
                    .update();
            var phase1 = event(jdbc, account, league, 1, "2026-11-14");
            var phase2 = event(jdbc, account, league, 2, "2027-01-24");
            var ana = UUID.randomUUID();
            var bea = UUID.randomUUID();
            // Ana's surname was fixed in phase 2; Bea only fought in phase 1.
            participant(jdbc, phase2, ana, "Ana", "Prueba Bis", 131);
            participant(jdbc, phase1, ana, "Ana", "Prueba", 130);
            participant(jdbc, phase1, bea, "Bea", "Prueba", null);

            flyway(dataSource, "latest").migrate();

            assertThat(jdbc.sql("select first_name || ' ' || last_name || ' ' || birth_date || ' ' ||"
                                    + " coalesce(height_cm::text, '-') from person order by first_name")
                            .query(String.class)
                            .list())
                    .containsExactly("Ana Prueba Bis 2018-01-15 131", "Bea Prueba 2018-01-15 -");
            assertThat(jdbc.sql("select count(*) from participant p join person pe on pe.id = p.person_id")
                            .query(Integer.class)
                            .single())
                    .isEqualTo(3);
        }
    }

    private static UUID event(JdbcClient jdbc, UUID account, UUID league, int phase, String date) {
        var id = UUID.randomUUID();
        jdbc.sql("insert into event (id, owner_account_id, league_id, phase_number, discipline, name, event_date,"
                        + " max_groups_per_mat, attendance_points, created_at)"
                        + " values (?, ?, ?, ?, 'TAMBO', ?, ?, 1, 10, now())")
                .params(id, account, league, phase, "Fase " + phase, LocalDate.parse(date))
                .update();
        return id;
    }

    private static void participant(
            JdbcClient jdbc, UUID event, UUID person, String firstName, String lastName, Integer heightCm) {
        jdbc.sql("insert into participant (id, event_id, person_id, first_name, last_name, birth_date, height_cm,"
                        + " guardian_consent, created_at) values (?, ?, ?, ?, ?, '2018-01-15', ?, true, now())")
                .params(UUID.randomUUID(), event, person, firstName, lastName, heightCm)
                .update();
    }

    private static Flyway flyway(DataSource dataSource, String target) {
        return Flyway.configure()
                .dataSource(dataSource)
                .locations("classpath:db/migration")
                .target(target)
                .load();
    }
}
