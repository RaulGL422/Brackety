package dev.rgal.debug;

import dev.rgal.brackety.BracketyApplication;
import org.springframework.boot.SpringApplication;

/** The debug image's entry point (./mvnw -P debug package): the app plus {@link DebugConfig}. */
public class DebugBracketyApplication {

    public static void main(String[] args) {
        SpringApplication.from(BracketyApplication::main)
                .with(DebugClockConfig.class, DebugConfig.class)
                .withAdditionalProfiles("debug")
                .run(args);
    }
}
