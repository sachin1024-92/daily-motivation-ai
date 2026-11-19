@file:OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)

package io.github.sachin102492.bijli

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.PrimaryTabRow
import androidx.compose.material3.Switch
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
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
import io.github.sachin102492.core.AboutScreen
import io.github.sachin102492.core.AdsConsent
import io.github.sachin102492.core.AppScaffold
import io.github.sachin102492.core.UtilityTheme
import io.github.sachin102492.core.formatDay
import io.github.sachin102492.core.openWhatsApp
import io.github.sachin102492.core.pickDate
import io.github.sachin102492.core.rupees
import io.github.sachin102492.core.shareText
import io.github.sachin102492.core.today
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val store = BijliStore(this)
        if (BuildConfig.DEBUG && intent.getBooleanExtra("seed_demo", false)) {
            BijliModel.seedDemo(store, today())
        }
        val model = BijliModel(store)
        AdsConsent.gather(this)
        setContent {
            UtilityTheme(seed = Color(0xFF1565C0)) { BijliApp(model) }
        }
    }
}

private fun num(v: Double): String =
    if (v == Math.floor(v)) String.format(Locale.ENGLISH, "%.0f", v) else String.format(Locale.ENGLISH, "%.1f", v)

@Composable
fun BijliApp(model: BijliModel) {
    var tab by rememberSaveable { mutableIntStateOf(0) }
    var showAbout by rememberSaveable { mutableStateOf(false) }
    var editingTenant by remember { mutableStateOf<Tenant?>(null) }
    var addingTenant by remember { mutableStateOf(false) }

    if (showAbout) {
        AboutScreen(
            appName = "Bijli Guard – Bill Predictor",
            versionName = BuildConfig.VERSION_NAME,
            about = "Bijli Guard predicts this month's electricity bill from a few meter readings and warns you " +
                "before you cross a costlier slab or lose the Atal Griha Jyoti subsidy (150 units in MP). " +
                "Landlords can work out each tenant's sub-meter bill and send it on WhatsApp.\n\n" +
                "Rates are estimates based on the MPERC tariff for FY 2026-27 as reported publicly. " +
                "Your discom's bill is final. Edit the rates to match your bill.",
            privacy = listOf(
                "Meter readings, rates and tenant details are stored only on this phone.",
                "Nothing is uploaded. Tenant bills are shared only when you tap Share.",
            ),
            onBack = { showAbout = false },
        )
        return
    }

    AppScaffold(
        title = "Bijli Guard",
        bannerId = BuildConfig.BANNER_ID,
        actions = {
            IconButton(onClick = { showAbout = true }) { Icon(Icons.Default.Info, contentDescription = "About Bijli Guard") }
        },
        floatingActionButton = {
            if (tab == 2) {
                FloatingActionButton(onClick = { addingTenant = true }) {
                    Icon(Icons.Default.Add, contentDescription = "Add tenant")
                }
            }
        },
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            PrimaryTabRow(selectedTabIndex = tab) {
                listOf("Month", "Readings", "Tenants", "Rates").forEachIndexed { i, label ->
                    Tab(
                        selected = tab == i,
                        onClick = { tab = i },
                        text = { Text(label, maxLines = 1, style = MaterialTheme.typography.labelMedium) },
                    )
                }
            }
            when (tab) {
                0 -> MonthTab(model)
                1 -> ReadingsTab(model)
                2 -> TenantsTab(model, onEdit = { editingTenant = it })
                else -> RatesTab(model)
            }
        }
    }

    if (addingTenant || editingTenant != null) {
        TenantDialog(
            initial = editingTenant,
            defaultRate = model.defaultTenantRate,
            onDismiss = { addingTenant = false; editingTenant = null },
            onSave = { model.upsertTenant(it); addingTenant = false; editingTenant = null },
        )
    }
}

// ---- This month ----------------------------------------------------------------------------

