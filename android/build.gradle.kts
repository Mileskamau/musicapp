import javax.xml.parsers.DocumentBuilderFactory

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

fun manifestPackageName(manifestFile: File): String? {
    if (!manifestFile.exists()) {
        return null
    }

    val documentBuilder = DocumentBuilderFactory.newInstance().apply {
        isNamespaceAware = false
    }.newDocumentBuilder()

    val manifest = manifestFile.inputStream().use { stream ->
        documentBuilder.parse(stream)
    }.documentElement

    return manifest.getAttribute("package").takeIf { it.isNotBlank() }
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
    plugins.withId("com.android.library") {
        val androidExtension = extensions.findByName("android") ?: return@withId
        val getNamespace = androidExtension.javaClass.methods.firstOrNull {
            it.name == "getNamespace" && it.parameterCount == 0
        } ?: return@withId
        val currentNamespace = getNamespace.invoke(androidExtension) as? String

        if (!currentNamespace.isNullOrBlank()) {
            return@withId
        }

        val manifestPackage = manifestPackageName(file("src/main/AndroidManifest.xml"))
            ?: return@withId
        val setNamespace = androidExtension.javaClass.methods.firstOrNull {
            it.name == "setNamespace" && it.parameterCount == 1
        } ?: return@withId

        setNamespace.invoke(androidExtension, manifestPackage)
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

allprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
