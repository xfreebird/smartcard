plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
}

android {
    namespace = "md.moldsign.app"
    compileSdk = 36

    androidResources {
        generateLocaleConfig = true
    }

    defaultConfig {
        testInstrumentationRunner = "md.moldsign.app.FileProtectionInstrumentation"
        applicationId = "md.esemnbun.app"   // public ID (D-07); the Kotlin namespace keeps the codename
        minSdk = 26
        targetSdk = 36
        // ADJ-13: universal APK and Play ABI splits cover ARM and Intel phones/tablets.
        ndk { abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64") }
        val buildNumber = providers.environmentVariable("BUILD_NUMBER").orNull
        require(buildNumber == null || (buildNumber.matches(Regex("[1-9][0-9]*")) &&
            buildNumber.toLongOrNull()?.let { it <= 2_100_000_000L } == true)) {
            "BUILD_NUMBER must be a positive whole number no greater than 2100000000"
        }
        versionCode = buildNumber?.toInt() ?: 2
        versionName = "0.2.14"
        manifestPlaceholders["appLabel"] = "@string/app_name"
    }

    buildTypes {
        debug {
            // Opt-in separate install preserves the Play-signed app and its saved credentials.
            if (providers.gradleProperty("nfcTestInstall").orNull == "true") {
                applicationIdSuffix = ".nfctest"
                manifestPlaceholders["appLabel"] = "@string/nfc_test_app_name"
            }
        }
        release {
            // AND-10: shrink, optimize and obfuscate the Play release; signing stays in the package script.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        buildConfig = true
        compose = true
    }

    packaging {
        resources.excludes += "/META-INF/{AL2.0,LGPL2.1}"
    }
}

// Built-in Kotlin inherits JVM 17 from android.compileOptions.

dependencies {
    implementation(project(":core"))
    implementation(project(":transport-usb"))

    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.webkit)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.appcompat) // Per-app locales on Android 12 and earlier
    implementation(libs.androidx.fragment) // FragmentActivity host for BiometricPrompt
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.navigation.compose)
    implementation(libs.androidx.biometric)
    implementation(libs.androidx.datastore.preferences)
    implementation(libs.kotlinx.coroutines.android)

    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.foundation)
    implementation(libs.compose.material3)
    implementation(libs.compose.material.icons.extended)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)

    testImplementation(libs.junit)
}
