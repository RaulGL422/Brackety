package dev.rgal.brackety.eventpackage;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import dev.rgal.brackety.auth.account.ProfileType;
import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Random;
import java.util.UUID;
import java.util.function.Consumer;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.beans.factory.annotation.Autowired;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;
import tools.jackson.databind.node.ObjectNode;

// The demo event (5 mats with referees, 9 categories, the 4 oldest by teams) with yoseikan-f1 style participants.
class EventPackageServiceTest extends EventApiTest {

    private static final List<String> NAMES = List.of("Lucía", "Hugo", "Martina", "Mateo", "Sofía", "Álvaro");
    private static final int[] AGES = {4, 6, 7, 9, 10, 12, 13, 15, 15, 17, 22, 30};
    private static final int PARTICIPANTS = 24;
    private static final int STAFF = 8;

    @Autowired
    EventPackageService packages;

    @Autowired
    ParticipantRepository participants;

    @Autowired
    JsonMapper json;

    @BeforeEach
    void yoseikanParticipantsAndOwnSettings() {
        var random = new Random(2027);
        var teamCategory = categoryId("15-16");
        var today = clock.instant().atZone(clock.getZone()).toLocalDate();
        for (int i = 0; i < PARTICIPANTS; i++) {
            var age = AGES[i % AGES.length];
            var participant = new Participant(eventId, clock.instant());
            participant.update(
                    NAMES.get(random.nextInt(NAMES.size())),
                    "García Muñoz " + i,
                    today.minusYears(age).minusDays(random.nextInt(360)),
                    i % 5 == 0 ? null : Math.min(195, 95 + age * 6),
                    age < 18,
                    // A 13-year-old moved up to the team category.
                    age == 13 ? teamCategory : null);
            participants.save(participant);
        }
        jdbc.sql("update event set max_groups_per_mat = 2, match_seconds = 90, points_limit = 12,"
                        + " changeover_seconds = 20, attendance_points = 5")
                .update();
        jdbc.sql("update mat set referee_account_id = null where number = 5").update();
    }

    @Test
    void roundTripIntoAnEmptyDatabaseKeepsEverythingButIds() {
        var exported = packages.export(eventId, accountId("club1"));
        var file = json.writeValueAsBytes(exported);
        emptyDatabase();

        var loaded = packages.export(packages.load(file).eventId(), accountId("club1"));

        assertThat(loaded.event()).isEqualTo(exported.event());
        assertThat(loaded.owner()).isEqualTo(exported.owner());
        assertThat(loaded.staff()).isEqualTo(exported.staff()).hasSize(STAFF);
        assertThat(loaded.categories()).isEqualTo(exported.categories()).hasSize(9);
        assertThat(loaded.categories()).filteredOn(c -> c.teamSize() != null).hasSize(4);
        assertThat(loaded.mats()).isEqualTo(exported.mats()).hasSize(5);
        assertThat(loaded.mats().get(4).refereeUsername()).isNull();
        assertThat(loaded.participants()).isEqualTo(exported.participants()).hasSize(PARTICIPANTS);
        assertThat(loaded.participants())
                .filteredOn(p -> "15-16".equals(p.categoryName()))
                .hasSize(2);
        assertThat(count("event")).isOne();
    }

    @Test
    void createsTheStaffAccountsVerifiedWithRandomPasswords() {
        var file = exportFile();
        emptyDatabase();

        var created = packages.load(file).newAccounts();

        assertThat(count("account")).isEqualTo(STAFF);
        assertThat(created).hasSize(STAFF);
        var referee = created.stream()
                .filter(a -> a.username().equals("arbitro1"))
                .findFirst()
                .orElseThrow();
        assertThat(referee.roles()).isEqualTo("REFEREE");
        assertThat(referee.mats()).isEqualTo("1");
        assertThat(referee.password())
                .hasSize(StaffPasswords.LENGTH)
                .matches("[" + StaffPasswords.ALPHABET + "]+")
                .doesNotContain("l", "1", "o", "0");
        assertThat(auth.login("arbitro1", referee.password(), "127.0.0.1").emailVerified())
                .isTrue();
        assertThatThrownBy(() -> auth.login("arbitro1", "arbitro1", "127.0.0.1"));
        assertThat(created).extracting(LoadedPackage.NewAccount::password).doesNotHaveDuplicates();
        assertThat(jdbc.sql("select organization_name from profile p join account a on a.id = p.account_id"
                                + " where a.email = 'club1' and p.type = 'CLUB'")
                        .query(String.class)
                        .single())
                .isEqualTo("Club Demo Yoseikan");
    }

    @Test
    void reusesAnAccountThatAlreadyExists() {
        var file = exportFile();
        emptyDatabase();
        auth.register(registration("ayudante1", ProfileType.HELPER, "es"));

        var created = packages.load(file).newAccounts();

        assertThat(count("account")).isEqualTo(STAFF);
        assertThat(auth.login("ayudante1", PASSWORD, "127.0.0.1").accessToken()).isNotBlank();
        assertThat(created)
                .extracting(LoadedPackage.NewAccount::username)
                .hasSize(STAFF - 1)
                .doesNotContain("ayudante1");
    }

