import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin 은 Android/Kotlin 플러그인 뒤에 와야 합니다.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // ✅ MainActivity 의 패키지와 100% 동일해야 합니다.
    namespace = "com.example.korean_writing_app_new"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        // ✅ 앱 ID도 동일해야 합니다.
        applicationId = "com.example.korean_writing_app_new"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // (필요 시) 벡터 드로어블 호환
        vectorDrawables.useSupportLibrary = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // ───────── 서명 설정 (release 키 사용) ─────────
    val keystorePropsFile = file("key.properties")
    val keystoreProps = Properties()

    if (keystorePropsFile.exists()) {
        keystoreProps.load(keystorePropsFile.inputStream())
    }

    signingConfigs {
        // debug 서명은 기본값 사용
        create("release") {
            if (keystorePropsFile.exists()) {
                storeFile = file(keystoreProps["storeFile"] as String)
                storePassword = keystoreProps["storePassword"] as String
                keyAlias = keystoreProps["keyAlias"] as String
                keyPassword = keystoreProps["keyPassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            // 기본 debug 서명 그대로 사용
        }
        release {
            // key.properties 가 있으면 release 키로, 없으면 debug 키로라도 빌드는 되게 처리
            signingConfig = if (keystorePropsFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")

            // 코드 수축/난독화는 일단 끔 (안정성 우선)
            isMinifyEnabled = false
            isShrinkResources = false
            // proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }

    packaging {
        // (충돌 방지 기본값)
        resources.excludes.add("META-INF/*")
    }
}

flutter {
    source = "../.."
}
