package dev.rgal.brackety.auth.me;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.account.Consent;
import dev.rgal.brackety.auth.account.ConsentRepository;
import dev.rgal.brackety.auth.dto.ConsentRequest;
import dev.rgal.brackety.auth.dto.PendingConsent;
import dev.rgal.brackety.legal.LegalDocument;
import java.time.Clock;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/**
 * A material change of the terms or the privacy policy asks for a new acceptance (docs/modulos/legal-paginas.md).
 * Only of whoever accepted an earlier version: an account that never accepted one (a QR referee) is not stopped.
 */
@Service
class ConsentService {

    private static final Map<Consent.Document, LegalDocument> REQUIRED =
            Map.of(Consent.Document.TERMS, LegalDocument.TERMS, Consent.Document.PRIVACY, LegalDocument.PRIVACY);

    private final ConsentRepository consents;
    private final Clock clock;

    ConsentService(ConsentRepository consents, Clock clock) {
        this.consents = consents;
        this.clock = clock;
    }

    /**
     * The texts accepted in some version but never in the current one, terms first. Versions only move forward, so
     * having accepted the current one once is enough.
     */
    @Transactional(readOnly = true)
    List<PendingConsent> pending(UUID accountId) {
        var accepted = consents.findByAccountId(accountId);
        return REQUIRED.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .filter(required -> {
                    var versions = accepted.stream()
                            .filter(c -> c.getDocument() == required.getKey())
                            .map(Consent::getVersion)
                            .toList();
                    return !versions.isEmpty()
                            && !versions.contains(required.getValue().version());
                })
                .map(required -> new PendingConsent(
                        required.getValue().slug(), required.getValue().version()))
                .toList();
    }

    /** A version that is not the current one is a 409 LEGAL_VERSION_OUTDATED: the text changed while reading. */
    @Transactional
    void accept(UUID accountId, ConsentRequest request) {
        var now = clock.instant();
        for (var accepted : request.accepted()) {
            var document = REQUIRED.entrySet().stream()
                    .filter(required -> required.getValue().slug().equals(accepted.document()))
                    .findFirst()
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unknown document."));
            if (!document.getValue().version().equals(accepted.version())) {
                throw AuthException.legalVersionOutdated();
            }
            consents.save(new Consent(accountId, document.getKey(), accepted.version(), now));
        }
    }
}
