package dev.rgal.brackety.event;

import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.event.EventPhaseChange.Action;
import dev.rgal.brackety.notifications.Email;
import dev.rgal.brackety.notifications.EmailService;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Locale;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.MessageSource;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.util.HtmlUtils;

/**
 * Nobody pressed "Finish" (F1-7, Raul 2026-11-18): the day after, a phase with no matches left finishes by itself and
 * the club gets an email. With matches left it stays open and the club is told once.
 */
@Component
class PhaseAutoClose {

    private final EventRepository events;
    private final EventPhase phase;
    private final AccountRepository accounts;
    private final EmailService emails;
    private final MessageSource messages;
    private final Clock clock;
    private final ZoneId zone;
    private final String baseUrl;

    PhaseAutoClose(
            EventRepository events,
            EventPhase phase,
            AccountRepository accounts,
            EmailService emails,
            MessageSource messages,
            Clock clock,
            @Value("${brackety.time-zone}") String zone,
            @Value("${brackety.public-base-url}") String baseUrl) {
        this.events = events;
        this.phase = phase;
        this.accounts = accounts;
        this.emails = emails;
        this.messages = messages;
        this.clock = clock;
        this.zone = ZoneId.of(zone);
        this.baseUrl = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
    }

    @Scheduled(cron = "0 5 0 * * *", zone = "${brackety.time-zone}")
    @Transactional
    void run() {
        for (var event : events.findOpenBefore(LocalDate.now(clock.withZone(zone)))) {
            if (events.hasMatchInProgressOrReview(event.getId()) || events.countPendingMatches(event.getId()) > 0) {
                if (event.getAutoCloseWarnedAt() == null) {
                    event.autoCloseWarned(clock.instant());
                    email(event, "email.phase-not-closed", events.countPendingMatches(event.getId()));
                }
            } else {
                phase.close(event, Action.AUTO_FINISH, null);
                email(event, "email.phase-closed", 0);
            }
        }
    }

    private void email(Event event, String key, int pending) {
        accounts.findById(event.getOwnerAccountId()).ifPresent(owner -> {
            var locale = Locale.forLanguageTag(owner.getLocale());
            Object[] args = {event.getName(), pending};
            var subject = messages.getMessage(key + ".subject", args, locale);
            var body = messages.getMessage(key + ".body", args, locale);
            var action = messages.getMessage("email.phase.action", null, locale);
            var footer = messages.getMessage("email.footer", null, locale);
            var link = baseUrl + "/events/" + event.getId() + "/club";
            var plain = body + "\n\n" + action + ": " + link + "\n\n" + footer;
            var html = "<p>%s</p><p><a href=\"%s\">%s</a></p><p><small>%s</small></p>"
                    .formatted(
                            HtmlUtils.htmlEscape(body),
                            HtmlUtils.htmlEscape(link),
                            HtmlUtils.htmlEscape(action),
                            HtmlUtils.htmlEscape(footer));
            emails.send(new Email(owner.getEmail(), subject, plain, html, link));
        });
    }
}
