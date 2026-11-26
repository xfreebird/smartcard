// USB host CCID transport + reader monitor (AND-02, AND-03).
plugins {
    alias(libs.plugins.android.library)
}

android {
    namespace = "md.moldsign.transport.usb"
    compileSdk = 36

    defaultConfig {
        minSdk = 26
    }

    buildTypes {
        debug { enableUnitTestCoverage = providers.gradleProperty("sonarCoverage").orNull == "true" }
    }

    testCoverage { jacocoVersion = libs.versions.jacoco.get() }

    // android.util.Log in the monitor's error paths returns quietly on the JVM.
    testOptions { unitTests.isReturnDefaultValues = true }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

// Built-in Kotlin inherits JVM 17 from android.compileOptions.

dependencies {
    api(project(":core"))
    implementation(libs.androidx.core.ktx)
    implementation(libs.kotlinx.coroutines.android)

    testImplementation(libs.junit)
}
