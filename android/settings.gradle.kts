pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    // Resolve plugin IDs straight to their implementation modules. This keeps `--offline` builds
    // working when only the plugin jars (not the plugin-marker POMs) are in the Gradle cache.
    resolutionStrategy {
        eachPlugin {
            when (requested.id.id) {
                "com.android.application", "com.android.library" ->
                    useModule("com.android.tools.build:gradle:${requested.version}")
                "org.jetbrains.kotlin.jvm" ->
                    useModule("org.jetbrains.kotlin:kotlin-gradle-plugin:${requested.version}")
                "org.jetbrains.kotlin.plugin.compose" ->
                    useModule("org.jetbrains.kotlin:compose-compiler-gradle-plugin:${requested.version}")
            }
        }
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        // Maven Central rate-limits CI addresses, even for requests about Robolectric's 151 MB framework jar
        // that Gradle has cached. CI therefore restores that jar into a local Maven folder
        // (scripts/ci/robolectric-cache.sh), and Gradle takes it only from there; dependency verification still
        // checks its pinned SHA-256. Without the variable, Maven Central serves it as before.
        providers.environmentVariable("ROBOLECTRIC_LOCAL_REPOSITORY").orNull?.let { folder ->
            exclusiveContent {
                forRepository { maven(file(folder)) { name = "RobolectricAndroidAll" } }
                filter { includeModule("org.robolectric", "android-all-instrumented") }
            }
        }
        google()
        mavenCentral()
    }
}

rootProject.name = "MoldSign"

include(":core", ":transport-usb", ":app")
