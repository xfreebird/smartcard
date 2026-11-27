import org.gradle.api.attributes.java.TargetJvmEnvironment
import org.gradle.api.attributes.java.TargetJvmVersion

// Root build: plugin versions live in gradle/libs.versions.toml; modules apply them.
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.kotlin.jvm) apply false
    alias(libs.plugins.kotlin.compose) apply false
}

// AGP 9.5.3 loads these tools lazily during packaging/lint. Resolve every supported
// host classifier when refreshing checksums, even from a Mac-only development host.
val verificationProject = project(":core")
val verificationTooling = verificationProject.configurations.create("verificationToolingClasspath") {
    isCanBeConsumed = false
    isCanBeResolved = true
    attributes {
        attribute(Usage.USAGE_ATTRIBUTE, objects.named(Usage.JAVA_RUNTIME))
        attribute(Category.CATEGORY_ATTRIBUTE, objects.named(Category.LIBRARY))
        attribute(LibraryElements.LIBRARY_ELEMENTS_ATTRIBUTE, objects.named(LibraryElements.JAR))
        attribute(TargetJvmEnvironment.TARGET_JVM_ENVIRONMENT_ATTRIBUTE, objects.named(TargetJvmEnvironment.STANDARD_JVM))
        attribute(TargetJvmVersion.TARGET_JVM_VERSION_ATTRIBUTE, 17)
    }
}
verificationProject.dependencies.add(verificationTooling.name, "com.android.tools.lint:lint-gradle:32.5.3")
listOf("linux", "osx", "windows").forEach { host ->
    verificationProject.dependencies.add(verificationTooling.name, "com.android.tools.build:aapt2:9.5.3-16666295:$host")
}

// Resolve only from each configuration's owning project: Gradle 9 requires its
// exclusive project lock. The root task aggregates these dependency-only tasks.
val verificationAgpVersion = libs.versions.agp.get()
subprojects {
    tasks.register("resolveDependencyVerification") {
        doLast {
            require(verificationAgpVersion == "9.5.3") { "Refresh verification tooling coordinates for the new AGP version." }
            project.configurations.filter {
                it.isCanBeResolved && (it.name.contains("Classpath", ignoreCase = true) ||
                    it.name.contains("aapt2", ignoreCase = true))
            }.forEach { configuration ->
                configuration.incoming.artifactView {
                    // Project variants are built later; only verify downloaded modules here.
                    componentFilter { it is org.gradle.api.artifacts.component.ModuleComponentIdentifier }
                }.files.files
            }
        }
    }
}
tasks.register("resolveDependencyVerification") {
    dependsOn(subprojects.map { "${it.path}:resolveDependencyVerification" })
}
