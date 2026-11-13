package dev.rgal.brackety.event;

import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.util.Arrays;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * The full rulebook of a phase (Raul, 2026-11-13): the club uploads it and every role of the event reads it, the
 * referees from their mat screen. It travels in the event package to the sports hall laptop.
 */
@Service
public class RulebookService {

    public static final int MAX_BYTES = 10 * 1024 * 1024;
    private static final byte[] PDF_MAGIC = "%PDF-".getBytes(StandardCharsets.US_ASCII);

    private final RulebookRepository rulebooks;
    private final EventAccess access;
    private final Clock clock;

    RulebookService(RulebookRepository rulebooks, EventAccess access, Clock clock) {
        this.rulebooks = rulebooks;
        this.access = access;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public Rulebook get(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.values());
        return rulebooks.findById(eventId).orElseThrow(EventException::notFound);
    }

    @Transactional(readOnly = true)
    public Optional<RulebookRepository.Info> info(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.values());
        return rulebooks.findInfo(eventId);
    }

    @Transactional
    public RulebookRepository.Info upload(UUID eventId, UUID accountId, String fileName, byte[] content) {
        access.require(eventId, accountId, EventRole.CLUB);
        put(eventId, fileName, content);
        rulebooks.flush();
        return rulebooks.findInfo(eventId).orElseThrow();
    }

    @Transactional
    public void delete(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        rulebooks.findById(eventId).ifPresent(rulebooks::delete);
    }

    /** No access check: also for loading a package. */
    @Transactional
    public void put(UUID eventId, String fileName, byte[] content) {
        if (content.length > MAX_BYTES) {
            throw EventException.invalid("The rulebook can be up to 10 MB.");
        }
        if (content.length < PDF_MAGIC.length || !Arrays.equals(Arrays.copyOf(content, PDF_MAGIC.length), PDF_MAGIC)) {
            throw EventException.invalid("The rulebook must be a PDF.");
        }
        rulebooks.save(new Rulebook(eventId, name(fileName), content, clock.instant()));
    }

    @Transactional(readOnly = true)
    public Optional<Rulebook> find(UUID eventId) {
        return rulebooks.findById(eventId);
    }

    private static String name(String fileName) {
        var name = fileName == null
                ? ""
                : fileName.replaceAll("[\\\\/\\p{Cntrl}]", "").strip();
        if (name.isEmpty()) {
            return "reglamento.pdf";
        }
        return name.length() > 200 ? name.substring(name.length() - 200) : name;
    }
}