@Composable
private fun MonthTab(model: BijliModel) {
    var askStart by remember { mutableStateOf(false) }
    var askReading by remember { mutableStateOf(false) }
    val start = model.start
    val projection = model.projection()

    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        if (start == null) {
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Let's set up", style = MaterialTheme.typography.titleLarge)
                    Text("Find the \"current reading\" on your latest electricity bill and the date it was taken.")
                    Button(onClick = { askStart = true }) { Text("Enter last bill's reading") }
                }
            }
        } else {
            Text(
                "Last bill reading: ${num(start.value)} on ${formatDay(start.epochDay)}",
                style = MaterialTheme.typography.bodyMedium,
            )
            if (projection == null) {
                Card(Modifier.fillMaxWidth()) {
                    Text(
                        "Read your meter today and add the number. Add a reading every few days for a better prediction.",
                        Modifier.padding(16.dp),
                    )
                }
            } else {
                AlertCard(projection, model.tariff)
                Card(Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Stat("Used so far", "${num(projection.unitsSoFar)} units in ${projection.daysElapsed} days")
                        Stat("Average", "${String.format(Locale.ENGLISH, "%.1f", projection.perDay)} units a day")
                        Stat("Bill so far (estimate)", rupees(projection.billSoFar.total))
                        HorizontalDivider()
                        Stat("Expected this month", "${num(Math.round(projection.projectedUnits).toDouble())} units")
                        Stat("Expected bill", rupees(projection.projectedBill.total), bold = true)
                        Text(
                            breakdown(projection.projectedBill),
                            style = MaterialTheme.typography.bodySmall,
                        )
                        Text(
                            "${projection.daysLeft} days left in this ${model.cycleDays}-day bill cycle.",
                            style = MaterialTheme.typography.bodySmall,
                        )
                    }
                }
            }
            Button(onClick = { askReading = true }, modifier = Modifier.fillMaxWidth()) { Text("Add today's meter reading") }
            OutlinedButton(onClick = { askStart = true }, modifier = Modifier.fillMaxWidth()) { Text("New bill arrived: start new cycle") }
        }
        Text(
            "Estimates only. Your discom's bill is final. Check the Rates tab against your bill.",
            style = MaterialTheme.typography.bodySmall,
        )
    }

    if (askStart) {
        ReadingDialog(
            title = "Reading on your latest bill",
            initialDay = model.latest?.epochDay ?: today(),
            onDismiss = { askStart = false },
            onSave = { model.beginCycle(it); askStart = false; null },
        )
    }
    if (askReading) {
        ReadingDialog(
            title = "Meter reading",
            initialDay = today(),
            onDismiss = { askReading = false },
            onSave = { r -> model.addReading(r).also { if (it == null) askReading = false } },
        )
    }
}

private fun breakdown(b: Bill): String = buildString {
    append("Energy ${rupees(b.energy)} + surcharge ${rupees(b.surcharge)} + duty ${rupees(b.duty)}")
    if (b.fixed > 0) append(" + fixed ${rupees(b.fixed)}")
    if (b.subsidised) append(" (Atal Griha Jyoti rate applied)")
}

@Composable
private fun Stat(label: String, value: String, bold: Boolean = false) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, style = MaterialTheme.typography.bodyMedium)
        Text(value, style = MaterialTheme.typography.bodyLarge, fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal)
    }
}

