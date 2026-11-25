import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.zelvira.ecommerce"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.zelvira.ecommerce"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 🔥 FIX APPAUTH REDIRECT SCHEME (KOTLIN DSL)
        manifestPlaceholders["appAuthRedirectScheme"] = "com.zelvira.ecommerce"
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { path ->
                val f = file(path)
                if (f.exists()) f else if (file("zelvira.jks").exists()) file("zelvira.jks") else rootProject.file("../keys/zelvira.jks")
            }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

configurations.all {
    resolutionStrategy {
        eachDependency {
            if (requested.group == "com.midtrans" && requested.name == "uikit") {
                useTarget("com.midtrans:uikit:2.5.0")
            }
        }
    }
}

flutter {
    source = "../.."
}