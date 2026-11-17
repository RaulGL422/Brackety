package dev.rgal.brackety.staff;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.notifications.Email;
import dev.rgal.brackety.notifications.EmailService;
import java.time.format.DateTimeFormatter;
import java.time.format.FormatStyle;
import java.util.Locale;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.MessageSource;
import org.springframework.stereotype.Component;
import org.springframework.web.util.HtmlUtils;

/** The invitation email (F1-5): one paragraph and the link, like the auth emails. */
@Component
class StaffEmails {

    static final String INVITATION_PATH = "/invitation?token=";

    private final EmailService emails;
    private final MessageSource messages;
    private final String baseUrl;

    StaffEmails(EmailService emails, MessageSource messages, @Value("${brackety.public-base-url}") String baseUrl) {
        this.emails = emails;
        this.messages = messages;
        this.baseUrl = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
    }

    /** {@code locale}: the invited account's, or Spanish when there is none yet. */
    void invitation(String to, Locale locale, Event event, String organizer, EventRole role, String token) {
        var date = event.getEventDate()
                .format(DateTimeFormatter.ofLocalizedDate(FormatStyle.LONG).withLocale(locale));
        var roleName = messages.getMessage("staff-role." + role.name(), null, locale);
        Object[] args = {organizer, event.getName(), roleName, date, to};
        var subject = messages.getMessage("email.staff-invitation.subject", args, locale);
        var body = messages.getMessage("email.staff-invitation.body", args, locale);
        var action = messages.getMessage("email.staff-invitation.action", null, locale);
        var footer = messages.getMessage("email.footer", null, locale);
        var link = baseUrl + INVITATION_PATH + token;
        var plain = body + "\n\n" + action + ": " + link + "\n\n" + footer;
        var html = "<p>%s</p><p><a href=\"%s\">%s</a></p><p><small>%s</small></p>"
                .formatted(
                        HtmlUtils.htmlEscape(body),
                        HtmlUtils.htmlEscape(link),
                        HtmlUtils.htmlEscape(action),
                        HtmlUtils.htmlEscape(footer));
        emails.send(new Email(to, subject, plain, html, link));
    }
}
