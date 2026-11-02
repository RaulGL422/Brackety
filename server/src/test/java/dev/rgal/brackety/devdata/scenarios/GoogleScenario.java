package dev.rgal.brackety.devdata.scenarios;

import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.Identity;
import dev.rgal.brackety.auth.account.IdentityRepository;
import dev.rgal.brackety.auth.account.ProfileType;
import dev.rgal.brackety.devdata.DevScenario;
import dev.rgal.brackety.devdata.Scenario;
import dev.rgal.brackety.devdata.ScenarioContext;

// Sign in to these with ID tokens from POST /api/v1/auth/dev/google-token (local runner only).
@DevScenario
class GoogleScenario implements Scenario {

    static final String PASSWORD = "brackety-demo";
    static final String GOOGLE_ONLY = "google@example.test";
    static final String GOOGLE_ONLY_SUBJECT = "google-solo";
    static final String LINKED = "vinculada@example.test";
    static final String LINKED_SUBJECT = "google-vinculada";
    static final String LINKED_GOOGLE_EMAIL = "vinculada.gmail@example.test";
    static final String UNVERIFIED = "sustituible@example.test";

    private final AuthService auth;
    private final AccountRepository accounts;
    private final IdentityRepository identities;

    GoogleScenario(AuthService auth, AccountRepository accounts, IdentityRepository identities) {
        this.auth = auth;
        this.accounts = accounts;
        this.identities = identities;
    }

    @Override
    public String name() {
        return "google";
    }

    @Override
    public String description() {
        return GOOGLE_ONLY + " with Google only (sub " + GOOGLE_ONLY_SUBJECT + "), " + LINKED + " with password '"
                + PASSWORD + "' and Google " + LINKED_GOOGLE_EMAIL + " (sub " + LINKED_SUBJECT + "), " + UNVERIFIED
                + " unverified, to be replaced by a Google sign-up with that email";
    }

    @Override
    public void seed(ScenarioContext ctx) {
        var now = ctx.now().toInstant();
        var googleOnly = auth.createAccount(
                GOOGLE_ONLY,
                null,
                SignUps.of(GOOGLE_ONLY, null, ProfileType.STUDENT, "es", ctx).details());
        googleOnly.markEmailVerified(now);
        identities.save(
                new Identity(googleOnly.getId(), Identity.Provider.GOOGLE, GOOGLE_ONLY_SUBJECT, GOOGLE_ONLY, now));

        auth.register(SignUps.of(LINKED, PASSWORD, ProfileType.CLUB, "es", ctx));
        var linked = accounts.findByEmail(LINKED).orElseThrow();
        linked.markEmailVerified(now);
        identities.save(
                new Identity(linked.getId(), Identity.Provider.GOOGLE, LINKED_SUBJECT, LINKED_GOOGLE_EMAIL, now));

        auth.register(SignUps.of(UNVERIFIED, PASSWORD, ProfileType.CLUB, "es", ctx));
    }
}