@Composable
private fun AlertCard(p: Projection, tariff: Tariff) {
    val alert = p.alert
    val (title, body, danger) = when {
        p.subsidyAlreadyLost -> Triple(
            "Above ${tariff.subsidyLimit} units this month",
            "The Atal Griha Jyoti subsidy won't apply to this bill. Saving units now still lowers the bill.",
            true,
        )
        alert != null && alert.isSubsidyLimit -> Triple(
            "You may lose the subsidy around ${formatDay(alert.crossOnEpochDay)}",
            "At this rate you'll cross ${alert.threshold} units, which could add about ${rupees(alert.extraCost)}. " +
                "Use at most ${String.format(Locale.ENGLISH, "%.1f", alert.safePerDay)} units a day for the next " +
                "${p.daysLeft} days to stay under.",
            true,
        )
        alert != null -> {
            val nextRate = tariff.slabs.firstOrNull { (it.upTo ?: Int.MAX_VALUE) > alert.threshold }?.rate
            Triple(
                "Costlier slab from about ${formatDay(alert.crossOnEpochDay)}",
                "Units above ${alert.threshold} cost ₹${nextRate ?: "more"} each. Staying under " +
                    "${String.format(Locale.ENGLISH, "%.1f", alert.safePerDay)} units a day avoids it.",
                false,
            )
        }
        else -> Triple("On track", "No slab change expected this month.", false)
    }
    Card(
        Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = if (danger) MaterialTheme.colorScheme.errorContainer else MaterialTheme.colorScheme.secondaryContainer,
        ),
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(title, style = MaterialTheme.typography.titleMedium)
            Text(body, style = MaterialTheme.typography.bodyMedium)
        }
    }
}

/** Value + date entry. [onSave] returns an error message to show, or null to close. */
@Composable
private fun ReadingDialog(title: String, initialDay: Long, onDismiss: () -> Unit, onSave: (Reading) -> String?) {
    val context = LocalContext.current
    var value by remember { mutableStateOf("") }
    var day by remember { mutableLongStateOf(initialDay) }
    var error by remember { mutableStateOf<String?>(null) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = value,
                    onValueChange = { value = it.filter { c -> c.isDigit() || c == '.' }; error = null },
                    label = { Text("kWh reading") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                )
                OutlinedButton(onClick = { pickDate(context, day) { day = it } }) {
                    Icon(Icons.Default.DateRange, contentDescription = null)
                    Spacer(Modifier.padding(4.dp))
                    Text(formatDay(day))
                }
                error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
            }
        },
        confirmButton = {
            TextButton(onClick = {
                val v = value.toDoubleOrNull()
                error = if (v == null) "Enter the number shown on the meter." else onSave(Reading(day, v))
            }) { Text("Save") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}

// ---- Readings ------------------------------------------------------------------------------

@Composable
private fun ReadingsTab(model: BijliModel) {
    val start = model.start
    LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        if (start != null) {
            item { Text("Bill reading: ${num(start.value)} on ${formatDay(start.epochDay)}", fontWeight = FontWeight.Bold) }
        }
        if (model.readings.isEmpty()) {
            item { Text("No readings yet. Add one from the This month tab.") }
        }
        items(model.readings.reversed()) { r ->
            Card(Modifier.fillMaxWidth()) {
                Row(Modifier.padding(start = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(num(r.value), style = MaterialTheme.typography.titleMedium)
                        val used = start?.let { " · ${num(r.value - it.value)} units since bill" } ?: ""
                        Text(formatDay(r.epochDay) + used, style = MaterialTheme.typography.bodySmall)
                    }
                    IconButton(onClick = { model.deleteReading(r) }) {
                        Icon(Icons.Default.Delete, contentDescription = "Delete reading")
                    }
                }
            }
        }
    }
}

// ---- Tenants -------------------------------------------------------------------------------

