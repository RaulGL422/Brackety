package dev.rgal.brackety.notifications;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

// Local and tests, when RESEND_API_KEY is empty: the link is enough to follow the flow by hand.
class LogEmailSender implements EmailSender {

    private static final Logger log = LoggerFactory.getLogger(LogEmailSender.class);

    @Override
    public void send(Email email) {
        log.info("Email to {}: {} {}", mask(email.to()), email.subject(), email.link());
    }

    static String mask(String address) {
        var at = address.indexOf('@');
        return at < 1 ? "***" : address.charAt(0) + "***" + address.substring(at);
    }
}
