package dev.rgal.brackety;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

/**
 * The app says every refusal code the server sends in the user's language (plan-limpieza.md, L3): a new code without
 * its text in app/lib/core/error_codes.dart would fall back to a generic message.
 */
class ErrorCodesTranslatedTest {

    private static final Path SOURCES = Path.of("src/main/java");
    private static final Path APP_CODES = Path.of("../app/lib/core/error_codes.dart");
    private static final Pattern LITERAL = Pattern.compile("(?:conflict|invalid)\\(\\s*\"([A-Z][A-Z0-9_]+)\",");
    private static final Pattern CONSTANT = Pattern.compile("(?:conflict|invalid)\\(\\s*([A-Z][A-Z0-9_]+),");
    private static final Pattern PROPERTY = Pattern.compile("setProperty\\(\"code\", \"([A-Z][A-Z0-9_]+)\"\\)");
    private static final Pattern APP_CODE = Pattern.compile("'([A-Z][A-Z0-9_]+)' =>");

    // Refused online with the cause's name as the code. AGE is a bad request the app never lets through, and a match
    // in review is refused before as MATCH_IN_REVIEW (IN_REVIEW only waits in the offline queue).
    private static final Set<String> CAUSES_NOT_SENT = Set.of("AGE", "IN_REVIEW");
    private static final Path CAUSES = SOURCES.resolve("dev/rgal/brackety/scoreboard/RejectedOp.java");

    @Test
    void theAppTranslatesEveryServerCode() throws IOException {
        var server = serverCodes();

        assertThat(server).isNotEmpty();
        assertThat(appCodes()).containsAll(server);
    }

    @Test
    void theAppTranslatesNoCodeTheServerDropped() throws IOException {
        assertThat(serverCodes()).containsAll(appCodes());
    }

    private static Set<String> serverCodes() throws IOException {
        var codes = new TreeSet<String>();
        try (var files = Files.walk(SOURCES)) {
            for (var file : files.filter(f -> f.toString().endsWith(".java")).toList()) {
                var source = Files.readString(file);
                all(LITERAL.matcher(source), codes);
                all(PROPERTY.matcher(source), codes);
                var constants = CONSTANT.matcher(source);
                while (constants.find()) {
                    codes.add(constant(source, constants.group(1)));
                }
            }
        }
        codes.addAll(causes());
        return codes;
    }

    private static String constant(String source, String name) {
        var value =
                Pattern.compile("String " + name + " = \"([A-Z][A-Z0-9_]+)\";").matcher(source);
        assertThat(value.find()).as("code constant %s", name).isTrue();
        return value.group(1);
    }

    private static Set<String> causes() throws IOException {
        var source = Files.readString(CAUSES);
        var body = source.substring(source.indexOf("enum Cause {") + "enum Cause {".length());
        body = body.substring(0, body.indexOf('}')).replaceAll("/\\*\\*.*?\\*/", "");
        var causes = new TreeSet<>(Arrays.stream(body.split(","))
                .map(String::strip)
                .filter(c -> !c.isEmpty())
                .toList());
        causes.removeAll(CAUSES_NOT_SENT);
        return causes;
    }

    private static Set<String> appCodes() throws IOException {
        var codes = new TreeSet<String>();
        all(APP_CODE.matcher(Files.readString(APP_CODES)), codes);
        return codes;
    }

    private static void all(Matcher matcher, Set<String> into) {
        while (matcher.find()) {
            into.add(matcher.group(1));
        }
    }
}
