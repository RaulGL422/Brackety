package dev.rgal.brackety.participant.importing;

import static dev.rgal.brackety.participant.importing.dto.RowIssue.Code.ALREADY_REGISTERED;
import static dev.rgal.brackety.participant.importing.dto.RowIssue.Code.CATEGORY_MISMATCH;
import static dev.rgal.brackety.participant.importing.dto.RowIssue.Code.DUPLICATE_IN_LIST;
import static dev.rgal.brackety.participant.importing.dto.RowIssue.Code.FUTURE_DATE;
import static dev.rgal.brackety.participant.importing.dto.RowIssue.Code.HEIGHT_OUT_OF_RANGE;
import static dev.rgal.brackety.participant.importing.dto.RowIssue.Code.INVALID_DATE;
import static dev.rgal.brackety.participant.importing.dto.RowIssue.Code.MISSING;
import static dev.rgal.brackety.participant.importing.dto.RowIssue.Code.NO_CATEGORY;
import static dev.rgal.brackety.participant.importing.dto.RowIssue.Code.TOO_LONG;
import static dev.rgal.brackety.participant.importing.dto.RowIssue.Code.UNKNOWN_CATEGORY;
import static dev.rgal.brackety.participant.importing.dto.RowIssue.Code.UNSURE;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.importing.dto.CheckedRow;
import dev.rgal.brackety.participant.importing.dto.ImportRow;
import dev.rgal.brackety.participant.importing.dto.RowIssue;
import java.text.Normalizer;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Optional;

/**
 * The rules an imported row must pass, the same as registering by hand plus what a list adds
 * (docs/modulos/importacion-alumnos.md). Claude's reading is never trusted.
 */
final class ImportValidator {

    // Same limits as ParticipantRequest.
    static final int MAX_FIRST_NAME = 60;
    static final int MAX_LAST_NAME = 80;
    static final int MIN_HEIGHT = 50;
    static final int MAX_HEIGHT = 250;

    private ImportValidator() {}

    /**
     * @param today the server's day: a birth date must be before it
     * @param registered the event's participants already in
     */
    static List<CheckedRow> check(
            Event event,
            List<EventCategory> categories,
            List<Participant> registered,
            List<ImportRow> rows,
            LocalDate today) {
        var existing = registered.stream()
                .map(p -> key(p.getFirstName(), p.getLastName(), p.getBirthDate()))
                .toList();
        var firstRowOf = new HashMap<String, Integer>();
        var result = new ArrayList<CheckedRow>();
        for (int i = 0; i < rows.size(); i++) {
            var row = rows.get(i);
            var errors = new ArrayList<RowIssue>();
            name(row.firstName(), "firstName", MAX_FIRST_NAME, errors);
            name(row.lastName(), "lastName", MAX_LAST_NAME, errors);
            var date = birthDate(row, today, errors);
            if (row.heightCm() != null && (row.heightCm() < MIN_HEIGHT || row.heightCm() > MAX_HEIGHT)) {
                errors.add(new RowIssue(
                        "heightCm", HEIGHT_OUT_OF_RANGE, row.heightCm().toString()));
            }
            Integer age = date == null ? null : event.ageOf(date);
            var byAge = age == null ? Optional.<EventCategory>empty() : byAge(categories, age);
            var indicated = indicated(categories, row.categoryText());
            var category = category(row, categories, byAge, indicated, age, errors);

            if (date != null && row.firstName() != null && row.lastName() != null) {
                var key = key(row.firstName(), row.lastName(), date);
                if (existing.contains(key)) {
                    errors.add(RowIssue.of("firstName", ALREADY_REGISTERED));
                }
                var first = firstRowOf.putIfAbsent(key, i);
                if (first != null) {
                    errors.add(new RowIssue("firstName", DUPLICATE_IN_LIST, String.valueOf(first + 1)));
                }
            }
            var warnings = row.unsure().stream()
                    .map(field -> RowIssue.of(field, UNSURE))
                    .toList();
            result.add(new CheckedRow(
                    row,
                    age,
                    category.map(EventCategory::getId).orElse(null),
                    category.map(EventCategory::getName).orElse(null),
                    indicated.map(EventCategory::getId).orElse(null),
                    indicated.map(EventCategory::getName).orElse(null),
                    byAge.map(EventCategory::getId).orElse(null),
                    byAge.map(EventCategory::getName).orElse(null),
                    errors,
                    warnings));
        }
        return result;
    }

    private static void name(String value, String field, int max, List<RowIssue> errors) {
        if (value == null || value.isBlank()) {
            errors.add(RowIssue.of(field, MISSING));
        } else if (value.strip().length() > max) {
            errors.add(RowIssue.of(field, TOO_LONG));
        }
    }

    private static LocalDate birthDate(ImportRow row, LocalDate today, List<RowIssue> errors) {
        if (row.birthDate() == null) {
            errors.add(
                    row.birthDateText() == null
                            ? RowIssue.of("birthDate", MISSING)
                            : new RowIssue("birthDate", INVALID_DATE, row.birthDateText()));
            return null;
        }
        if (!row.birthDate().isBefore(today)) {
            errors.add(RowIssue.of("birthDate", FUTURE_DATE));
            return null;
        }
        return row.birthDate();
    }

    /**
     * Where they would compete. A category chosen by the club wins; otherwise the one written in
     * the list must agree with their age, or the club has to choose.
     */
    private static Optional<EventCategory> category(
            ImportRow row,
            List<EventCategory> categories,
            Optional<EventCategory> byAge,
            Optional<EventCategory> indicated,
            Integer age,
            List<RowIssue> errors) {
        if (row.categoryId() != null) {
            var chosen = categories.stream()
                    .filter(c -> c.getId().equals(row.categoryId()))
                    .findFirst();
            if (chosen.isEmpty()) {
                errors.add(RowIssue.of("category", UNKNOWN_CATEGORY));
            }
            return chosen;
        }
        if (row.categoryText() != null) {
            if (indicated.isEmpty()) {
                errors.add(new RowIssue("category", UNKNOWN_CATEGORY, row.categoryText()));
                return Optional.empty();
            }
            if (age != null && !indicated.equals(byAge)) {
                errors.add(new RowIssue("category", CATEGORY_MISMATCH, row.categoryText()));
                return Optional.empty();
            }
        }
        if (age != null && byAge.isEmpty()) {
            errors.add(new RowIssue("category", NO_CATEGORY, String.valueOf(age)));
        }
        return byAge;
    }

    private static Optional<EventCategory> byAge(List<EventCategory> categories, int age) {
        return categories.stream().filter(c -> c.contains(age)).findFirst();
    }

    /** The event category whose name matches what was written ("cat. 9-10", "9 - 10 años"). */
    private static Optional<EventCategory> indicated(List<EventCategory> categories, String text) {
        if (text == null) {
            return Optional.empty();
        }
        var wanted = categoryKey(text);
        return categories.stream()
                .filter(c -> categoryKey(c.getName()).equals(wanted))
                .findFirst();
    }

    private static String categoryKey(String text) {
        return plain(text).replaceAll("categoria|cat\\.?|anos|ano", "").replaceAll("[^a-z0-9+-]", "");
    }

    private static String key(String firstName, String lastName, LocalDate birthDate) {
        return plain(firstName) + "|" + plain(lastName) + "|" + birthDate;
    }

    /** Lower case, no accents, single spaces: "  Lucía  GARCÍA" and "lucia garcia" are the same. */
    private static String plain(String text) {
        return Normalizer.normalize(text.strip(), Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase()
                .replaceAll("\\s+", " ");
    }
}
