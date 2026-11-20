package dev.rgal.brackety.common;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;
import java.util.TreeMap;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * The golden check (docs/producto/plan-limpieza.md, L0): what the code produces today must stay byte for byte the
 * same, so a refactor that changes a standing or a CSV fails here. Random ids are numbered in order of appearance.
 * When a change is intended, rewrite the files with {@code -Dgolden.update=true} and review their diff in the PR.
 */
public final class GoldenFiles {

    private static final Path ROOT = Path.of("src", "test", "resources", "golden");
    private static final Pattern UUID_PATTERN =
            Pattern.compile("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}");

    private GoldenFiles() {}

    public static void check(String set, Map<String, String> files) throws IOException {
        var actual = withNumberedIds(files);
        var dir = ROOT.resolve(set);
        if (Boolean.getBoolean("golden.update")) {
            rewrite(dir, actual);
            return;
        }
        var expected = read(dir);
        assertThat(actual.keySet()).as("golden files of %s", set).isEqualTo(expected.keySet());
        actual.forEach((name, content) -> assertThat(content)
                .as("golden %s/%s (if the change is intended, run with -Dgolden.update=true)", set, name)
                .isEqualTo(expected.get(name)));
    }

    // In file-name order, so the same id gets the same number in every file.
    private static Map<String, String> withNumberedIds(Map<String, String> files) {
        var numbers = new HashMap<String, String>();
        var result = new TreeMap<String, String>();
        new TreeMap<>(files)
                .forEach((name, content) -> result.put(
                        name,
                        UUID_PATTERN
                                .matcher(content)
                                .replaceAll(
                                        m -> numbers.computeIfAbsent(m.group(), id -> "id-" + (numbers.size() + 1)))));
        return result;
    }

    private static Map<String, String> read(Path dir) throws IOException {
        if (!Files.isDirectory(dir)) {
            return Map.of();
        }
        try (Stream<Path> paths = Files.walk(dir)) {
            var result = new TreeMap<String, String>();
            for (var path : paths.filter(Files::isRegularFile).toList()) {
                result.put(
                        dir.relativize(path).toString().replace('\\', '/'),
                        Files.readString(path, StandardCharsets.UTF_8));
            }
            return result;
        }
    }

    private static void rewrite(Path dir, Map<String, String> files) throws IOException {
        if (Files.isDirectory(dir)) {
            try (Stream<Path> paths = Files.walk(dir)) {
                for (var path : paths.sorted((a, b) -> b.compareTo(a)).collect(Collectors.toList())) {
                    Files.delete(path);
                }
            }
        }
        for (var file : files.entrySet()) {
            var path = dir.resolve(file.getKey());
            Files.createDirectories(path.getParent());
            Files.writeString(path, file.getValue(), StandardCharsets.UTF_8);
        }
    }
}
