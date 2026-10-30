package dev.rgal.brackety.notifications;

import java.util.ArrayList;
import java.util.List;

/** Test double: keeps every email instead of sending it, or fails on demand. */
public class CapturingEmailSender implements EmailSender {

    private final List<Email> sent = new ArrayList<>();
    private boolean failing;

    @Override
    public synchronized void send(Email email) {
        if (failing) {
            throw new IllegalStateException("Resend is down");
        }
        sent.add(email);
    }

    public synchronized List<Email> sent() {
        return List.copyOf(sent);
    }

    public synchronized List<Email> sentTo(String address) {
        return sent.stream().filter(e -> e.to().equals(address)).toList();
    }

    public synchronized void reset() {
        sent.clear();
        failing = false;
    }

    public synchronized void failFromNowOn() {
        failing = true;
    }
}
