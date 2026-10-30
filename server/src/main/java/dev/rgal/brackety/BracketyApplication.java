package dev.rgal.brackety;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class BracketyApplication {

    public static void main(String[] args) {
        SpringApplication.run(BracketyApplication.class, args);
    }
}
