package dev.rgal.brackety.participant.importing.dto;

/**
 * What is wrong (an error) or doubtful (a warning) in a row. The app words it from {@code code};
 * {@code detail} carries what it needs, such as the date as written or the other row's number.
 */
public record RowIssue(String field, Code code, String detail) {

    public enum Code {
        MISSING,
        TOO_LONG,
        INVALID_DATE,
        FUTURE_DATE,
        HEIGHT_OUT_OF_RANGE,
        NO_CATEGORY,
        UNKNOWN_CATEGORY,
        CATEGORY_MISMATCH,
        DUPLICATE_IN_LIST,
        ALREADY_REGISTERED,
        UNSURE
    }

    public static RowIssue of(String field, Code code) {
        return new RowIssue(field, code, null);
    }
}
