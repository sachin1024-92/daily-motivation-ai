@file:OptIn(ExperimentalMaterial3Api::class)

package io.github.sachin102492.gharclock

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import io.github.sachin102492.core.AboutScreen
import io.github.sachin102492.core.AdsConsent
import io.github.sachin102492.core.AppScaffold
import io.github.sachin102492.core.UtilityTheme
import io.github.sachin102492.core.dial
import io.github.sachin102492.core.formatDay
import io.github.sachin102492.core.openWhatsApp
import io.github.sachin102492.core.pickDate
import io.github.sachin102492.core.today

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val store = GharStore(this)
        if (BuildConfig.DEBUG && intent.getBooleanExtra("seed_demo", false)) GharModel.seedDemo(store, today())
        val model = GharModel(store)
        ReminderWorker.schedule(this)
        AdsConsent.gather(this)
        setContent {
            UtilityTheme(seed = Color(0xFF6A1B9A)) { GharApp(model) }
        }
    }
}

@Composable
fun GharApp(model: GharModel) {
    var showAbout by rememberSaveable { mutableStateOf(false) }
    var editingId by rememberSaveable { mutableStateOf<String?>(null) }
    var addingCustom by rememberSaveable { mutableStateOf(false) }
    var choosingPresets by rememberSaveable { mutableStateOf(false) }
    val context = LocalContext.current

    // Ask once for permission to post reminders (Android 13+).
    val notifLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {}
    LaunchedEffect(Unit) {
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            notifLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    val editing = model.items.firstOrNull { it.id == editingId }
    when {
        showAbout -> AboutScreen(
            appName = "Ghar Clock",
            versionName = BuildConfig.VERSION_NAME,
            about = "Ghar Clock remembers when your home things are due: it learns how long your LPG cylinder " +
                "lasts from your own refill dates and reminds you to book before it runs out, and keeps track of " +
                "RO, AC, inverter, chimney, water-tank and other servicing.",
            privacy = listOf(
                "Your items, dates and service numbers are stored only on this phone.",
                "Reminders are worked out on the phone; nothing is uploaded.",
            ),
            onBack = { showAbout = false },
        )
        !model.onboarded || choosingPresets -> PresetScreen(
            existing = model.items.map { it.name }.toSet(),
            firstRun = !model.onboarded,
            onDone = { model.addPresets(it); choosingPresets = false },
            onBack = { choosingPresets = false },
        )
        editing != null || addingCustom -> EditScreen(
            item = editing,
            onSave = { model.upsert(it); editingId = null; addingCustom = false },
            onDelete = { id -> model.delete(id); editingId = null },
            onRemoveDate = { day -> editing?.let { model.removeDate(it.id, day) } },
            onBack = { editingId = null; addingCustom = false },
        )
        else -> HomeScreen(
            model = model,
            onEdit = { editingId = it },
            onAddPreset = { choosingPresets = true },
            onAddCustom = { addingCustom = true },
            onAbout = { showAbout = true },
        )
    }
}

@Composable
private fun HomeScreen(
    model: GharModel,
    onEdit: (String) -> Unit,
    onAddPreset: () -> Unit,
    onAddCustom: () -> Unit,
    onAbout: () -> Unit,
) {
    val context = LocalContext.current
    val day = today()
    var showAddMenu by remember { mutableStateOf(false) }
    AppScaffold(
        title = "Ghar Clock",
        bannerId = BuildConfig.BANNER_ID,
        actions = { IconButton(onClick = onAbout) { Icon(Icons.Default.Info, contentDescription = "About Ghar Clock") } },
        floatingActionButton = {
            FloatingActionButton(onClick = { showAddMenu = true }) { Icon(Icons.Default.Add, contentDescription = "Add item") }
        },
    ) { padding ->
        LazyColumn(
            Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 96.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            if (model.items.isEmpty()) item { Text("Nothing to track yet. Tap + to add things.") }
            items(Schedule.sorted(model.items, day), key = { it.id }) { item ->
                ItemCard(
                    item = item,
                    today = day,
                    onDoneToday = { model.markDone(item.id, day) },
                    onDoneOn = { pickDate(context, day) { d -> model.markDone(item.id, d) } },
                    onOpen = { onEdit(item.id) },
                )
            }
        }
    }
    if (showAddMenu) {
        AlertDialog(
            onDismissRequest = { showAddMenu = false },
            title = { Text("Add") },
            text = { Text("Pick from common household items, or add your own.") },
            confirmButton = { TextButton(onClick = { showAddMenu = false; onAddPreset() }) { Text("Common items") } },
            dismissButton = { TextButton(onClick = { showAddMenu = false; onAddCustom() }) { Text("My own") } },
        )
    }
}

@Composable
private fun ItemCard(item: HomeItem, today: Long, onDoneToday: () -> Unit, onDoneOn: () -> Unit, onOpen: () -> Unit) {
    val context = LocalContext.current
    val due = Schedule.due(item, today)
    fun days(n: Long) = if (n == 1L) "1 day" else "$n days"
    val (status, color) = when (due.state) {
        DueState.OVERDUE -> "Overdue by ${days(-(due.daysLeft ?: 0))}" to MaterialTheme.colorScheme.errorContainer
        DueState.DUE_SOON -> (if (due.daysLeft == 0L) "Due today" else "Due in ${days(due.daysLeft ?: 0)} (${formatDay(due.nextEpochDay ?: today)})") to
            MaterialTheme.colorScheme.tertiaryContainer
        DueState.OK -> "Next: ${formatDay(due.nextEpochDay ?: today)} · in ${days(due.daysLeft ?: 0)}" to MaterialTheme.colorScheme.surfaceVariant
        DueState.NOT_STARTED -> "Tap \"Other date\" and enter when it was last done" to MaterialTheme.colorScheme.surfaceVariant
    }
    val learned = Schedule.learnedInterval(item)
    val rhythm = when {
        learned != null -> "Lasts about $learned days (learned from ${item.history.size} refills)"
        item.learns -> "Assuming ${item.intervalDays} days until you've logged 2 refills"
        else -> "Every ${item.intervalDays} days"
    }
    Card(
        Modifier.fillMaxWidth().clickable(onClick = onOpen),
        colors = CardDefaults.cardColors(containerColor = color),
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(item.name, style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
                if (item.contact.isNotBlank()) {
                    IconButton(onClick = { dial(context, item.contact) }) { Icon(Icons.Default.Call, contentDescription = "Call") }
                    TextButton(onClick = { openWhatsApp(context, item.contact, "Hello, I need to book: ${item.name}.") }) {
                        Text("WhatsApp")
                    }
                }
            }
            Text(status, fontWeight = FontWeight.SemiBold)
            Text(rhythm, style = MaterialTheme.typography.bodySmall)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(onClick = onDoneToday) { Text(if (item.learns) "Refilled today" else "Done today") }
                OutlinedButton(onClick = onDoneOn) { Text("Other date") }
            }
        }
    }
}

