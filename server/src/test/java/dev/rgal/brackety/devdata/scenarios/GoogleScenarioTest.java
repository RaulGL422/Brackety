package dev.rgal.brackety.devdata.scenarios;

import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.IdentityRepository;
import dev.rgal.brackety.auth.google.FakeGoogle;
import dev.rgal.brackety.auth.google.GoogleSignInService;
import dev.rgal.brackety.devdata.ScenarioContext;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.support.TransactionOperations;

class GoogleScenarioTest extends AuthIntegrationTest {

    @Autowired
    AuthService auth;

    @Autowired
    AccountRepository accounts;

    @Autowired
    IdentityRepository identities;

    @Autowired
    GoogleSignInService googleSignIn;

    @Autowired
    FakeGoogle google;

    @Autowired
    TransactionOperations transactions;

    @Test
    void seedsAccountsReadyForEveryGoogleCase() {
        var scenario = new GoogleScenario(auth, accounts, identities);

        transactions.executeWithoutResult(status -> scenario.seed(new ScenarioContext(clock)));

        assertThat(signIn(GoogleScenario.GOOGLE_ONLY_SUBJECT, GoogleScenario.GOOGLE_ONLY)
                        .session()
                        .emailVerified())
                .isTrue();
        assertThat(signIn(GoogleScenario.LINKED_SUBJECT, GoogleScenario.LINKED_GOOGLE_EMAIL)
                        .session())
                .isNotNull();
        assertThat(auth.login(GoogleScenario.LINKED, GoogleScenario.PASSWORD, "127.0.0.1")
                        .emailVerified())
                .isTrue();
        var replaced = googleSignIn.signIn(
                google.idToken("google-nueva", GoogleScenario.UNVERIFIED), details(LocalDate.of(1990, 5, 20)));
        assertThat(replaced.replacedUnverifiedAccount()).isTrue();
    }

    private GoogleSignInService.Result signIn(String subject, String email) {
        return googleSignIn.signIn(google.idToken(subject, email), null);
    }
}
