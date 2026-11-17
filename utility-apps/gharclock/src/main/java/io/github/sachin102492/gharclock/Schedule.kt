package io.github.sachin102492.gharclock

import kotlin.math.roundToInt

/** Something in the home that needs refilling or servicing on a rhythm. */
data class HomeItem(
    val id: String,
    val name: String,
    /** True for things like the LPG cylinder whose interval is learned from the user's own dates. */
    val learns: Boolean,
    val intervalDays: Int,
    val remindBefore: Int,
    /** Epoch days when it was done/refilled. */
    val history: List<Long> = emptyList(),
    val contact: String = "",
)

enum class DueState { OVERDUE, DUE_SOON, OK, NOT_STARTED }

data class Due(val state: DueState, val nextEpochDay: Long?, val daysLeft: Long?)

object Schedule {
    private const val MIN_GAP = 5
    private const val MAX_GAP = 400

    /** Average of the last five gaps between refills, once there are at least two refills. */
    fun learnedInterval(item: HomeItem): Int? {
        if (!item.learns) return null
        val gaps = item.history.distinct().sorted()
            .zipWithNext { a, b -> (b - a).toInt() }
            .filter { it in MIN_GAP..MAX_GAP }
            .takeLast(5)
        if (gaps.isEmpty()) return null
        return gaps.average().roundToInt()
    }

    fun interval(item: HomeItem): Int = learnedInterval(item) ?: item.intervalDays

    fun due(item: HomeItem, today: Long): Due {
        val last = item.history.maxOrNull() ?: return Due(DueState.NOT_STARTED, null, null)
        val next = last + interval(item)
        val left = next - today
        val state = when {
            left < 0 -> DueState.OVERDUE
            left <= item.remindBefore -> DueState.DUE_SOON
            else -> DueState.OK
        }
        return Due(state, next, left)
    }

    /** Most urgent first; things never done go last. */
    fun sorted(items: List<HomeItem>, today: Long): List<HomeItem> =
        items.sortedWith(
            compareBy<HomeItem> { due(it, today).state.ordinal }
                .thenBy { due(it, today).daysLeft ?: Long.MAX_VALUE }
                .thenBy { it.name },
        )

    fun needingReminder(items: List<HomeItem>, today: Long): List<HomeItem> =
        sorted(items, today).filter {
            val s = due(it, today).state
            s == DueState.OVERDUE || s == DueState.DUE_SOON
        }

    fun reminderText(items: List<HomeItem>, today: Long): Pair<String, String>? {
        if (items.isEmpty()) return null
        fun phrase(i: HomeItem): String {
            val d = due(i, today)
            val left = d.daysLeft ?: 0
            return when {
                left < 0 -> "${i.name}: overdue by ${-left} day" + if (-left == 1L) "" else "s"
                left == 0L -> "${i.name}: due today"
                else -> "${i.name}: due in $left day" + if (left == 1L) "" else "s"
            }
        }
        val title = if (items.size == 1) phrase(items[0]) else "${items.size} things need attention"
        val body = if (items.size == 1) {
            if (items[0].learns) "Book the refill now so you don't run out." else "Tap to see details."
        } else {
            items.joinToString("\n") { phrase(it) }
        }
        return title to body
    }
}

data class Preset(val name: String, val learns: Boolean, val intervalDays: Int, val remindBefore: Int, val defaultOn: Boolean)

val presets = listOf(
    Preset("LPG cylinder", learns = true, intervalDays = 35, remindBefore = 5, defaultOn = true),
    Preset("RO / water purifier service", learns = false, intervalDays = 180, remindBefore = 7, defaultOn = true),
    Preset("AC service", learns = false, intervalDays = 365, remindBefore = 14, defaultOn = true),
    Preset("Inverter battery water", learns = false, intervalDays = 60, remindBefore = 3, defaultOn = true),
    Preset("Kitchen chimney filter", learns = false, intervalDays = 30, remindBefore = 2, defaultOn = true),
    Preset("Water tank cleaning", learns = false, intervalDays = 180, remindBefore = 7, defaultOn = true),
    Preset("Gas pipe (Suraksha hose)", learns = false, intervalDays = 1825, remindBefore = 30, defaultOn = false),
    Preset("Pest control", learns = false, intervalDays = 180, remindBefore = 7, defaultOn = false),
    Preset("Fire extinguisher refill", learns = false, intervalDays = 365, remindBefore = 14, defaultOn = false),
    Preset("Bike / car service", learns = false, intervalDays = 90, remindBefore = 5, defaultOn = false),
    Preset("Vehicle PUC certificate", learns = false, intervalDays = 365, remindBefore = 10, defaultOn = false),
    Preset("Drinking water can", learns = true, intervalDays = 4, remindBefore = 1, defaultOn = false),
)
