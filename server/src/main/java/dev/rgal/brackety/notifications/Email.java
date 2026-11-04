package dev.rgal.brackety.notifications;

/** {@code link} is the call to action, kept apart so the log sender can show it without the body. */
public record Email(String to, String subject, String text, String html, String link) {

    @Override
    public String toString() {
        return "Email[subject=" + subject + "]";
    }
}
