package io.github.sachin102492.core

import android.app.Activity
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdSize
import com.google.android.gms.ads.AdView
import com.google.android.gms.ads.MobileAds
import com.google.android.ump.ConsentInformation
import com.google.android.ump.ConsentRequestParameters
import com.google.android.ump.UserMessagingPlatform
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Consent first, ads second (Google's User Messaging Platform, required in the EEA/UK and
 * some US states). The ad SDK is only started once consent allows it, and banners stay hidden
 * until then. This mirrors FloatNote's working setup.
 */
object AdsConsent {
    private val canRequest = MutableStateFlow(false)
    val canRequestAds: StateFlow<Boolean> = canRequest.asStateFlow()

    private val privacyRequired = MutableStateFlow(false)
    val privacyOptionsRequired: StateFlow<Boolean> = privacyRequired.asStateFlow()

    private val sdkStarted = AtomicBoolean(false)
    private val asked = AtomicBoolean(false)

    /** Call from the launcher activity's onCreate. Safe to call more than once. */
    fun gather(activity: Activity) {
        val info = UserMessagingPlatform.getConsentInformation(activity)
        // Consent given in an earlier session lets ads start immediately.
        refresh(activity, info)
        if (!asked.compareAndSet(false, true)) return
        info.requestConsentInfoUpdate(
            activity,
            ConsentRequestParameters.Builder().build(),
            {
                UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity) {
                    refresh(activity, info)
                }
            },
            {
                // Consent service unreachable: fall back to whatever was decided last time.
                refresh(activity, info)
            },
        )
    }

    fun showPrivacyOptions(activity: Activity) {
        UserMessagingPlatform.showPrivacyOptionsForm(activity) {
            refresh(activity, UserMessagingPlatform.getConsentInformation(activity))
        }
    }

    private fun refresh(activity: Activity, info: ConsentInformation) {
        privacyRequired.value = info.privacyOptionsRequirementStatus ==
            ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED
        if (info.canRequestAds()) {
            if (sdkStarted.compareAndSet(false, true)) {
                MobileAds.initialize(activity.applicationContext) {}
            }
            canRequest.value = true
        }
    }
}

/**
 * One anchored adaptive banner. Shown only after consent allows ads. Each app places it at the
 * bottom of its main screen, away from buttons, and never on alarm, editing or camera screens.
 */
@Composable
fun BannerAd(adUnitId: String, modifier: Modifier = Modifier) {
    val allowed by AdsConsent.canRequestAds.collectAsState()
    if (!allowed) return
    val context = LocalContext.current
    val widthDp = LocalConfiguration.current.screenWidthDp
    val adView = remember(adUnitId, widthDp) {
        AdView(context).apply {
            this.adUnitId = adUnitId
            setAdSize(AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(context, widthDp))
            loadAd(AdRequest.Builder().build())
        }
    }
    DisposableEffect(adView) {
        onDispose { adView.destroy() }
    }
    AndroidView(factory = { adView }, modifier = modifier.fillMaxWidth())
}
