import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "io.github.sachin102492.core"
    compileSdk = 36

    defaultConfig {
        minSdk = 26
    }

    buildFeatures {
        compose = true
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
    val composeBom = platform("androidx.compose:compose-bom:2025.06.00")
    api(composeBom)
    api("androidx.core:core-ktx:1.16.0")
    api("androidx.activity:activity-compose:1.10.1")
    api("androidx.compose.ui:ui")
    api("androidx.compose.foundation:foundation")
    api("androidx.compose.material3:material3")
    api("androidx.compose.material:material-icons-core")
    api("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    // Same ad SDK versions as FloatNote.
    api("com.google.android.gms:play-services-ads:23.6.0")
    api("com.google.android.ump:user-messaging-platform:3.1.0")
}
