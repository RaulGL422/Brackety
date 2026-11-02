package dev.rgal.brackety.participant.importing;

import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import dev.rgal.brackety.participant.importing.dto.CheckedRow;
import dev.rgal.brackety.participant.importing.dto.ImportRequest;
import dev.rgal.brackety.participant.importing.dto.ImportResult;
import dev.rgal.brackety.participant.importing.dto.ImportRow;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Bulk participant import (docs/modulos/importacion-alumnos.md): read, check, register all or none. */
@Service
class ParticipantImportService {

    /** The consent text the app shows; a new wording gets a new version. */
    static final String CONSENT_VERSION = "v1";

    static final int MAX_ROWS = 200;
    static final int MAX_FILES = 10;
    static final long MAX_FILE_BYTES = 10L * 1024 * 1024;
    static final int MAX_READS_PER_HOUR = 10;

    static final String XLSX = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
    private static final Set<String> IMAGE_TYPES = Set.of("image/jpeg", "image/png", "image/webp");
    private static final Logger log = LoggerFactory.getLogger(ParticipantImportService.class);

    private final ListReader reader;
    private final ParticipantRepository participants;
    private final EventCategoryRepository categories;
    private final ParticipantImportRepository imports;
    private final EventService events;
    private final EventAccess access;
    private final Clock clock;
    // A single server for now: reads per account in the last hour, in memory.
    private final Map<UUID, Deque<Instant>> reads = new ConcurrentHashMap<>();

    ParticipantImportService(
            ListReader reader,
            ParticipantRepository participants,
            EventCategoryRepository categories,
            ParticipantImportRepository imports,
            EventService events,
            EventAccess access,
            Clock clock) {
        this.reader = reader;
        this.participants = participants;
        this.categories = categories;
        this.imports = imports;
        this.events = events;
        this.access = access;
        this.clock = clock;
    }

    boolean isAvailable(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        return reader.isAvailable();
    }

    /**
     * Reads the list and checks it; nothing is kept, neither the files nor the rows. Not in a
     * transaction: reading takes up to 90 s and must not hold a database connection.
     */
    List<CheckedRow> read(UUID eventId, UUID accountId, List<ListFile> files, String consentVersion) {
        access.require(eventId, accountId, EventRole.CLUB);
        requireConsent(consentVersion);
        if (!reader.isAvailable()) {
            throw ImportException.unavailable();
        }
        checkFiles(files);
        countRead(accountId);
        var started = clock.instant();
        List<ImportRow> rows;
        try {
            rows = reader.read(
                    files.stream().map(ParticipantImportService::asText).toList());
        } catch (ListReadException e) {
            log.warn("A list could not be read: {}", e.getMessage());
            throw ImportException.unreadable();
        }
        log.info(
                "Read a list: {} files, {} rows in {} ms",
                files.size(),
                rows.size(),
                Duration.between(started, clock.instant()).toMillis());
        return check(eventId, accountId, rows);
    }

    @Transactional(readOnly = true)
    public List<CheckedRow> check(UUID eventId, UUID accountId, List<ImportRow> rows) {
        access.require(eventId, accountId, EventRole.CLUB);
        if (rows.size() > MAX_ROWS) {
            throw EventException.invalid("At most " + MAX_ROWS + " participants per import.");
        }
        return ImportValidator.check(
                events.get(eventId),
                categories.findByEventIdOrderByMinAge(eventId),
                participants.findByEventIdOrderByFirstNameAscLastNameAsc(eventId),
                rows,
                LocalDate.now(clock));
    }

    /** All or none: one row with an error and nothing is registered. */
    @Transactional
    public ImportResult register(UUID eventId, UUID accountId, ImportRequest request) {
        access.require(eventId, accountId, EventRole.CLUB);
        requireConsent(request.consentVersion());
        // Same lock as group creation, so nobody registers the same participant meanwhile.
        events.lock(eventId);
        var checked = check(eventId, accountId, request.rows());
        if (!checked.stream().allMatch(CheckedRow::isValid)) {
            return new ImportResult(0, checked);
        }
        var now = clock.instant();
        for (var row : request.rows()) {
            var participant = new Participant(eventId, now);
            // The club declared that every guardian agreed: that is the import's consent.
            participant.update(
                    row.firstName().strip(),
                    row.lastName().strip(),
                    row.birthDate(),
                    row.heightCm(),
                    true,
                    row.categoryId());
            participants.save(participant);
        }
        imports.save(new ParticipantImport(eventId, accountId, request.rows().size(), CONSENT_VERSION, now));
        return new ImportResult(request.rows().size(), checked);
    }

    private static void requireConsent(String version) {
        if (!CONSENT_VERSION.equals(version)) {
            throw EventException.invalid("The current consent must be accepted.");
        }
    }

    private static void checkFiles(List<ListFile> files) {
        if (files.isEmpty() || files.size() > MAX_FILES) {
            throw EventException.invalid("Send between 1 and " + MAX_FILES + " files.");
        }
        for (var file : files) {
            var known = IMAGE_TYPES.contains(file.mediaType())
                    || file.mediaType().equals(XLSX)
                    || file.mediaType().startsWith("text/");
            if (!known) {
                throw EventException.invalid("Photos (JPG, PNG, WebP), CSV, TXT or Excel only.");
            }
            if (file.content().length == 0 || file.content().length > MAX_FILE_BYTES) {
                throw EventException.invalid("Each file must be up to 10 MB.");
            }
        }
    }

    private void countRead(UUID accountId) {
        var now = clock.instant();
        var times = reads.computeIfAbsent(accountId, id -> new ArrayDeque<>());
        synchronized (times) {
            while (!times.isEmpty() && times.peekFirst().isBefore(now.minus(Duration.ofHours(1)))) {
                times.pollFirst();
            }
            if (times.size() >= MAX_READS_PER_HOUR) {
                throw ImportException.tooManyReads();
            }
            times.addLast(now);
        }
    }

    // Claude reads photos and text; an Excel sheet becomes text first.
    private static ListFile asText(ListFile file) {
        return file.mediaType().equals(XLSX)
                ? new ListFile("text/plain", XlsxText.of(file.content()).getBytes(StandardCharsets.UTF_8))
                : file;
    }
}
