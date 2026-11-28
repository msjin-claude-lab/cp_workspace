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
        // flutter_local_notifications(매일 알림)가 예약에 java.time을 쓴다 — 옛 안드로이드용 desugaring
        isCoreLibraryDesugaringEnabled = true
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
        // AdMob 앱 ID(AndroidManifest의 com.google.android.gms.ads.APPLICATION_ID). debug·profile은 Google 공식 테스트 앱 ID,
        // release만 아래 buildTypes.release에서 실제 ID로 바꾼다(2026-11-29 사용자 결정). 광고 단위 ID는 lib/features/ads/ad_ids.dart
        manifestPlaceholders["admobAppId"] = "ca-app-pub-3940256099942544~3347511713"
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
            // 실제 AdMob 앱 ID — 저장소에서 이 한 곳에만 적는다. release를 기기에 깔았을 때 광고를 누르지 않는다(부정 클릭)
            manifestPlaceholders["admobAppId"] = "ca-app-pub-5860744543403858~5527092484"
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
