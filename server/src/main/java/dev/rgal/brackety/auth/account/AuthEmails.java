package dev.rgal.brackety.auth.account;

import dev.rgal.brackety.notifications.Email;
import dev.rgal.brackety.notifications.EmailService;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.FormatStyle;
import java.util.Locale;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.MessageSource;
import org.springframework.stereotype.Component;
import org.springframework.web.util.HtmlUtils;

// Every auth email: one paragraph, one link, in the account language.
@Component
public class AuthEmails {

    static final String VERIFY_PATH = "/verify-email?token=";
    static final String RESET_PATH = "/reset-password?token=";
    static final String FORGOT_PATH = "/forgot-password";
    static final String CHANGE_EMAIL_PATH = "/confirm-email-change?token=";
    static final String LOGIN_PATH = "/login";

    private final EmailService emails;
    private final MessageSource messages;
    private final String baseUrl;

    AuthEmails(EmailService emails, MessageSource messages, @Value("${brackety.public-base-url}") String baseUrl) {
        this.emails = emails;
        this.messages = messages;
        this.baseUrl = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
    }

    public void verifyEmail(Account account, String token) {
        send(account, "verify", VERIFY_PATH + token);
    }

    public void verificationReminder(Account account, String token) {
        send(account, "reminder", VERIFY_PATH + token);
    }

    public void alreadyRegistered(Account account) {
        send(account, "already-registered", FORGOT_PATH);
    }

    public void resetPassword(Account account, String token) {
        send(account, "reset", RESET_PATH + token);
    }

    public void passwordChanged(Account account) {
        send(account, "password-changed", FORGOT_PATH);
    }

    public void sessionReused(Account account) {
        send(account, "session-reused", FORGOT_PATH);
    }

    public void identityLinked(Account account, Identity.Provider provider) {
        send(account, "identity-linked", FORGOT_PATH, providerName(provider));
    }

    public void identityUnlinked(Account account, Identity.Provider provider) {
        send(account, "identity-unlinked", FORGOT_PATH, providerName(provider));
    }

    public void passwordRemoved(Account account) {
        send(account, "password-removed", FORGOT_PATH);
    }

    public void accountLocked(Account account, String lockId) {
        send(account, "locked", FORGOT_PATH, lockId);
    }

    /** Goes to the new address, which has no account yet: it is in the language of the one asking. */
    public void confirmEmailChange(Account account, String newEmail, String token) {
        send(newEmail, account, "change-email", CHANGE_EMAIL_PATH + token);
    }

    /** Someone asked to move their account to the address of {@code existing}; its owner is told, not them. */
    public void emailInUse(Account existing) {
        send(existing, "email-in-use", FORGOT_PATH);
    }

    public void emailChanged(String oldEmail, Account account) {
        send(oldEmail, account, "email-changed", LOGIN_PATH, masked(account.getEmail()));
    }

    public void deletionScheduled(Account account, LocalDate deletesOn) {
        send(account, "deletion-scheduled", LOGIN_PATH, longDate(deletesOn, account));
    }

    public void registeredWhilePendingDeletion(Account account) {
        send(account, "pending-deletion", LOGIN_PATH);
    }

    public void organizerValidated(Account account, ProfileType type) {
        var typeName = text("profile-type." + type.name(), Locale.forLanguageTag(account.getLocale()));
        send(account, "organizer-validated", LOGIN_PATH, typeName);
    }

    private void send(Account account, String kind, String path, Object... args) {
        send(account.getEmail(), account, kind, path, args);
    }

    private void send(String to, Account account, String kind, String path, Object... args) {
        var locale = Locale.forLanguageTag(account.getLocale());
        var subject = messages.getMessage("email." + kind + ".subject", args, locale);
        var body = messages.getMessage("email." + kind + ".body", args, locale);
        var action = text("email." + kind + ".action", locale);
        var footer = text("email.footer", locale);
        var link = baseUrl + path;
        var plain = body + "\n\n" + action + ": " + link + "\n\n" + footer;
        var html = "<p>%s</p><p><a href=\"%s\">%s</a></p><p><small>%s</small></p>"
                .formatted(
                        HtmlUtils.htmlEscape(body),
                        HtmlUtils.htmlEscape(link),
                        HtmlUtils.htmlEscape(action),
                        HtmlUtils.htmlEscape(footer));
        emails.send(new Email(to, subject, plain, html, link));
    }

    // Enough for the owner to recognise it, not enough to hand the new address to whoever reads the old inbox.
    static String masked(String email) {
        var at = email.indexOf('@');
        return email.charAt(0) + "***" + email.substring(at);
    }

    private static String longDate(LocalDate date, Account account) {
        return date.format(DateTimeFormatter.ofLocalizedDate(FormatStyle.LONG)
                .withLocale(Locale.forLanguageTag(account.getLocale())));
    }

    private static String providerName(Identity.Provider provider) {
        return switch (provider) {
            case GOOGLE -> "Google";
        };
    }

    private String text(String key, Locale locale) {
        return messages.getMessage(key, null, locale);
    }
}
