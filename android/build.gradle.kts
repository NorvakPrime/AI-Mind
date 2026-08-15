allprojects {
    repositories {
        google()
        mavenCentral()
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
    afterEvaluate {
        // Fix for missing namespace in older plugins (required by AGP 8+)
        if (project.plugins.hasPlugin("com.android.library")) {
            val extension = project.extensions.getByType<com.android.build.gradle.LibraryExtension>()
            if (extension.namespace == null) {
                // Generate a safe namespace based on plugin name
                val name = project.name.replace("-", "_").replace(".", "_")
                extension.namespace = "com.norvak.generated_namespace.$name"
            }
            
            // Fix for deprecated proguard-android.txt
            extension.buildTypes.all {
                val files = proguardFiles
                if (files.any { it is File && it.name == "proguard-android.txt" }) {
                    val filtered = files.filter { it is File && it.name != "proguard-android.txt" }
                    setProguardFiles(filtered)
                    proguardFile(extension.getDefaultProguardFile("proguard-android-optimize.txt"))
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
