import org.jetbrains.kotlin.gradle.dsl.JvmTarget

// Pure Kotlin/JVM port of the MoldSign core (no Android dependencies), see docs/09-architecture.md.
plugins {
    alias(libs.plugins.kotlin.jvm)
    `java-library`
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    // StateFlow for SigningService.readerState / progress (pure JVM, no Android).
    api(libs.kotlinx.coroutines.core)

    testImplementation(libs.junit)
}

// Single source of truth for the bridge allow-list: package spec/bridge/allowed-origins.properties
// into the jar as md/moldsign/core/allowed-origins.properties (BridgeOriginPolicy.bundled()).
tasks.processResources {
    from(rootProject.file("../swift/MoldSignKit/Sources/MoldSignKit/Resources/PDFStamp")) { into("md/moldsign/core/pdfstamp") }
    from(rootProject.file("../spec/bridge/allowed-origins.properties")) {
        into("md/moldsign/core")
    }
    // The vendor localhost.cts.md TLS identity for the bridge's HTTPS listener (BridgeTls), shared with the Apple apps.
    from(rootProject.file("../swift/MoldSignKit/Resources/localhost.p12")) {
        into("md/moldsign/core")
    }
}

tasks.test {
    // Hint for VectorFiles: the repo root holds spec/vectors/. The loader also walks up from the
    // working directory, so running the tests from an IDE works without this property.
    systemProperty("moldsign.repoRoot", rootProject.projectDir.parentFile.absolutePath)
    testLogging {
        events("passed", "skipped", "failed")
        exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
    }
}
