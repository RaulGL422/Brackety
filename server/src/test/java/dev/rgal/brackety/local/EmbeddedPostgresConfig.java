package dev.rgal.brackety.local;

import io.zonky.test.db.postgres.embedded.EmbeddedPostgres;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.concurrent.TimeUnit;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.util.FileSystemUtils;

// Throwaway PostgreSQL 18: created on startup, deleted on shutdown. DataSourceAutoConfiguration backs off.
@TestConfiguration(proxyBeanMethods = false)
public class EmbeddedPostgresConfig {

    @Bean(destroyMethod = "close")
    EmbeddedPostgres embeddedPostgres(@Value("${brackety.local.db-port:0}") int port) throws IOException {
        var builder = EmbeddedPostgres.builder();
        if (port > 0) {
            // A fixed port means the local runner: a hard stop (IDE stop button) leaves postgres
            // running, so reuse one data dir and kill the leftover through its postmaster.pid.
            var dataDir = Path.of(System.getProperty("java.io.tmpdir"), "brackety-local-pg-" + port);
            killLeftoverPostgres(dataDir);
            FileSystemUtils.deleteRecursively(dataDir);
            builder.setPort(port).setDataDirectory(dataDir).setCleanDataDirectory(true);
        }
        return builder.start();
    }

    @Bean
    DataSource dataSource(EmbeddedPostgres postgres) {
        return postgres.getPostgresDatabase();
    }

    static void killLeftoverPostgres(Path dataDir) throws IOException {
        var pidFile = dataDir.resolve("postmaster.pid");
        if (!Files.exists(pidFile)) {
            return;
        }
        var pid = Long.parseLong(Files.readAllLines(pidFile).getFirst().trim());
        ProcessHandle.of(pid)
                .filter(p -> p.info().command().orElse("").contains("postgres"))
                .ifPresent(postmaster -> {
                    postmaster.descendants().forEach(ProcessHandle::destroyForcibly);
                    postmaster.destroyForcibly();
                    postmaster.onExit().orTimeout(10, TimeUnit.SECONDS).join();
                });
    }
}
