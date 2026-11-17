package dev.rgal.brackety.event;

import static org.assertj.core.api.Assertions.assertThat;

import io.zonky.test.db.postgres.embedded.EmbeddedPostgres;
import java.util.UUID;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.simple.JdbcClient;

/**
 * The F1 events reach production through this migration (docs/producto/modelo-datos-migracion.md, M1): their rules
 * must come out the same in their modality.
 */
class ModalityMigrationTest {

    @Test
    void anEventKeepsItsRulesInItsModality() throws Exception {
        try (var postgres = EmbeddedPostgres.builder().start()) {
            var dataSource = postgres.getPostgresDatabase();
            var jdbc = JdbcClient.create(dataSource);
            flyway(dataSource, "20261116.1000").migrate();
            var account = UUID.randomUUID();
            var league = UUID.randomUUID();
            var event = UUID.randomUUID();
            jdbc.sql("insert into account (id, email, email_verified, locale, status, created_at, updated_at)"
                            + " values (?, 'club@example.test', true, 'es', 'ACTIVE', now(), now())")
                    .param(account)
                    .update();
            jdbc.sql("insert into league (id, owner_account_id, name, podium_firsts, podium_seconds, podium_thirds,"
                            + " created_at) values (?, ?, 'Liga', 1, 1, 1, now())")
                    .params(league, account)
                    .update();
            // The F1 of 2026-11-14: individual 1:00 and 15 points, teams 3:00 and no limit, 30 s rest, 20 s
            // changeover.
            jdbc.sql("insert into event (id, owner_account_id, league_id, phase_number, discipline, name, event_date,"
                            + " max_groups_per_mat, match_seconds, points_limit, changeover_seconds,"
                            + " attendance_points, team_match_seconds, team_points_limit, min_rest_seconds, created_at)"
                            + " values (?, ?, ?, 1, 'TAMBO', 'Fase 1', '2026-11-14', 1, 60, 15, 20, 10, 180, 0, 30,"
                            + " now())")
                    .params(event, account, league)
                    .update();

            flyway(dataSource, "latest").migrate();

            assertThat(jdbc.sql("select position, name, min_rest_seconds, changeover_seconds from modality"
                                    + " where event_id = ?")
                            .param(event)
                            .query()
                            .singleRow())
                    .containsEntry("position", 1)
                    .containsEntry("name", null)
                    .containsEntry("min_rest_seconds", 30)
                    .containsEntry("changeover_seconds", 20);
            assertThat(jdbc.sql("select format || ' ' || match_seconds || ' ' || points_limit from modality_rules r"
                                    + " join modality m on m.id = r.modality_id where m.event_id = ? order by format")
                            .param(event)
                            .query(String.class)
                            .list())
                    .containsExactly("INDIVIDUAL 60 15", "TEAM 180 0");
        }
    }

    private static Flyway flyway(javax.sql.DataSource dataSource, String target) {
        return Flyway.configure()
                .dataSource(dataSource)
                .locations("classpath:db/migration")
                .target(target)
                .load();
    }
}
