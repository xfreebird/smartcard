import org.gradle.testing.jacoco.plugins.JacocoTaskExtension

// USB host CCID transport + reader monitor (AND-02, AND-03).
plugins {
    alias(libs.plugins.android.library)
}

android {
    namespace = "md.moldsign.transport.usb"
    // Compose 1.13 requires Android API 37.1 or later to compile against; targetSdk stays separate.
    compileSdk {
        version = release(37) {
            minorApiLevel = 2
        }
    }

    defaultConfig {
        minSdk = 26
    }

    buildTypes {
        debug { enableUnitTestCoverage = providers.gradleProperty("sonarCoverage").orNull == "true" }
    }

    testCoverage { jacocoVersion = libs.versions.jacoco.get() }

    // android.util.Log in the monitor's error paths returns quietly on the JVM; the Android USB host
    // adapter runs on Robolectric with the library's merged manifest.
    testOptions {
        unitTests.isReturnDefaultValues = true
        unitTests.isIncludeAndroidResources = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

// Built-in Kotlin inherits JVM 17 from android.compileOptions.

// Robolectric's Android framework jar is a verified Gradle dependency used offline (as in :app).
val robolectricRuntimeClasspath: Configuration by configurations.creating {
    isCanBeConsumed = false
    isTransitive = false
}

dependencies {
    api(project(":core"))
    implementation(libs.androidx.core.ktx)
    implementation(libs.kotlinx.coroutines.android)

    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.robolectric)
    robolectricRuntimeClasspath(libs.robolectric.android.all)
}

val robolectricDependencies = tasks.register<Sync>("robolectricDependencies") {
    from(robolectricRuntimeClasspath)
    into(layout.buildDirectory.dir("robolectric"))
}
tasks.withType<Test>().configureEach {
    dependsOn(robolectricDependencies)
    val directory = robolectricDependencies.map { it.destinationDir.absolutePath }
    inputs.files(robolectricRuntimeClasspath).withPropertyName("robolectricAndroidAll").withNormalizer(ClasspathNormalizer::class.java)
    systemProperty("robolectric.offline", "true")
    jvmArgumentProviders += CommandLineArgumentProvider { listOf("-Drobolectric.dependency.dir=${directory.get()}") }
}
// Robolectric defines classes without a code source; include them (project packages only) in coverage.
pluginManager.withPlugin("jacoco") {
    tasks.withType<Test>().configureEach {
        extensions.configure<JacocoTaskExtension> {
            isIncludeNoLocationClasses = true
            includes = listOf("md.moldsign.*")
            excludes = listOf("jdk.internal.*")
        }
    }
}
