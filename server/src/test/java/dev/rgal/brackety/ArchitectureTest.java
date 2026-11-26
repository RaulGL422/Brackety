package dev.rgal.brackety;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.methods;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.dependencies.SlicesRuleDefinition.slices;

import com.tngtech.archunit.core.domain.JavaMethod;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchCondition;
import com.tngtech.archunit.lang.ArchRule;
import com.tngtech.archunit.lang.ConditionEvents;
import com.tngtech.archunit.lang.SimpleConditionEvent;
import jakarta.persistence.Entity;
import org.springframework.web.bind.annotation.RestController;

/** The structure rules of .claude/rules/backend-java.md, checked on every build. */
@AnalyzeClasses(packages = "dev.rgal.brackety", importOptions = ImportOption.DoNotIncludeTests.class)
class ArchitectureTest {

    @ArchTest
    static final ArchRule featuresHaveNoCycles =
            slices().matching("dev.rgal.brackety.(*)..").should().beFreeOfCycles();

    // A thin controller validates, calls its service and returns a DTO.
    @ArchTest
    static final ArchRule controllersDoNotUseRepositories = noClasses()
            .that()
            .areAnnotatedWith(RestController.class)
            .should()
            .dependOnClassesThat()
            .haveSimpleNameEndingWith("Repository");

    @ArchTest
    static final ArchRule controllersNeverReturnEntities = methods()
            .that()
            .areDeclaredInClassesThat()
            .areAnnotatedWith(RestController.class)
            .should(notReturnAnEntity());

    @ArchTest
    static final ArchRule nothingDependsOnControllers = noClasses()
            .that()
            .areNotAnnotatedWith(RestController.class)
            .should()
            .dependOnClassesThat()
            .areAnnotatedWith(RestController.class);

    // Demo data is only for local runs and tests; no feature may need it.
    @ArchTest
    static final ArchRule nothingDependsOnDemo = noClasses()
            .that()
            .resideOutsideOfPackage("dev.rgal.brackety.demo..")
            .should()
            .dependOnClassesThat()
            .resideInAPackage("dev.rgal.brackety.demo..");

    // Without a locale, a server in Turkish lower-cases "I" to a dotless "ı": names stop matching (duplicates in an
    // import, warning reasons) and "MULTIPART" stops being multipart.
    @ArchTest
    static final ArchRule caseChangesNameTheirLocale = noClasses()
            .should()
            .callMethod(String.class, "toLowerCase")
            .orShould()
            .callMethod(String.class, "toUpperCase")
            .because("String.toLowerCase(Locale.ROOT) gives the same result on every server");

    // Also inside ResponseEntity, Optional or List.
    private static ArchCondition<JavaMethod> notReturnAnEntity() {
        return new ArchCondition<>("not return a JPA entity") {
            @Override
            public void check(JavaMethod method, ConditionEvents events) {
                method.getReturnType().getAllInvolvedRawTypes().stream()
                        .filter(type -> type.isAnnotatedWith(Entity.class))
                        .forEach(entity -> events.add(SimpleConditionEvent.violated(
                                method, method.getFullName() + " returns the entity " + entity.getSimpleName())));
            }
        };
    }
}
