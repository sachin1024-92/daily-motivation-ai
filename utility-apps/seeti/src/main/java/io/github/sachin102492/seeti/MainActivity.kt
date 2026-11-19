@file:OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)

package io.github.sachin102492.seeti

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import io.github.sachin102492.core.AboutScreen
import io.github.sachin102492.core.AdsConsent
import io.github.sachin102492.core.AppScaffold
import io.github.sachin102492.core.UtilityTheme
import kotlinx.coroutines.delay

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        AdsConsent.gather(this)
        setContent {
            UtilityTheme(seed = Color(0xFFD84315)) { SeetiApp() }
        }
    }
}

@Composable
fun SeetiApp() {
    val session by SeetiState.session.collectAsState()
    var showAbout by rememberSaveable { mutableStateOf(false) }
    when {
        showAbout -> AboutScreen(
            appName = "Seeti – Cooker Whistle Counter",
            versionName = BuildConfig.VERSION_NAME,
            about = "Seeti listens for your pressure cooker's whistles, counts them, and rings an " +
                "alarm when your dish is done, so you don't have to stand in the kitchen counting.",
            privacy = listOf(
                "The microphone is used only while you are counting, and stops when you tap Stop or the count is reached.",
                "Sound is analysed on your phone, a fraction of a second at a time. Nothing is recorded, saved or uploaded.",
                "Your settings stay on this phone.",
            ),
            onBack = { showAbout = false },
        )
        session.running || session.alarm != null -> ListeningScreen(session)
        else -> SetupScreen(error = session.error, onAbout = { showAbout = true })
    }
}

private fun hasPermission(context: Context, permission: String) =
    ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED

@Composable
private fun SetupScreen(error: String?, onAbout: () -> Unit) {
    val context = LocalContext.current
    val prefs = remember { SeetiPrefs(context) }
    var target by rememberSaveable { mutableIntStateOf(prefs.target) }
    var sensitivity by rememberSaveable { mutableStateOf(prefs.sensitivity) }
    var safety by rememberSaveable { mutableIntStateOf(prefs.safetyMinutes) }
    var showDisclosure by remember { mutableStateOf(false) }

    val startListening: () -> Unit = {
        prefs.target = target
        prefs.sensitivity = sensitivity
        prefs.safetyMinutes = safety
        ListenService.start(context, target, sensitivity, safety)
    }
    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {
        if (hasPermission(context, Manifest.permission.RECORD_AUDIO)) {
            startListening()
        } else {
            Toast.makeText(context, "Seeti needs the microphone to hear the whistles.", Toast.LENGTH_LONG).show()
        }
    }
    val requestAndStart: () -> Unit = {
        val needed = buildList {
            add(Manifest.permission.RECORD_AUDIO)
            if (Build.VERSION.SDK_INT >= 33) add(Manifest.permission.POST_NOTIFICATIONS)
        }.filterNot { hasPermission(context, it) }
        if (needed.isEmpty()) startListening() else permissionLauncher.launch(needed.toTypedArray())
    }

    AppScaffold(
        title = "Seeti",
        bannerId = BuildConfig.BANNER_ID,
        actions = {
            IconButton(onClick = onAbout) { Icon(Icons.Default.Info, contentDescription = "About Seeti") }
        },
    ) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text("Cooker whistle counter", style = MaterialTheme.typography.titleMedium)
            if (error != null) {
                Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)) {
                    Text(error, Modifier.padding(16.dp), color = MaterialTheme.colorScheme.onErrorContainer)
                }
            }

            Text("How many whistles?", style = MaterialTheme.typography.titleLarge)
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                FilledIconButton(onClick = { if (target > 1) target-- }, modifier = Modifier.size(56.dp)) {
                    Text("−", fontSize = 28.sp)
                }
                Text(
                    "$target",
                    fontSize = 72.sp,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = 32.dp),
                )
                FilledIconButton(onClick = { if (target < 20) target++ }, modifier = Modifier.size(56.dp)) {
                    Icon(Icons.Default.Add, contentDescription = "One more whistle")
                }
            }
            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                presets.forEach { p ->
                    FilterChip(
                        selected = target == p.whistles,
                        onClick = { target = p.whistles },
                        label = { Text("${p.name} ${p.whistles}") },
                    )
                }
            }

            Text("Sensitivity", style = MaterialTheme.typography.titleMedium)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Sensitivity.entries.forEach { s ->
                    FilterChip(selected = sensitivity == s, onClick = { sensitivity = s }, label = { Text(s.label) })
                }
            }
            Text(
                "Use High if the phone is in another room, Low if the kitchen is noisy.",
                style = MaterialTheme.typography.bodySmall,
            )

            Text("Safety alarm", style = MaterialTheme.typography.titleMedium)
            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf(0, 15, 20, 30, 45).forEach { m ->
                    FilterChip(
                        selected = safety == m,
                        onClick = { safety = m },
                        label = { Text(if (m == 0) "Off" else "$m min") },
                    )
                }
            }
            Text(
                "Rings after this time even if a whistle was missed, so the cooker is never forgotten.",
                style = MaterialTheme.typography.bodySmall,
            )

            Button(
                onClick = { if (prefs.disclosureAccepted) requestAndStart() else showDisclosure = true },
                modifier = Modifier.fillMaxWidth().height(60.dp),
            ) {
                Text("Start counting", fontSize = 20.sp)
            }
            Text(
                "Keep the phone within 3–4 metres of the cooker. The screen can be off; Seeti keeps counting.",
                style = MaterialTheme.typography.bodySmall,
            )
        }
    }

    if (showDisclosure) {
        AlertDialog(
            onDismissRequest = { showDisclosure = false },
            title = { Text("Seeti uses the microphone") },
            text = {
                Text(
                    "To hear whistles, Seeti listens through the microphone only while you are counting. " +
                        "Sound is checked on your phone and is never recorded, saved or sent anywhere. " +
                        "Listening stops when you tap Stop or the count is reached.",
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    showDisclosure = false
                    prefs.disclosureAccepted = true
                    requestAndStart()
                }) { Text("Continue") }
            },
            dismissButton = { TextButton(onClick = { showDisclosure = false }) { Text("Not now") } },
        )
    }
}