@Composable
private fun TenantsTab(model: BijliModel, onEdit: (Tenant) -> Unit) {
    val context = LocalContext.current
    val month = LocalDate.now().format(DateTimeFormatter.ofPattern("MMM yyyy", Locale.ENGLISH))
    LazyColumn(
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 88.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        item {
            Text(
                "For landlords with sub-meters: enter each tenant's reading, then send the bill on WhatsApp.",
                style = MaterialTheme.typography.bodyMedium,
            )
        }
        if (model.tenants.isEmpty()) item { Text("No tenants yet. Tap + to add one.") }
        items(model.tenants, key = { it.id }) { t ->
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(t.name, style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
                        Text(rupees(t.amount), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    }
                    Text("${num(t.previous)} → ${num(t.current)} = ${num(t.units)} units × ₹${num(t.rate)}" +
                        if (t.fixedShare > 0) " + ₹${num(t.fixedShare)}" else "")
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        if (t.phone.isNotBlank()) {
                            Button(onClick = { openWhatsApp(context, t.phone, t.billMessage(month)) }) { Text("WhatsApp") }
                        }
                        OutlinedButton(onClick = { shareText(context, t.billMessage(month), "Send bill") }) { Text("Share") }
                        OutlinedButton(onClick = { onEdit(t) }) { Text("Edit") }
                    }
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        TextButton(onClick = { model.startNewMonth(t.id) }) { Text("Paid: start next month") }
                        TextButton(onClick = { model.deleteTenant(t.id) }) { Text("Remove") }
                    }
                }
            }
        }
    }
}

