//buildscript {
//    dependencies {
//        // Firebase Gradle Plugin
//        classpath("com.google.gms:google-services:4.3.15")
//    }
//}

buildscript {
    repositories {
        google()         // 👈 REQUIRED
        mavenCentral()   // 👈 Optional but useful
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.3.1")
        classpath("com.google.gms:google-services:4.3.15") // 👈 This needs google()
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
