package dev.rgal.brackety.local;

import dev.rgal.brackety.BracketyApplication;
import org.springframework.boot.SpringApplication;

// Local runner: embedded database + a data scenario. See docs/08-ejecucion-local.md.
public class LocalBracketyApplication {

    public static void main(String[] args) {
        SpringApplication.from(BracketyApplication::main)
                .with(LocalConfig.class)
                .withAdditionalProfiles("local")
                .run(args);
    }
}
