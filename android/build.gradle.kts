allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    if (name == "isar_flutter_libs") {
        // Isar 3.1 hardcodes compileSdk 30; finalize its DSL at the app SDK level.
        plugins.withId("com.android.library") {
            extensions.configure<
                com.android.build.api.variant.LibraryAndroidComponentsExtension
            > {
                finalizeDsl { extension ->
                    extension.namespace = "dev.isar.isar_flutter_libs"
                    extension.compileSdk = 36
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
