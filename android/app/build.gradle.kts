import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader().use { reader ->
        localProperties.load(reader)
    }
}

val flutterRoot: String = localProperties.getProperty("flutter.sdk")
    ?: throw GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"

val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}


repositories {
    flatDir {
        dirs("../libs")
    }
}

android {
    namespace = "com.enigma.zmall"
    ndkVersion = "29.0.14206865" //"29.0.13113456 rc1"
    compileSdk = 36
    // ndkVersion = "29.0.13113456"  
    // flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    lint {
        checkReleaseBuilds = false
    }

    // Force Java 17 for all tasks
    tasks.withType<JavaCompile> {
        options.compilerArgs.addAll(listOf("-source", "17", "-target", "17"))
    }


    //for deployment to play store
    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.zmall.user"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { path -> file(path) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
    ////////////For teleBirr InApp SDK path///////////
    dependencies {
        implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.jar", "*.aar"))))
       
        // Alternative: Direct file reference (use when AAR is available)
        implementation(files("../libs/EthiopiaPaySdkModule-prod-release.aar"))
        // implementation(files("libs/EthiopiaPaySdkModule-uat-release.aar"))
        ////For future implementation of both production and uat support
        // Production SDK for release builds
        // "releaseImplementation"(files("libs/EthiopiaPaySdkModule-prod-release.aar"))

        // UAT SDK for debug builds
        // "debugImplementation"(files("libs/EthiopiaPaySdkModule-uat-release.aar"))
        // implementation(files("libs/EthiopiaPaySdkModule-uat-release.aar"))
    }

    ///////////////////////////////////////////


}

flutter {
    source = "../.."
}

dependencies {
    // implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.jar", "*.aar"))))
    implementation(platform("com.google.firebase:firebase-bom:33.10.0"))
    implementation("com.google.firebase:firebase-analytics")
}
