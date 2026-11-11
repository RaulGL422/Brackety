package dev.rgal.brackety.eventpackage;

import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.Cif;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.participant.ParticipantService;
import jakarta.validation.Validator;
import java.time.Period;
import java.util.HashSet;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

/** What a package must hold to load, beyond its JSON shape; the messages never quote its content. */
final class EventPackageRules {

    private EventPackageRules() {}

    static void check(EventPackage p, Validator validator) {
        var violations = validator.validate(p);
        if (!violations.isEmpty()) {
            throw new InvalidEventPackageException(violations.stream()
                    .map(v -> v.getPropertyPath() + ": " + v.getMessage())
                    .sorted()
                    .collect(Collectors.joining("; ")));
        }
        checkOwner(p);
        checkStaff(p.staff());
        checkCategories(p.categories());
        checkOrganizations(p.organizationsOrEmpty());
        checkMats(p);
        checkParticipants(p);
    }

    private static void checkOwner(EventPackage p) {
        var owner = p.owner();
        if (owner.taxId() != null && !Cif.isValid(Cif.normalize(owner.taxId()))) {
            throw invalid("owner.taxId: not a valid CIF");
        }
        if (!p.staff().contains(new EventPackage.StaffMember(username(owner.username()), EventRole.CLUB))) {
            throw invalid("owner: must be in staff with role CLUB");
        }
    }

    private static void checkStaff(List<EventPackage.StaffMember> staff) {
        var seen = new HashSet<EventPackage.StaffMember>();
        for (int i = 0; i < staff.size(); i++) {
            var member = staff.get(i);
            if (!member.username().equals(username(member.username()))) {
                throw invalid("staff[" + i + "].username: must be lowercase, without spaces around");
            }
            if (!seen.add(member)) {
                throw invalid("staff[" + i + "]: repeats an account with the same role");
            }
        }
    }

    private static void checkCategories(List<EventPackage.Category> categories) {
        var names = new HashSet<String>();
        for (int i = 0; i < categories.size(); i++) {
            var c = categories.get(i);
            if (!names.add(c.name().strip())) {
                throw invalid("categories[" + i + "].name: repeated");
            }
            if (c.minAge() > c.maxAge()) {
                throw invalid("categories[" + i + "]: minAge is above maxAge");
            }
            if ((c.format() == EventCategory.Format.TEAM) != (c.teamSize() != null)) {
                throw invalid("categories[" + i + "]: teamSize is set for TEAM and only for TEAM");
            }
        }
    }

    private static void checkOrganizations(List<EventPackage.OrganizationEntry> organizations) {
        var names = new HashSet<String>();
        for (int i = 0; i < organizations.size(); i++) {
            if (!names.add(organizations.get(i).name().strip())) {
                throw invalid("organizations[" + i + "].name: repeated");
            }
        }
    }

    private static void checkMats(EventPackage p) {
        var numbers =
                p.mats().stream().map(EventPackage.MatEntry::number).sorted().toList();
        if (!numbers.equals(IntStream.rangeClosed(1, numbers.size()).boxed().toList())) {
            throw invalid("mats: numbers must go from 1 to the number of mats, each once");
        }
        var referees = new HashSet<String>();
        for (int i = 0; i < p.mats().size(); i++) {
            var referee = p.mats().get(i).refereeUsername();
            if (referee == null) {
                continue;
            }
            if (!p.staff().contains(new EventPackage.StaffMember(referee, EventRole.REFEREE))) {
                throw invalid("mats[" + i + "].refereeUsername: not in staff with role REFEREE");
            }
            if (!referees.add(referee)) {
                throw invalid("mats[" + i + "].refereeUsername: already on another mat");
            }
        }
    }

    private static void checkParticipants(EventPackage p) {
        var categories = p.categories().stream().map(c -> c.name().strip()).collect(Collectors.toSet());
        var organizations =
                p.organizationsOrEmpty().stream().map(o -> o.name().strip()).collect(Collectors.toSet());
        var persons = new HashSet<UUID>();
        for (int i = 0; i < p.participants().size(); i++) {
            var participant = p.participants().get(i);
            if (participant.personId() != null && !persons.add(participant.personId())) {
                throw invalid("participants[" + i + "].personId: repeated");
            }
            if (participant.organizationName() != null
                    && !organizations.contains(participant.organizationName().strip())) {
                throw invalid("participants[" + i + "].organizationName: not one of the package's organizations");
            }
            if (participant.categoryName() != null && !categories.contains(participant.categoryName())) {
                throw invalid("participants[" + i + "].categoryName: not one of the package's categories");
            }
            var age = Period.between(participant.birthDate(), p.event().date()).getYears();
            if (age < ParticipantService.ADULT_AGE && !participant.guardianConsent()) {
                throw invalid("participants[" + i + "]: a minor needs guardianConsent");
            }
        }
    }

    static String username(String username) {
        return Account.normalizeEmail(username);
    }

    private static InvalidEventPackageException invalid(String message) {
        return new InvalidEventPackageException(message);
    }
}
