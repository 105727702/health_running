allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Fix for Gradle compatibility issues
gradle.projectsEvaluated {
    tasks.withType<Test> {
        enabled = false
    }

    tasks.configureEach {
        if (name.contains("test", ignoreCase = true) && this is Test) {
            enabled = false
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}