@Composable
private fun PresetScreen(existing: Set<String>, firstRun: Boolean, onDone: (List<Preset>) -> Unit, onBack: () -> Unit) {
    if (!firstRun) BackHandler(onBack = onBack)
    val available = presets.filter { it.name !in existing }
    val chosen = remember { mutableStateListOf<Preset>().apply { if (firstRun) addAll(available.filter { it.defaultOn }) } }
    AppScaffold(title = if (firstRun) "Welcome to Ghar Clock" else "Add common items", bannerId = null, onBack = if (firstRun) null else onBack) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            LazyColumn(Modifier.weight(1f), contentPadding = PaddingValues(16.dp)) {
                item {
                    Text(
                        "What should Ghar Clock remember for you? You can change intervals later.",
                        style = MaterialTheme.typography.bodyLarge,
                        modifier = Modifier.padding(bottom = 8.dp),
                    )
                }
                items(available, key = { it.name }) { p ->
                    Row(
                        Modifier.fillMaxWidth().clickable { if (p in chosen) chosen.remove(p) else chosen.add(p) },
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Checkbox(checked = p in chosen, onCheckedChange = { if (it) chosen.add(p) else chosen.remove(p) })
                        Column {
                            Text(p.name)
                            Text(
                                if (p.learns) "Learns from your refill dates" else "Every ${p.intervalDays} days",
                                style = MaterialTheme.typography.bodySmall,
                            )
                        }
                    }
                }
            }
            Button(
                onClick = { onDone(chosen.toList()) },
                modifier = Modifier.fillMaxWidth().padding(16.dp),
            ) { Text(if (chosen.isEmpty()) "Skip" else "Add ${chosen.size} items") }
        }
    }
}

