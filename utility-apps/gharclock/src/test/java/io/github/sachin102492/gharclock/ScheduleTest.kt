package io.github.sachin102492.gharclock

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ScheduleTest {
    private fun lpg(vararg days: Long) = HomeItem("lpg", "LPG cylinder", learns = true, intervalDays = 35, remindBefore = 5, history = days.toList())

    @Test fun usesDefaultUntilTwoRefills() {
        assertNull(Schedule.learnedInterval(lpg()))
        assertNull(Schedule.learnedInterval(lpg(100)))
        assertEquals(35, Schedule.interval(lpg(100)))
    }

    @Test fun learnsAverageGap() {
        // gaps 30, 32, 33 → 31.67 → 32
        assertEquals(32, Schedule.learnedInterval(lpg(0, 30, 62, 95)))
    }

    @Test fun usesOnlyTheLastFiveGaps() {
        // An old 60-day gap drops out once five newer gaps exist.
        val item = lpg(0, 60, 90, 120, 150, 180, 210)
        assertEquals(30, Schedule.learnedInterval(item))
    }

    @Test fun ignoresDuplicateAndImpossibleGaps() {
        // Same day entered twice (gap 0) and a 2-day typo are ignored.
        assertEquals(31, Schedule.learnedInterval(lpg(0, 31, 31, 33)))
    }

    @Test fun fixedItemsNeverLearn() {
        val ro = HomeItem("ro", "RO service", learns = false, intervalDays = 180, remindBefore = 7, history = listOf(0, 90))
        assertNull(Schedule.learnedInterval(ro))
        assertEquals(180, Schedule.interval(ro))
    }

    @Test fun dueStates() {
        val item = lpg(0, 30, 60) // learned 30 → next on day 90, remind 5 days before
        assertEquals(DueState.OK, Schedule.due(item, 80).state)
        assertEquals(DueState.DUE_SOON, Schedule.due(item, 85).state)
        assertEquals(DueState.DUE_SOON, Schedule.due(item, 90).state)
        val overdue = Schedule.due(item, 93)
        assertEquals(DueState.OVERDUE, overdue.state)
        assertEquals(-3L, overdue.daysLeft)
        assertEquals(90L, overdue.nextEpochDay)
        assertEquals(DueState.NOT_STARTED, Schedule.due(lpg(), 10).state)
    }

    @Test fun mostUrgentFirst() {
        val a = HomeItem("a", "AC", false, 365, 14, listOf(0))
        val b = HomeItem("b", "Chimney", false, 30, 2, listOf(0)) // overdue at day 40
        val c = HomeItem("c", "Tank", false, 180, 7, emptyList())
        val d = HomeItem("d", "Inverter", false, 60, 3, listOf(0)) // due soon at day 58
        val order = Schedule.sorted(listOf(a, b, c, d), today = 58).map { it.id }
        assertEquals(listOf("b", "d", "a", "c"), order)
        assertEquals(listOf("b", "d"), Schedule.needingReminder(listOf(a, b, c, d), 58).map { it.id })
    }

    @Test fun reminderWording() {
        val (title, body) = Schedule.reminderText(listOf(lpg(0, 30, 60)), today = 87)!!
        assertEquals("LPG cylinder: due in 3 days", title)
        assertTrue(body.contains("Book the refill"))
        val two = Schedule.reminderText(
            listOf(lpg(0, 30, 60), HomeItem("b", "Chimney", false, 30, 2, listOf(62))),
            today = 91,
        )!!
        assertEquals("2 things need attention", two.first)
        assertTrue(two.second.contains("LPG cylinder: overdue by 1 day"))
        assertTrue(two.second.contains("Chimney: due in 1 day"))
        assertNull(Schedule.reminderText(emptyList(), 0))
    }
}
