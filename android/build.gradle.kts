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
        plugins.withId("com.android.library") {
            extensions.findByName("android")?.let { androidExtension ->
                val setNamespace =
                    androidExtension.javaClass.methods.firstOrNull {
                        it.name == "setNamespace" &&
                            it.parameterTypes.size == 1 &&
                            it.parameterTypes[0] == String::class.java
                    }
                setNamespace?.invoke(androidExtension, "dev.isar.isar_flutter_libs")
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
