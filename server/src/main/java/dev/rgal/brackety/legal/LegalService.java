package dev.rgal.brackety.legal;

import dev.rgal.brackety.legal.dto.LegalTextResponse;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.MessageSource;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

/** The legal texts in Markdown, read once at startup with the owner and privacy contact filled in. */
@Service
public class LegalService {

    static final List<String> LANGS = List.of("es", "en");
    static final String DEFAULT_LANG = "es";

    private final boolean privacyContactConfigured;
    private final Map<LegalDocument, Map<String, String>> texts = new EnumMap<>(LegalDocument.class);

    LegalService(
            MessageSource messages,
            @Value("${brackety.legal.owner-name}") String ownerName,
            @Value("${brackety.legal.privacy-contact-email}") String privacyEmail) {
        this.privacyContactConfigured = !privacyEmail.isBlank();
        for (var document : LegalDocument.values()) {
            var byLang = new HashMap<String, String>();
            for (var lang : LANGS) {
                var notConfigured = messages.getMessage("legal.not-configured", null, Locale.forLanguageTag(lang));
                byLang.put(
                        lang,
                        read(document, lang)
                                .replace("{{OWNER_NAME}}", orElse(ownerName, notConfigured))
                                .replace("{{PRIVACY_EMAIL}}", orElse(privacyEmail, notConfigured))
                                .replace("{{VERSION}}", document.version()));
            }
            texts.put(document, byLang);
        }
    }

    private static String orElse(String value, String fallback) {
        return value.isBlank() ? fallback : value.strip();
    }

    /** Without it the API must not publish events nor advance phases (the legal gate). */
    public boolean isPrivacyContactConfigured() {
        return privacyContactConfigured;
    }

    /** Empty for an unknown type; an unknown or missing language falls back to Spanish. */
    public Optional<LegalTextResponse> text(String slug, String lang) {
        var language = lang != null && LANGS.contains(lang) ? lang : DEFAULT_LANG;
        return LegalDocument.fromSlug(slug)
                .map(d -> new LegalTextResponse(
                        d.slug(), d.version(), language, texts.get(d).get(language)));
    }

    // A missing file stops the startup: a deploy without its legal texts must not go live.
    private static String read(LegalDocument document, String lang) {
        var path = "legal/" + document.slug() + "." + lang + ".md";
        var resource = new ClassPathResource(path);
        if (!resource.exists()) {
            throw new IllegalStateException("Missing legal text " + path);
        }
        try {
            return resource.getContentAsString(StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
