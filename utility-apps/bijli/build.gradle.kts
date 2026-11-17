import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

// ---- AdMob IDs ------------------------------------------------------------------------------
// Debug builds always use Google's published TEST IDs, so testing on your own phone can never
// cause an invalid-traffic strike. Release builds use the real IDs from admob.properties (or the
// environment variables BIJLI_APP_ID / BIJLI_BANNER_ID); without them they fall back to test
// IDs and earn nothing, and the build prints a warning.
val appKey = "bijli"
val admobProps = Properties().apply {
    val f = rootProject.file("admob.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
fun admobValue(name: String): String? =
    (System.getenv("${appKey.uppercase()}_${name.uppercase()}") ?: admobProps.getProperty("$appKey.$name"))
        ?.trim()?.takeIf { it.isNotEmpty() }

val testAppId = "ca-app-pub-3940256099942544~3347511713"
val testBannerId = "ca-app-pub-3940256099942544/9214589741"
val releaseAppId = admobValue("app_id") ?: testAppId
val releaseBannerId = admobValue("banner_id") ?: testBannerId
if (releaseBannerId == testBannerId) {
    logger.warn("WARNING [$appKey]: release build uses Google TEST ad IDs and will earn nothing. Fill admob.properties.")
}

// Upload-key signing comes from the environment (CI secrets); never stored in the repo.
val keystorePath: String? = System.getenv("UPLOAD_KEYSTORE_FILE")?.takeIf { it.isNotBlank() }

android {
    namespace = "io.github.sachin102492.bijli"
    compileSdk = 36

    defaultConfig {
        applicationId = "io.github.sachin102492.bijli"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    signingConfigs {
        if (keystorePath != null) {
            create("release") {
                storeFile = file(keystorePath)
                storePassword = System.getenv("UPLOAD_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("UPLOAD_KEY_ALIAS")
                keyPassword = System.getenv("UPLOAD_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            buildConfigField("String", "BANNER_ID", "\"$releaseBannerId\"")
            manifestPlaceholders["admobAppId"] = releaseAppId
        }
        debug {
            applicationIdSuffix = ".debug"
            buildConfigField("String", "BANNER_ID", "\"$testBannerId\"")
            manifestPlaceholders["admobAppId"] = testAppId
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    lint {
        abortOnError = false
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    implementation(project(":core"))
    testImplementation("junit:junit:4.13.2")
}