    @Test
    void refusedWhenTheDatabaseHasAnEvent() {
        var file = exportFile();

        assertThatThrownBy(() -> packages.load(file))
                .isInstanceOf(InvalidEventPackageException.class)
                .hasMessageContaining("already has an event");
        assertThat(count("event")).isOne();
        assertThat(count("participant")).isEqualTo(PARTICIPANTS);
    }

    @Test
    void refusesAnUnknownSchemaVersion() {
        var unknown = EventPackage.SCHEMA_VERSION + 1;
        var file = edit(root -> root.put("schemaVersion", unknown));
        emptyDatabase();

        assertThatThrownBy(() -> packages.load(file)).hasMessageContaining("unknown schemaVersion " + unknown);
    }

    @Test
    void invalidContentIsRefusedNamingTheRowAndNothingIsWritten() {
        var last = PARTICIPANTS - 1;
        var cases = List.<Case>of(
                new Case(
                        r -> participant(r, last).put("categoryName", "Senior"),
                        "participants[" + last + "].categoryName"),
                new Case(
                        r -> participant(r, 0).put("birthDate", "2025-01-01").put("guardianConsent", false),
                        "participants[0]: a minor"),
                new Case(r -> participant(r, 1).put("firstName", " "), "participants[1].firstName"),
                new Case(r -> participant(r, 2).put("birthDate", "2020-13-40"), "participants[2].birthDate"),
                new Case(r -> mat(r, 1).put("number", 1), "mats: numbers"),
                new Case(r -> mat(r, 0).put("refereeUsername", "ayudante1"), "mats[0].refereeUsername"),
                new Case(r -> r.withObject("owner").put("username", "arbitro1"), "owner: must be in staff"),
                new Case(r -> r.withObject("event").put("maxGroupsPerMat", 9), "event.maxGroupsPerMat"),
                new Case(r -> ((ObjectNode) r.get("categories").get(0)).put("teamSize", 3), "categories[0]"));
        var files = cases.stream().map(c -> edit(c.change())).toList();
        emptyDatabase();

        for (int i = 0; i < cases.size(); i++) {
            var file = files.get(i);
            assertThatThrownBy(() -> packages.load(file))
                    .isInstanceOf(InvalidEventPackageException.class)
                    .hasMessageContaining(cases.get(i).message())
                    .hasMessageNotContainingAny(NAMES.toArray(String[]::new));
        }
        assertThat(count("account") + count("event") + count("participant")).isZero();
    }

    @Test
    void theStartupLoaderLoadsTheFileOrStopsWithTheReason(@TempDir Path dir) throws Exception {
        var file = Files.write(dir.resolve("f1.brackety"), exportFile());
        var credentials = dir.resolve("credentials.txt");
        var loader = new EventPackageLoader(packages, file.toString(), credentials.toString());

        assertThatThrownBy(loader::afterSingletonsInstantiated)
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("Event package f1.brackety not loaded: "
                        + "the database already has an event: a package only loads into an empty one");
        emptyDatabase();
        loader.afterSingletonsInstantiated();
        assertThat(count("participant")).isEqualTo(PARTICIPANTS);
        var lines = Files.readAllLines(credentials);
        assertThat(lines).hasSize(STAFF + 1).first().isEqualTo(EventPackageLoader.CREDENTIALS_HEADER);
        var referee = lines.stream()
                .filter(l -> l.startsWith("arbitro2;"))
                .findFirst()
                .orElseThrow()
                .split(";");
        assertThat(referee).hasSize(4);
        assertThat(referee[1]).isEqualTo("REFEREE");
        assertThat(referee[3]).isEqualTo("2");
        assertThat(auth.login("arbitro2", referee[2], "127.0.0.1").accessToken())
                .isNotBlank();
    }

    @Test
    void theStartupLoaderNeedsTheCredentialsFile(@TempDir Path dir) throws Exception {
        var file = Files.write(dir.resolve("f1.brackety"), exportFile());
        emptyDatabase();

        assertThatThrownBy(new EventPackageLoader(packages, file.toString(), " ")::afterSingletonsInstantiated)
                .hasMessageContaining("BRACKETY_PACKAGE_CREDENTIALS is required");
        assertThat(count("account")).isZero();
    }

    private record Case(Consumer<ObjectNode> change, String message) {}

    private byte[] exportFile() {
        return json.writeValueAsBytes(packages.export(eventId, accountId("club1")));
    }

    private byte[] edit(Consumer<ObjectNode> change) {
        var root = (ObjectNode) json.readTree(exportFile());
        change.accept(root);
        return json.writeValueAsBytes(root);
    }

    private static ObjectNode participant(JsonNode root, int index) {
        return (ObjectNode) root.get("participants").get(index);
    }

    private static ObjectNode mat(JsonNode root, int index) {
        return (ObjectNode) root.get("mats").get(index);
    }

    private void emptyDatabase() {
        jdbc.sql("truncate account cascade").update();
    }

    private UUID categoryId(String name) {
        return jdbc.sql("select id from event_category where name = ?")
                .param(name)
                .query(UUID.class)
                .single();
    }
}
