package io.github.sachin102492.gharclock

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import org.json.JSONArray
import org.json.JSONObject
import java.time.Duration
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.util.UUID
import java.util.concurrent.TimeUnit

/** Items are stored on the phone only, as JSON in SharedPreferences. */
class GharStore(context: Context) {
    private val p = context.getSharedPreferences("gharclock", Context.MODE_PRIVATE)

    var items: List<HomeItem>
        get() {
            val raw = p.getString("items", null) ?: return emptyList()
            val a = JSONArray(raw)
            return (0 until a.length()).map { fromJson(a.getJSONObject(it)) }
        }
        set(v) = p.edit().putString("items", JSONArray(v.map { toJson(it) }).toString()).apply()

    var onboarded: Boolean
        get() = p.getBoolean("onboarded", false)
        set(v) = p.edit().putBoolean("onboarded", v).apply()

    private fun toJson(i: HomeItem) = JSONObject()
        .put("id", i.id).put("name", i.name).put("learns", i.learns)
        .put("interval", i.intervalDays).put("remind", i.remindBefore)
        .put("history", JSONArray(i.history)).put("contact", i.contact)

    private fun fromJson(o: JSONObject): HomeItem {
        val h = o.optJSONArray("history") ?: JSONArray()
        return HomeItem(
            id = o.getString("id"),
            name = o.getString("name"),
            learns = o.optBoolean("learns", false),
            intervalDays = o.getInt("interval"),
            remindBefore = o.optInt("remind", 3),
            history = (0 until h.length()).map { h.getLong(it) },
            contact = o.optString("contact", ""),
        )
    }
}

class GharModel(private val store: GharStore) {
    var items by mutableStateOf(store.items)
        private set
    var onboarded by mutableStateOf(store.onboarded)
        private set

    private fun save(list: List<HomeItem>) {
        items = list
        store.items = list
    }

    fun addPresets(chosen: List<Preset>) {
        val existing = items.map { it.name }.toSet()
        save(items + chosen.filter { it.name !in existing }.map {
            HomeItem(newId(), it.name, it.learns, it.intervalDays, it.remindBefore)
        })
        onboarded = true
        store.onboarded = true
    }

    fun upsert(item: HomeItem) =
        save(if (items.any { it.id == item.id }) items.map { if (it.id == item.id) item else it } else items + item)

    fun delete(id: String) = save(items.filterNot { it.id == id })

    fun markDone(id: String, epochDay: Long) =
        save(items.map { if (it.id == id) it.copy(history = (it.history + epochDay).distinct().sorted()) else it })

    fun removeDate(id: String, epochDay: Long) =
        save(items.map { if (it.id == id) it.copy(history = it.history - epochDay) else it })

    companion object {
        fun newId(): String = UUID.randomUUID().toString()

        /** Sample history for screenshots and the emulator test (debug builds only). */
        fun seedDemo(store: GharStore, today: Long) {
            store.items = listOf(
                HomeItem(newId(), "LPG cylinder", true, 35, 5, listOf(today - 97, today - 64, today - 32), "9876543210"),
                HomeItem(newId(), "RO / water purifier service", false, 180, 7, listOf(today - 176)),
                HomeItem(newId(), "Kitchen chimney filter", false, 30, 2, listOf(today - 34)),
                HomeItem(newId(), "AC service", false, 365, 14, listOf(today - 200)),
                HomeItem(newId(), "Inverter battery water", false, 60, 3, emptyList()),
            )
            store.onboarded = true
        }
    }
}

/** Once a day (around 9 AM) checks what is due and posts one summary notification. */
class ReminderWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val today = LocalDate.now().toEpochDay()
        val due = Schedule.needingReminder(GharStore(applicationContext).items, today)
        val text = Schedule.reminderText(due, today) ?: return Result.success()
        notify(applicationContext, text.first, text.second)
        return Result.success()
    }

    companion object {
        private const val WORK_NAME = "daily-reminder"
        private const val CHANNEL = "reminders"

        fun schedule(context: Context) {
            val now = LocalDateTime.now()
            var next = now.toLocalDate().atTime(LocalTime.of(9, 0))
            if (!next.isAfter(now)) next = next.plusDays(1)
            val request = PeriodicWorkRequestBuilder<ReminderWorker>(1, TimeUnit.DAYS)
                .setInitialDelay(Duration.between(now, next).toMinutes(), TimeUnit.MINUTES)
                .build()
            WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork(WORK_NAME, ExistingPeriodicWorkPolicy.KEEP, request)
        }

        private fun notify(context: Context, title: String, body: String) {
            if (Build.VERSION.SDK_INT >= 33 &&
                ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
            ) {
                return
            }
            context.getSystemService(NotificationManager::class.java)?.createNotificationChannel(
                NotificationChannel(CHANNEL, "Home reminders", NotificationManager.IMPORTANCE_DEFAULT),
            )
            val open = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            val n = NotificationCompat.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_stat_gharclock)
                .setContentTitle(title)
                .setContentText(body.lineSequence().first())
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setContentIntent(open)
                .setAutoCancel(true)
                .build()
            try {
                NotificationManagerCompat.from(context).notify(1, n)
            } catch (ignored: SecurityException) {
            }
        }
    }
}
