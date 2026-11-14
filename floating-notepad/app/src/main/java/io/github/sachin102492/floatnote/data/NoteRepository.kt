package io.github.sachin102492.floatnote.data

import android.content.Context
import android.util.AtomicFile
import android.util.Log
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.io.File
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.Executors
import kotlin.math.max

/**
 * Offline note store backed by a single JSON file.
 *
 * All reads and mutations happen on the main thread against an in-memory copy; every mutation
 * snapshots the notes and writes them atomically on a background thread, so a crash or a kill
 * mid-write can never corrupt the file.
 */
class NoteRepository(context: Context) {

    fun interface Listener {
        fun onNotesChanged()
    }

    private val file = AtomicFile(File(context.filesDir, "notes.json"))
    private val prefs = context.getSharedPreferences("notes", Context.MODE_PRIVATE)
    private val io = Executors.newSingleThreadExecutor()
    private val notes = LinkedHashMap<Long, Note>()
    private val listeners = LinkedHashSet<Listener>()
    private var lastId = 0L

    init {
        load()
    }

    /** Most recently edited first. */
    val all: List<Note>
        get() = notes.values.sortedByDescending { it.updatedAt }

    /** Newest first; a stable order for paging through notes while they are being edited. */
    val byCreation: List<Note>
        get() = notes.values.sortedByDescending { it.createdAt }

    operator fun get(id: Long): Note? = notes[id]

    /** The note the floating bubble opens. */
    var activeNoteId: Long
        get() = prefs.getLong(KEY_ACTIVE, NO_ID)
        set(value) {
            prefs.edit().putLong(KEY_ACTIVE, value).apply()
        }

    fun activeOrNewest(): Note =
        notes[activeNoteId] ?: all.firstOrNull()?.also { activeNoteId = it.id } ?: create()

    fun create(): Note {
        val now = System.currentTimeMillis()
        val note = Note(nextId(now), "", "", now, now)
        notes[note.id] = note
        activeNoteId = note.id
        changed()
        return note
    }

    /** Saves [title] and [body] for [id], re-creating the note if it was deleted elsewhere. */
    fun save(id: Long, title: String, body: String) {
        val old = notes[id]
        if (old != null && old.title == title && old.body == body) return
        val now = System.currentTimeMillis()
        notes[id] = old?.copy(title = title, body = body, updatedAt = now)
            ?: Note(id, title, body, now, now)
        lastId = max(lastId, id)
        changed()
    }

    fun delete(id: Long): Note? {
        val removed = notes.remove(id) ?: return null
        if (activeNoteId == id) activeNoteId = NO_ID
        changed()
        return removed
    }

    fun deleteIfBlank(id: Long) {
        if (notes[id]?.isBlank == true) delete(id)
    }

    fun restore(note: Note) {
        notes[note.id] = note
        changed()
    }

    fun addListener(listener: Listener) {
        listeners.add(listener)
    }

    fun removeListener(listener: Listener) {
        listeners.remove(listener)
    }

    private fun nextId(now: Long): Long {
        lastId = max(now, lastId + 1)
        return lastId
    }

    private fun changed() {
        val snapshot = serialize()
        io.execute { write(snapshot) }
        listeners.toList().forEach { it.onNotesChanged() }
    }

    private fun load() {
        val text = try {
            String(file.readFully(), Charsets.UTF_8)
        } catch (e: FileNotFoundException) {
            return
        } catch (e: IOException) {
            Log.e(TAG, "Could not read notes", e)
            return
        }
        try {
            val array = JSONObject(text).getJSONArray("notes")
            for (i in 0 until array.length()) {
                val o = array.getJSONObject(i)
                val note = Note(
                    id = o.getLong("id"),
                    title = o.optString("title"),
                    body = o.optString("body"),
                    createdAt = o.optLong("createdAt"),
                    updatedAt = o.optLong("updatedAt"),
                )
                notes[note.id] = note
                lastId = max(lastId, note.id)
            }
        } catch (e: JSONException) {
            Log.e(TAG, "Notes file is corrupt", e)
        }
    }

    private fun serialize(): String {
        val array = JSONArray()
        for (note in notes.values) {
            array.put(
                JSONObject()
                    .put("id", note.id)
                    .put("title", note.title)
                    .put("body", note.body)
                    .put("createdAt", note.createdAt)
                    .put("updatedAt", note.updatedAt),
            )
        }
        return JSONObject().put("version", 1).put("notes", array).toString()
    }

    private fun write(json: String) {
        var out: FileOutputStream? = null
        try {
            out = file.startWrite()
            out.write(json.toByteArray(Charsets.UTF_8))
            file.finishWrite(out)
        } catch (e: IOException) {
            Log.e(TAG, "Could not save notes", e)
            if (out != null) file.failWrite(out)
        }
    }

    companion object {
        const val NO_ID = -1L
        private const val KEY_ACTIVE = "active_note"
        private const val TAG = "NoteRepository"
    }
}