@Composable
private fun ListeningScreen(s: Session) {
    val context = LocalContext.current
    // No ads on this screen: it is used with wet hands and must not invite accidental taps.
    Scaffold { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp, Alignment.CenterVertically),
        ) {
            val alarm = s.alarm
            if (alarm != null) {
                Text(
                    if (alarm == AlarmReason.TARGET_REACHED) "${s.count} whistles done!" else "Safety timer",
                    style = MaterialTheme.typography.displaySmall,
                    textAlign = TextAlign.Center,
                )
                Text(
                    if (alarm == AlarmReason.TARGET_REACHED) "Turn off the gas." else "Check the cooker now.",
                    style = MaterialTheme.typography.headlineSmall,
                    textAlign = TextAlign.Center,
                )
                Button(
                    onClick = { ListenService.stop(context) },
                    modifier = Modifier.fillMaxWidth().height(72.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error),
                ) { Text("Stop alarm", fontSize = 22.sp) }
            } else {
                Text("Listening for whistles", style = MaterialTheme.typography.titleLarge)
                Text("${s.count} / ${s.target}", fontSize = 88.sp, fontWeight = FontWeight.Bold)
                val level = ((s.levelDb + 70f) / 70f).coerceIn(0f, 1f)
                LinearProgressIndicator(
                    progress = { level },
                    modifier = Modifier.fillMaxWidth().height(10.dp),
                    color = if (s.hearing) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline,
                )
                Text(
                    if (s.hearing) "Hearing a whistle…" else "Sound level",
                    style = MaterialTheme.typography.bodyMedium,
                )
                Elapsed(s.startedAtMillis, s.safetyMinutes)
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    OutlinedButton(onClick = { SeetiState.adjustCount(-1) }) { Text("−1 wrong count") }
                    OutlinedButton(onClick = { SeetiState.adjustCount(1) }) { Text("+1 missed one") }
                }
                Button(onClick = { ListenService.stop(context) }, modifier = Modifier.fillMaxWidth().height(56.dp)) {
                    Text("Stop")
                }
                Text(
                    "You can lock the phone. Seeti will ring when the count is reached.",
                    style = MaterialTheme.typography.bodySmall,
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
}

@Composable
private fun Elapsed(startedAt: Long, safetyMinutes: Int) {
    var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
    LaunchedEffect(startedAt) {
        while (true) {
            delay(1_000)
            now = System.currentTimeMillis()
        }
    }
    val seconds = ((now - startedAt) / 1000).coerceAtLeast(0)
    val text = "%d:%02d cooking".format(seconds / 60, seconds % 60) +
        if (safetyMinutes > 0) " · safety alarm at $safetyMinutes min" else ""
    Text(text, style = MaterialTheme.typography.bodyMedium)
}
