package dev.rgal.brackety.ranking;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import org.junit.jupiter.api.Test;

class CsvTest {

    @Test
    void formulaStartsAreNeutralisedAlsoBehindATabOrACarriageReturn() {
        var csv = Csv.of(List.of("a", "b", "c", "d"), List.of(List.of("=1+1", "\t=1+1", "\r=1+1", -3)));

        assertThat(csv).isEqualTo(Csv.BOM + "a;b;c;d\r\n" + "'=1+1;'\t=1+1;\"'\r=1+1\";-3\r\n");
    }

    @Test
    void plainTextIsKept() {
        assertThat(Csv.of(List.of("Nombre"), List.of(List.of("Lucía 1\t2"))))
                .isEqualTo(Csv.BOM + "Nombre\r\nLucía 1\t2\r\n");
    }
}
