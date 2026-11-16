package dev.rgal.brackety.event;

import static org.assertj.core.api.Assertions.assertThat;

import io.zonky.test.db.postgres.embedded.EmbeddedPostgres;
import java.time.LocalDate;
import java.util.UUID;
import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.simple.JdbcClient;

/** M2b (docs/producto/modelo-datos-migracion.md): the clubs of every phase become one club each. */
class OrganizationMigrationTest {

    @Test
    void theSameClubInEveryPhaseIsOneClub() throws Exception {
        try (var postgres = EmbeddedPostgres.builder().start()) {
            var dataSource = postgres.getPostgresDatabase();
            var jdbc = JdbcClient.create(dataSource);
            flyway(dataSource, "20261117.1000").migrate();
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
            club(jdbc, phase1, "Club Norte", null);
            club(jdbc, phase2, "club norte", "NOR");
            club(jdbc, phase2, "Club Sur", null);

            flyway(dataSource, "latest").migrate();

            // The latest phase gives the name and short name.
            assertThat(jdbc.sql(
                                    "select name || ' ' || coalesce(short_name, '-') from organization order by lower(name)")
                            .query(String.class)
                            .list())
                    .containsExactly("club norte NOR", "Club Sur -");
            assertThat(jdbc.sql("select count(distinct eo.organization_id) from event_organization eo"
                                    + " join organization o on o.id = eo.organization_id and o.owner_account_id = ?")
                            .param(account)
                            .query(Integer.class)
                            .single())
                    .isEqualTo(2);
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

    private static void club(JdbcClient jdbc, UUID event, String name, String shortName) {
        jdbc.sql("insert into event_organization (id, event_id, name, short_name) values (?, ?, ?, ?)")
                .params(UUID.randomUUID(), event, name, shortName)
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
