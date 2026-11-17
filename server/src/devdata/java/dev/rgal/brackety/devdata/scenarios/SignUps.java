package dev.rgal.brackety.devdata.scenarios;

import dev.rgal.brackety.auth.account.ProfileType;
import dev.rgal.brackety.auth.dto.OrganizationRequest;
import dev.rgal.brackety.auth.dto.RegisterRequest;
import dev.rgal.brackety.devdata.ScenarioContext;
import dev.rgal.brackety.legal.LegalDocument;

/** Password sign-ups as the app sends them: organizers with a fictional organization, the rest aged 30. */
final class SignUps {

    // Fictional names; the CIFs only pass the check digit.
    static final OrganizationRequest CLUB = new OrganizationRequest("Club Deportivo Ejemplo", "G12345674");
    static final OrganizationRequest ENTITY = new OrganizationRequest("Federación Ejemplo", "Q1234567D");

    private SignUps() {}

    static RegisterRequest of(String email, String password, ProfileType profile, String locale, ScenarioContext ctx) {
        if (profile.isOrganizer()) {
            var organization = profile == ProfileType.CLUB ? CLUB : ENTITY;
            return new RegisterRequest(
                    email,
                    password,
                    profile,
                    null,
                    organization,
                    true,
                    LegalDocument.TERMS.version(),
                    LegalDocument.PRIVACY.version(),
                    locale);
        }
        return new RegisterRequest(
                email,
                password,
                profile,
                ctx.daysFromToday(-30 * 365),
                null,
                null,
                LegalDocument.TERMS.version(),
                LegalDocument.PRIVACY.version(),
                locale);
    }
}
