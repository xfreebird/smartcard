package md.moldsign.app.application

import md.moldsign.core.ValidationReport
import md.moldsign.core.Verdict

/** Result of "Verifică": one report per signature found. */
data class VerifyOutcome(val reports: List<ValidationReport>) {
    val verdict: Verdict get() = Verdict.of(reports)

    /** Documents a detached XAdES refers to and that the user still has to pick. */
    val missingDocuments: List<String> get() = reports.flatMap { it.missingDocuments }.distinct()
}