@Composable
private fun EditScreen(
    item: HomeItem?,
    onSave: (HomeItem) -> Unit,
    onDelete: (String) -> Unit,
    onRemoveDate: (Long) -> Unit,
    onBack: () -> Unit,
) {
    BackHandler(onBack = onBack)
    var name by remember(item?.id) { mutableStateOf(item?.name ?: "") }
    var interval by remember(item?.id) { mutableStateOf((item?.intervalDays ?: 30).toString()) }
    var remind by remember(item?.id) { mutableStateOf((item?.remindBefore ?: 3).toString()) }
    var contact by remember(item?.id) { mutableStateOf(item?.contact ?: "") }
    var learns by remember(item?.id) { mutableStateOf(item?.learns ?: false) }
    var error by remember { mutableStateOf<String?>(null) }
    val number = KeyboardOptions(keyboardType = KeyboardType.Number)

    AppScaffold(title = if (item == null) "New item" else item.name, bannerId = null, onBack = onBack) { padding ->
        Column(
            Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            OutlinedTextField(name, { name = it.take(40) }, label = { Text("Name") }, singleLine = true, modifier = Modifier.fillMaxWidth())
            OutlinedTextField(
                interval, { interval = it.filter(Char::isDigit) }, label = { Text("Repeat every (days)") },
                singleLine = true, keyboardOptions = number, modifier = Modifier.fillMaxWidth(),
            )
            OutlinedTextField(
                remind, { remind = it.filter(Char::isDigit) }, label = { Text("Remind me this many days before") },
                singleLine = true, keyboardOptions = number, modifier = Modifier.fillMaxWidth(),
            )
            OutlinedTextField(
                contact, { contact = it }, label = { Text("Service / booking number (optional)") },
                singleLine = true, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone), modifier = Modifier.fillMaxWidth(),
            )
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text("Learn from my dates")
                    Text("For refills like LPG: uses the average gap between your last refills.", style = MaterialTheme.typography.bodySmall)
                }
                Switch(checked = learns, onCheckedChange = { learns = it })
            }
            error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
            Button(onClick = {
                val i = interval.toIntOrNull()
                val r = remind.toIntOrNull()
                error = when {
                    name.isBlank() -> "Enter a name."
                    i == null || i !in 1..3650 -> "Repeat every 1 to 3650 days."
                    r == null || r < 0 || r >= i -> "Reminder days must be less than the repeat interval."
                    else -> null
                }
                if (error == null && i != null && r != null) {
                    onSave(
                        HomeItem(
                            id = item?.id ?: GharModel.newId(),
                            name = name.trim(),
                            learns = learns,
                            intervalDays = i,
                            remindBefore = r,
                            history = item?.history ?: emptyList(),
                            contact = contact.trim(),
                        ),
                    )
                }
            }, modifier = Modifier.fillMaxWidth()) { Text("Save") }

            if (item != null) {
                Text("History", style = MaterialTheme.typography.titleMedium)
                if (item.history.isEmpty()) Text("No dates yet.")
                item.history.sortedDescending().forEach { d ->
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(formatDay(d), Modifier.weight(1f))
                        IconButton(onClick = { onRemoveDate(d) }) { Icon(Icons.Default.Delete, contentDescription = "Remove date") }
                    }
                }
                TextButton(onClick = { onDelete(item.id) }) {
                    Text("Delete this item", color = MaterialTheme.colorScheme.error)
                }
            }
        }
    }
}
