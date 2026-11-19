package io.github.sachin102492.seeti

import android.content.Context
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update

enum class AlarmReason { TARGET_REACHED, SAFETY_TIMER }

data class Session(
    val running: Boolean = false,
    val count: Int = 0,
    val target: Int = 3,
    val levelDb: Float = -90f,
    val hearing: Boolean = false,
    val startedAtMillis: Long = 0L,
    val safetyMinutes: Int = 0,
    val alarm: AlarmReason? = null,
    val error: String? = null,
)

/** Shared between the listening service and the screen. */
object SeetiState {
    val session = MutableStateFlow(Session())

    /** Manual correction from the screen; the service raises the alarm if the target is reached. */
    fun adjustCount(delta: Int) {
        session.update { it.copy(count = (it.count + delta).coerceAtLeast(0)) }
    }
}

data class Preset(val name: String, val whistles: Int)

val presets = listOf(
    Preset("Rice", 2),
    Preset("Dal", 3),
    Preset("Aloo", 3),
    Preset("Chana", 5),
    Preset("Rajma", 6),
    Preset("Mutton", 8),
)

class SeetiPrefs(context: Context) {
    private val p = context.getSharedPreferences("seeti", Context.MODE_PRIVATE)

    var target: Int
        get() = p.getInt("target", 3)
        set(v) = p.edit().putInt("target", v).apply()

    var sensitivity: Sensitivity
        get() = Sensitivity.entries.getOrElse(p.getInt("sensitivity", 1)) { Sensitivity.MEDIUM }
        set(v) = p.edit().putInt("sensitivity", v.ordinal).apply()

    var safetyMinutes: Int
        get() = p.getInt("safety", 0)
        set(v) = p.edit().putInt("safety", v).apply()

    var disclosureAccepted: Boolean
        get() = p.getBoolean("disclosure", false)
        set(v) = p.edit().putBoolean("disclosure", v).apply()
}
