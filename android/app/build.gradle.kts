import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// =============================================================================
// Signing config: lê credenciais de `android/key.properties` SE existir.
// Esse arquivo NÃO deve ir pro git (ver .gitignore).
// Estrutura esperada:
//   storeFile=/caminho/para/serviceflow-release.jks
//   storePassword=...
//   keyAlias=serviceflow
//   keyPassword=...
// Se ausente, a build de release cai pro signing de DEBUG (apenas para
// `flutter run --release` em dev). Em produção/Play Store o arquivo
// é OBRIGATÓRIO.
// =============================================================================
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.serviceflow.serviceflow"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.serviceflow.serviceflow"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Reduz APK final ao limpar resources de idioma/densidade não usados.
        resourceConfigurations.addAll(listOf("en", "pt", "pt-rBR"))
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                enableV1Signing = true
                enableV2Signing = true
                enableV3Signing = true
                enableV4Signing = true
            }
        }
    }

    buildTypes {
        release {
            // Assinatura: usa keystore de release se houver `key.properties`,
            // senão cai pro debug (somente para `flutter run --release` local).
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // R8 + shrinkResources: reduz tamanho do APK e remove código morto.
            // Combinado com obfuscação do Dart (build com --obfuscate
            // --split-debug-info), torna a engenharia reversa impraticável.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            isDebuggable = false
            isJniDebuggable = false
        }

        debug {
            applicationIdSuffix = ".debug"
            isMinifyEnabled = false
        }
    }

    packaging {
        resources {
            excludes += listOf(
                "META-INF/AL2.0",
                "META-INF/LGPL2.1",
                "META-INF/*.kotlin_module"
            )
        }
    }
}

flutter {
    source = "../.."
}
