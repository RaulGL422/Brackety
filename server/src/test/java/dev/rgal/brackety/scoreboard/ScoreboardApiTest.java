package dev.rgal.brackety.scoreboard;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;

// Demo event on 2027-03-10: a group of 6-year-olds (one-hand rule) goes to mat 1 (arbitro1),
// a group of 9-year-olds to mat 2 (arbitro2).
abstract class ScoreboardApiTest extends EventApiTest {

    @Autowired
    ParticipantRepository participants;

    List<UUID> young;
    List<UUID> older;

    @BeforeEach
    void createGroups() throws Exception {
        young = participants(6, "Peque");
        older = participants(9, "Mayor");
        group("4-6", young);
        group("9-10", older);
    }

    UUID match(List<UUID> group, int red, int blue) {
        return jdbc.sql("select id from fight_match where red_participant_id = ? and blue_participant_id = ?")
                .params(group.get(red), group.get(blue))
                .query(UUID.class)
                .single();
    }

    UUID matOf(UUID match) {
        return jdbc.sql("select mat_id from fight_match where id = ?")
                .param(match)
                .query(UUID.class)
                .single();
    }

    static String path(UUID match) {
        return "/api/v1/matches/" + match;
    }

    private List<UUID> participants(int age, String name) {
        var ids = new ArrayList<UUID>();
        for (int i = 0; i < 4; i++) {
            var participant = new Participant(eventId, clock.instant());
            participant.update(name + i, "Prueba", LocalDate.of(2027, 3, 1).minusYears(age), 110, true);
            ids.add(participants.save(participant).getId());
        }
        return ids;
    }

    private void group(String category, List<UUID> members) throws Exception {
        var categoryId = jdbc.sql("select id from event_category where name = ?")
                .param(category)
                .query(UUID.class)
                .single();
        var ids = members.stream().map(id -> "\"" + id + "\"").collect(Collectors.joining(","));
        call(post("/api/v1/events/" + eventId + "/groups").content("""
                                {"categoryId":"%s","groups":[{"participantIds":[%s]}]}""".formatted(categoryId, ids)), "ayudante1")
                .andExpect(status().isCreated());
    }
}
