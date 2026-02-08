import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory


allprojects {
    repositories {
        google()
        mavenCentral()
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
            android.compileSdkVersion = "android-34"
        }
    }
    plugins.withId("com.android.library") {
        val android = extensions.getByName("android") as com.android.build.gradle.BaseExtension
        if (android.compileSdkVersion == null) {
            android.compileSdkVersion = "android-34"
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
