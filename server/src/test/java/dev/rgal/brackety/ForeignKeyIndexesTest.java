package dev.rgal.brackety;

import static org.assertj.core.api.Assertions.assertThat;

import io.zonky.test.db.postgres.embedded.EmbeddedPostgres;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.simple.JdbcClient;

/**
 * Every foreign key column leads an index (plan-limpieza.md, L1): without one, reading a row's children and deleting
 * the parent (an account, an event) scan the whole table.
 */
class ForeignKeyIndexesTest {

    @Test
    void everyForeignKeyHasAnIndex() throws Exception {
        try (var postgres = EmbeddedPostgres.builder().start()) {
            var dataSource = postgres.getPostgresDatabase();
            Flyway.configure()
                    .dataSource(dataSource)
                    .locations("classpath:db/migration")
                    .load()
                    .migrate();

            var unindexed =
                    JdbcClient.create(dataSource).sql("""
                            select c.conrelid::regclass || '.' || a.attname
                            from pg_constraint c
                            join pg_attribute a on a.attrelid = c.conrelid and a.attnum = c.conkey[1]
                            where c.contype = 'f'
                              and not exists (select 1 from pg_index i
                                              where i.indrelid = c.conrelid and i.indkey[0] = c.conkey[1])
                            order by 1""").query(String.class).list();

            assertThat(unindexed).isEmpty();
        }
    }
}
