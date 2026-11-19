package io.github.sachin102492.bijli

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/** Everything is stored on the phone in SharedPreferences as JSON. Nothing leaves the device. */
class BijliStore(context: Context) {
    private val p = context.getSharedPreferences("bijli", Context.MODE_PRIVATE)

    var start: Reading?
        get() = p.getString("start", null)?.let { readingFrom(JSONObject(it)) }
        set(v) = p.edit().putString("start", v?.let { readingJson(it).toString() }).apply()

    var readings: List<Reading>
        get() = array("readings").map { readingFrom(it) }
        set(v) = p.edit().putString("readings", JSONArray(v.map { readingJson(it) }).toString()).apply()

    var cycleDays: Int
        get() = p.getInt("cycleDays", 30)
        set(v) = p.edit().putInt("cycleDays", v).apply()

    var tariff: Tariff
        get() = p.getString("tariff", null)?.let { tariffFrom(JSONObject(it)) } ?: Tariff.MP_2026_27
        set(v) = p.edit().putString("tariff", tariffJson(v).toString()).apply()

    var tenants: List<Tenant>
        get() = array("tenants").map { tenantFrom(it) }
        set(v) = p.edit().putString("tenants", JSONArray(v.map { tenantJson(it) }).toString()).apply()

    var defaultTenantRate: Double
        get() = p.getFloat("tenantRate", 8f).toDouble()
        set(v) = p.edit().putFloat("tenantRate", v.toFloat()).apply()

    private fun array(key: String): List<JSONObject> {
        val raw = p.getString(key, null) ?: return emptyList()
        val a = JSONArray(raw)
        return (0 until a.length()).map { a.getJSONObject(it) }
    }

    private fun readingJson(r: Reading) = JSONObject().put("day", r.epochDay).put("value", r.value)
    private fun readingFrom(o: JSONObject) = Reading(o.getLong("day"), o.getDouble("value"))

    private fun tariffJson(t: Tariff) = JSONObject()
        .put("slabs", JSONArray(t.slabs.map { s -> JSONObject().put("upTo", s.upTo ?: -1).put("rate", s.rate) }))
        .put("surcharge", t.surchargePercent)
        .put("duty", t.dutyPercent)
        .put("fixed", t.fixedMonthly)
        .put("subsidy", t.subsidyEnabled)

    private fun tariffFrom(o: JSONObject): Tariff {
        val a = o.getJSONArray("slabs")
        val slabs = (0 until a.length()).map { i ->
            val s = a.getJSONObject(i)
            Slab(s.getInt("upTo").takeIf { it >= 0 }, s.getDouble("rate"))
        }
        return Tariff(
            slabs = slabs,
            surchargePercent = o.getDouble("surcharge"),
            dutyPercent = o.getDouble("duty"),
            fixedMonthly = o.getDouble("fixed"),
            subsidyEnabled = o.getBoolean("subsidy"),
        )
    }

    private fun tenantJson(t: Tenant) = JSONObject()
        .put("id", t.id).put("name", t.name).put("phone", t.phone)
        .put("previous", t.previous).put("current", t.current)
        .put("rate", t.rate).put("fixed", t.fixedShare)

    private fun tenantFrom(o: JSONObject) = Tenant(
        id = o.getString("id"),
        name = o.getString("name"),
        phone = o.optString("phone", ""),
        previous = o.getDouble("previous"),
        current = o.getDouble("current"),
        rate = o.getDouble("rate"),
        fixedShare = o.optDouble("fixed", 0.0),
    )
}

/** Screen state backed by [BijliStore]; every change is saved immediately. */
class BijliModel(private val store: BijliStore) {
    var start by mutableStateOf(store.start)
        private set
    var readings by mutableStateOf(store.readings.sortedBy { it.epochDay })
        private set
    var tariff by mutableStateOf(store.tariff)
        private set
    var cycleDays by mutableStateOf(store.cycleDays)
        private set
    var tenants by mutableStateOf(store.tenants)
        private set
    val defaultTenantRate: Double get() = store.defaultTenantRate

    val latest: Reading? get() = readings.maxByOrNull { it.epochDay }

    fun projection(): Projection? {
        val s = start ?: return null
        val l = latest ?: return null
        if (l.epochDay < s.epochDay) return null
        return Projector.project(s, l, cycleDays, tariff)
    }

    /** Starts a billing cycle from the reading printed on the latest bill. */
    fun beginCycle(r: Reading) {
        start = r
        store.start = r
        readings = readings.filter { it.epochDay > r.epochDay && it.value >= r.value }
        store.readings = readings
    }

    /** Returns an error message, or null when saved. */
    fun addReading(r: Reading): String? {
        val s = start
        if (s != null && r.value < s.value) return "The reading can't be lower than the last bill's reading (${s.value})."
        if (s != null && r.epochDay < s.epochDay) return "That date is before the last bill."
        readings = (readings.filter { it.epochDay != r.epochDay } + r).sortedBy { it.epochDay }
        store.readings = readings
        return null
    }

    fun deleteReading(r: Reading) {
        readings = readings - r
        store.readings = readings
    }

    fun saveTariff(t: Tariff, cycle: Int) {
        tariff = t
        store.tariff = t
        cycleDays = cycle
        store.cycleDays = cycle
    }

    fun upsertTenant(t: Tenant) {
        tenants = if (tenants.any { it.id == t.id }) tenants.map { if (it.id == t.id) t else it } else tenants + t
        store.tenants = tenants
        store.defaultTenantRate = t.rate
    }

    fun deleteTenant(id: String) {
        tenants = tenants.filterNot { it.id == id }
        store.tenants = tenants
    }

    /** After billing a tenant: this month's closing reading becomes next month's opening one. */
    fun startNewMonth(id: String) {
        tenants = tenants.map { if (it.id == id) it.copy(previous = it.current) else it }
        store.tenants = tenants
    }

    companion object {
        fun newId(): String = UUID.randomUUID().toString()

        /** Sample data for screenshots and the emulator test (debug builds only). */
        fun seedDemo(store: BijliStore, today: Long) {
            store.start = Reading(today - 18, 5230.0)
            store.readings = listOf(Reading(today - 9, 5291.0), Reading(today, 5348.0))
            store.tariff = Tariff.MP_2026_27
            store.cycleDays = 30
            store.tenants = listOf(
                Tenant(newId(), "Room 1 – Ramesh", "9876543210", 1204.0, 1291.0, 9.0, 50.0),
                Tenant(newId(), "Shop – Priya Stores", "", 3410.0, 3586.0, 10.0, 0.0),
            )
        }
    }
}
