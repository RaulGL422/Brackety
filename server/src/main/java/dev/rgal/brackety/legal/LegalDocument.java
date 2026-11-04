package dev.rgal.brackety.legal;

import java.util.Arrays;
import java.util.Optional;

/** The legal texts and their current versions; a material change bumps the version and asks for a new acceptance. */
public enum LegalDocument {
    PRIVACY("privacy", "2026-11-04", true),
    TERMS("terms", "2026-11-04", true),
    COOKIES("cookies", "2026-11-04", false),
    LEGAL_NOTICE("legal-notice", "2026-11-04", false);

    private final String slug;
    private final String version;
    private final boolean acceptanceRequired;

    LegalDocument(String slug, String version, boolean acceptanceRequired) {
        this.slug = slug;
        this.version = version;
        this.acceptanceRequired = acceptanceRequired;
    }

    public String slug() {
        return slug;
    }

    public String version() {
        return version;
    }

    public boolean acceptanceRequired() {
        return acceptanceRequired;
    }

    public static Optional<LegalDocument> fromSlug(String slug) {
        return Arrays.stream(values()).filter(d -> d.slug.equals(slug)).findFirst();
    }
}
