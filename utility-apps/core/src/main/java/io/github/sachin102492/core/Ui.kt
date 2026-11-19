package io.github.sachin102492.core

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun UtilityTheme(seed: Color, content: @Composable () -> Unit) {
    val scheme = if (isSystemInDarkTheme()) {
        val light = seed.lighten(0.45f)
        darkColorScheme(primary = light, secondary = light, tertiary = light)
    } else {
        lightColorScheme(primary = seed, secondary = seed, tertiary = seed)
    }
    MaterialTheme(colorScheme = scheme, content = content)
}

private fun Color.lighten(f: Float) = Color(
    red = red + (1f - red) * f,
    green = green + (1f - green) * f,
    blue = blue + (1f - blue) * f,
    alpha = 1f,
)

/** Top bar, content, and an optional banner pinned to the bottom edge. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppScaffold(
    title: String,
    bannerId: String?,
    onBack: (() -> Unit)? = null,
    actions: @Composable RowScope.() -> Unit = {},
    floatingActionButton: @Composable () -> Unit = {},
    content: @Composable (PaddingValues) -> Unit,
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(title, maxLines = 1, overflow = TextOverflow.Ellipsis) },
                navigationIcon = {
                    if (onBack != null) {
                        IconButton(onClick = onBack) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                        }
                    }
                },
                actions = actions,
            )
        },
        bottomBar = {
            Column(Modifier.fillMaxWidth().navigationBarsPadding()) {
                if (bannerId != null) BannerAd(bannerId)
            }
        },
        floatingActionButton = floatingActionButton,
        content = content,
    )
}

/** Shared About screen: what the app does, its privacy promises, and the ad privacy choices. */
@Composable
fun AboutScreen(
    appName: String,
    versionName: String,
    about: String,
    privacy: List<String>,
    onBack: () -> Unit,
) {
    BackHandler(onBack = onBack)
    val context = LocalContext.current
    val privacyRequired by AdsConsent.privacyOptionsRequired.collectAsState()
    AppScaffold(title = "About", bannerId = null, onBack = onBack) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(appName, style = MaterialTheme.typography.headlineSmall)
            Text("Version $versionName", style = MaterialTheme.typography.bodySmall)
            Text(about, style = MaterialTheme.typography.bodyLarge)
            Spacer(Modifier.height(4.dp))
            Text("Your privacy", style = MaterialTheme.typography.titleMedium)
            privacy.forEach { Text("• $it", style = MaterialTheme.typography.bodyMedium) }
            Text(
                "• Ads are served by Google AdMob, which may use your device's advertising ID. " +
                    "You can reset or delete it in your phone's Settings > Google > Ads.",
                style = MaterialTheme.typography.bodyMedium,
            )
            val activity = context.findActivity()
            if (privacyRequired && activity != null) {
                OutlinedButton(onClick = { AdsConsent.showPrivacyOptions(activity) }) {
                    Text("Ad privacy choices")
                }
            }
            Spacer(Modifier.height(8.dp))
            Text(
                "Made in India. Not affiliated with any government body or company named in the app.",
                style = MaterialTheme.typography.bodySmall,
            )
        }
    }
}

fun Context.findActivity(): Activity? {
    var c: Context? = this
    while (c is ContextWrapper) {
        if (c is Activity) return c
        c = c.baseContext
    }
    return null
}

private val dayFormat: DateTimeFormatter = DateTimeFormatter.ofPattern("d MMM yyyy", Locale.ENGLISH)

fun today(): Long = LocalDate.now().toEpochDay()

fun formatDay(epochDay: Long): String = LocalDate.ofEpochDay(epochDay).format(dayFormat)

fun rupees(amount: Double): String = "₹" + String.format(Locale.ENGLISH, "%,.0f", amount)

/** Indian mobile numbers: keep digits, add the 91 country code to 10-digit numbers. */
fun normalisePhone(raw: String): String {
    val digits = raw.filter { it.isDigit() }.trimStart('0')
    return if (digits.length == 10) "91$digits" else digits
}

fun openWhatsApp(context: Context, phone: String, text: String = "") {
    val number = normalisePhone(phone)
    val uri = Uri.parse("https://wa.me/$number" + if (text.isNotEmpty()) "?text=" + Uri.encode(text) else "")
    context.startActivity(Intent(Intent.ACTION_VIEW, uri).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
}

fun dial(context: Context, phone: String) {
    context.startActivity(
        Intent(Intent.ACTION_DIAL, Uri.parse("tel:" + phone.filter { it.isDigit() || it == '+' }))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
    )
}

/** Platform date picker (no extra library); returns the chosen day as an epoch day. */
fun pickDate(context: Context, initialEpochDay: Long, maxEpochDay: Long? = today(), onPicked: (Long) -> Unit) {
    val d = LocalDate.ofEpochDay(initialEpochDay)
    val dialog = android.app.DatePickerDialog(
        context,
        { _, year, month, day -> onPicked(LocalDate.of(year, month + 1, day).toEpochDay()) },
        d.year,
        d.monthValue - 1,
        d.dayOfMonth,
    )
    if (maxEpochDay != null) {
        dialog.datePicker.maxDate = LocalDate.ofEpochDay(maxEpochDay)
            .atStartOfDay(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli() + 86_399_000L
    }
    dialog.show()
}

fun shareText(context: Context, text: String, title: String = "Share") {
    val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
    context.startActivity(Intent.createChooser(send, title).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
}