@Composable
private fun TenantDialog(initial: Tenant?, defaultRate: Double, onDismiss: () -> Unit, onSave: (Tenant) -> Unit) {
    var name by remember { mutableStateOf(initial?.name ?: "") }
    var phone by remember { mutableStateOf(initial?.phone ?: "") }
    var previous by remember { mutableStateOf(initial?.previous?.let(::num) ?: "") }
    var current by remember { mutableStateOf(initial?.current?.let(::num) ?: "") }
    var rate by remember { mutableStateOf(num(initial?.rate ?: defaultRate)) }
    var fixed by remember { mutableStateOf(initial?.fixedShare?.takeIf { it > 0 }?.let(::num) ?: "") }
    var error by remember { mutableStateOf<String?>(null) }
    val decimal = KeyboardOptions(keyboardType = KeyboardType.Decimal)
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (initial == null) "Add tenant" else "Edit tenant") },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                OutlinedTextField(name, { name = it }, label = { Text("Name / room") }, singleLine = true)
                OutlinedTextField(
                    phone, { phone = it }, label = { Text("WhatsApp number (optional)") }, singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                )
                OutlinedTextField(previous, { previous = it }, label = { Text("Last month's reading") }, singleLine = true, keyboardOptions = decimal)
                OutlinedTextField(current, { current = it }, label = { Text("This month's reading") }, singleLine = true, keyboardOptions = decimal)
                OutlinedTextField(rate, { rate = it }, label = { Text("Rate ₹ per unit") }, singleLine = true, keyboardOptions = decimal)
                OutlinedTextField(fixed, { fixed = it }, label = { Text("Fixed charge share ₹ (optional)") }, singleLine = true, keyboardOptions = decimal)
                error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
            }
        },
        confirmButton = {
            TextButton(onClick = {
                val p = previous.toDoubleOrNull()
                val c = current.toDoubleOrNull()
                val r = rate.toDoubleOrNull()
                val f = fixed.toDoubleOrNull() ?: 0.0
                error = when {
                    name.isBlank() -> "Enter a name."
                    p == null || c == null -> "Enter both meter readings."
                    c < p -> "This month's reading can't be lower than last month's."
                    r == null || r <= 0 -> "Enter the rate per unit."
                    else -> null
                }
                if (error == null && p != null && c != null && r != null) {
                    onSave(Tenant(initial?.id ?: BijliModel.newId(), name.trim(), phone.trim(), p, c, r, f))
                }
            }) { Text("Save") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}

// ---- Rates ---------------------------------------------------------------------------------

@Composable
private fun RatesTab(model: BijliModel) {
    val t = model.tariff
    val limits = remember(t) { mutableStateListOf(*t.slabs.map { it.upTo?.toString() ?: "" }.toTypedArray()) }
    val rates = remember(t) { mutableStateListOf(*t.slabs.map { it.rate.toString() }.toTypedArray()) }
    var surcharge by remember(t) { mutableStateOf(t.surchargePercent.toString()) }
    var duty by remember(t) { mutableStateOf(t.dutyPercent.toString()) }
    var fixed by remember(t) { mutableStateOf(num(t.fixedMonthly)) }
    var subsidy by remember(t) { mutableStateOf(t.subsidyEnabled) }
    var cycle by remember(t) { mutableStateOf(model.cycleDays.toString()) }
    var message by remember { mutableStateOf<String?>(null) }
    val decimal = KeyboardOptions(keyboardType = KeyboardType.Decimal)

    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text("Energy charge slabs (₹ per unit)", style = MaterialTheme.typography.titleMedium)
        rates.indices.forEach { i ->
            val isLast = i == rates.lastIndex
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                if (isLast) {
                    Text("Above ${limits.getOrNull(i - 1) ?: ""} units", Modifier.weight(1f))
                } else {
                    OutlinedTextField(
                        limits[i], { limits[i] = it.filter(Char::isDigit) }, label = { Text("Up to units") },
                        singleLine = true, keyboardOptions = decimal, modifier = Modifier.weight(1f),
                    )
                }
                OutlinedTextField(
                    rates[i], { rates[i] = it }, label = { Text("₹/unit") },
                    singleLine = true, keyboardOptions = decimal, modifier = Modifier.weight(1f),
                )
            }
        }
        OutlinedTextField(surcharge, { surcharge = it }, label = { Text("Fuel surcharge % (FPPAS)") }, singleLine = true, keyboardOptions = decimal)
        OutlinedTextField(duty, { duty = it }, label = { Text("Electricity duty %") }, singleLine = true, keyboardOptions = decimal)
        OutlinedTextField(fixed, { fixed = it }, label = { Text("Fixed charge + meter rent ₹/month") }, singleLine = true, keyboardOptions = decimal)
        OutlinedTextField(cycle, { cycle = it.filter(Char::isDigit) }, label = { Text("Days in your bill cycle") }, singleLine = true, keyboardOptions = decimal)
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text("Atal Griha Jyoti subsidy (MP)")
                Text("₹1/unit for the first 100 units when the month stays at 150 units or less.", style = MaterialTheme.typography.bodySmall)
            }
            Switch(checked = subsidy, onCheckedChange = { subsidy = it })
        }
        Button(onClick = {
            val parsedRates = rates.map { it.toDoubleOrNull() }
            val parsedLimits = limits.dropLast(1).map { it.toIntOrNull() }
            val s = surcharge.toDoubleOrNull()
            val d = duty.toDoubleOrNull()
            val f = fixed.toDoubleOrNull() ?: 0.0
            val c = cycle.toIntOrNull()
            val limitsOk = parsedLimits.all { it != null && it > 0 } &&
                parsedLimits.filterNotNull().zipWithNext().all { (a, b) -> b > a }
            message = if (parsedRates.any { it == null } || !limitsOk || s == null || d == null || c == null || c !in 20..62) {
                "Check the numbers: slab limits must increase, and the cycle must be 20–62 days."
            } else {
                val slabs = parsedRates.mapIndexed { i, r -> Slab(parsedLimits.getOrNull(i), r!!) }
                model.saveTariff(Tariff(slabs, s, d, f, subsidy), c)
                "Saved."
            }
        }, modifier = Modifier.fillMaxWidth()) { Text("Save rates") }
        TextButton(onClick = { model.saveTariff(Tariff.MP_2026_27, model.cycleDays); message = "Reset to MP FY 2026-27 rates." }) {
            Text("Reset to MP 2026-27 rates")
        }
        message?.let { Text(it, color = MaterialTheme.colorScheme.primary) }
        Text(
            "Defaults: MPERC domestic tariff FY 2026-27 as reported publicly (₹4.71 / 5.67 / 7.05 / 7.24), " +
                "about 5% fuel surcharge, 9% duty. Copy the fixed charge from your bill. Rates change every April.",
            style = MaterialTheme.typography.bodySmall,
        )
        Spacer(Modifier.height(24.dp))
    }
}
