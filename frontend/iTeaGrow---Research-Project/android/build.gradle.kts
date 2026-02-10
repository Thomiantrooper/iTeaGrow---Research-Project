import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory


allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Provide flutter ext properties for plugins that use the old-style build.gradle
// (e.g. geolocator_android which references flutter.compileSdkVersion)
// Skip :app since it has the real Flutter Gradle plugin
subprojects {
    if (project.name != "app") {
        project.extra.apply {
            set("flutter", mapOf(
                "compileSdkVersion" to 35,
                "minSdkVersion" to 26,
                "targetSdkVersion" to 35
            ))
        }
    }
}

// Move root build directory
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    plugins.withId("com.android.application") {
        val android = extensions.getByName("android") as com.android.build.gradle.BaseExtension
        if (android.compileSdkVersion == null) {
            android.compileSdkVersion = "android-35"
        }
    }
    plugins.withId("com.android.library") {
        val android = extensions.getByName("android") as com.android.build.gradle.LibraryExtension
        if (android.compileSdkVersion == null) {
            android.compileSdkVersion = "android-35"
        }
        // Auto-set namespace for old plugins that only have package in AndroidManifest.xml
        if (android.namespace == null || android.namespace!!.isEmpty()) {
            android.namespace = project.group.toString()
        }
    }
}

subprojects {
    evaluationDependsOn(":app")
}

// Register clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
