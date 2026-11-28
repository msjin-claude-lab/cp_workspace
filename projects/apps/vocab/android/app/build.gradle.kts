import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Play 업로드 키(2026-11-28 사용자 결정): 개인 PC에만 있는 android/key.properties를 읽는다.
// 이 파일이 없는 PC(사내망 PC 등)에서는 release도 디버그 키로 서명된다. key.properties와 *.jks는 git에 넣지 않는다.
val keystorePropertiesFile = rootProject.file("key.properties")
val hasUploadKey = keystorePropertiesFile.exists()
val keystoreProperties = Properties().apply {
    if (hasUploadKey) keystorePropertiesFile.inputStream().use { load(it) }
}
if (hasUploadKey) {
    // 값이 빠지면 Gradle이 알아보기 어려운 오류를 내므로 먼저 막는다(storeFile은 슬래시 / 로 쓴다 — \는 이스케이프로 읽힌다)
    for (key in listOf("storeFile", "keyAlias", "storePassword", "keyPassword")) {
        require(!keystoreProperties.getProperty(key).isNullOrBlank()) { "android/key.properties: $key 값이 비어 있다" }
    }
} else {
    logger.warn("android/key.properties 없음 — release도 디버그 키로 서명된다(Play에 올릴 수 없음)")
}

android {
    namespace = "kr.msjin.vocab"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Play에 올린 뒤에는 바꿀 수 없다(2026-11-28 사용자 결정).
        applicationId = "kr.msjin.vocab"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasUploadKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
