package io.github.sachin102492.safeshare

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

data class ShareRecord(val epochDay: Long, val purpose: String)

/** A private list of who was given a copy, so the user can remember later. Stored on the phone only. */
class ShareLog(context: Context) {
    private val prefs = context.getSharedPreferences("safeshare", Context.MODE_PRIVATE)

    fun all(): List<ShareRecord> {
        val raw = prefs.getString("log", null) ?: return emptyList()
        val a = JSONArray(raw)
        return (0 until a.length()).map {
            val o = a.getJSONObject(it)
            ShareRecord(o.getLong("day"), o.getString("purpose"))
        }
    }

    fun add(record: ShareRecord) = save(listOf(record) + all().take(199))

    fun remove(record: ShareRecord) = save(all() - record)

    private fun save(list: List<ShareRecord>) {
        val a = JSONArray(list.map { JSONObject().put("day", it.epochDay).put("purpose", it.purpose) })
        prefs.edit().putString("log", a.toString()).apply()
    }
}
