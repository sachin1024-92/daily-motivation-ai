package io.github.sachin102492.bijli

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class BillingTest {
    private val mp = Tariff.MP_2026_27
    private val noSubsidy = mp.copy(subsidyEnabled = false)

    @Test fun telescopicEnergy() {
        assertEquals(0.0, BillCalculator.energyBetween(0.0, 0.0, mp.slabs), 1e-9)
        assertEquals(50 * 4.71, BillCalculator.energyBetween(0.0, 50.0, mp.slabs), 1e-9)
        assertEquals(50 * 4.71 + 100 * 5.67, BillCalculator.energyBetween(0.0, 150.0, mp.slabs), 1e-9)
        assertEquals(50 * 4.71 + 100 * 5.67 + 150 * 7.05 + 100 * 7.24, BillCalculator.energyBetween(0.0, 400.0, mp.slabs), 1e-9)
        // Units 101–150 sit in the 51–150 slab.
        assertEquals(50 * 5.67, BillCalculator.energyBetween(100.0, 150.0, mp.slabs), 1e-9)
    }

    @Test fun normalBillAddsSurchargeDutyAndFixed() {
        val t = noSubsidy.copy(fixedMonthly = 120.0)
        val b = BillCalculator.bill(200.0, t)
        val energy = 50 * 4.71 + 100 * 5.67 + 50 * 7.05
        assertEquals(energy, b.energy, 1e-9)
        assertEquals(energy * 0.0506, b.surcharge, 1e-9)
        assertEquals((energy * 1.0506) * 0.09, b.duty, 1e-9)
        assertEquals(120.0, b.fixed, 1e-9)
        assertFalse(b.subsidised)
    }

    @Test fun subsidyCostsOneRupeePerUnitUpTo100() {
        val b = BillCalculator.bill(80.0, mp)
        assertTrue(b.subsidised)
        assertEquals(80.0, b.total, 1e-9)
        assertEquals(100.0, BillCalculator.bill(100.0, mp).total, 1e-9)
    }

    @Test fun subsidyChargesUnits101To150Normally() {
        val b = BillCalculator.bill(150.0, mp)
        val extra = 50 * 5.67
        assertEquals(100.0 + extra + extra * 0.0506 + extra * 1.0506 * 0.09, b.total, 1e-6)
    }

    @Test fun crossing150LosesTheSubsidy() {
        val at150 = BillCalculator.bill(150.0, mp).total
        val at151 = BillCalculator.bill(151.0, mp).total
        assertTrue("one extra unit should cost far more than ₹10 (was ${at151 - at150})", at151 - at150 > 400)
    }

    @Test fun projectionWarnsAboutTheSubsidyLimitFirst() {
        // 118 units in 18 days of a 30-day cycle: about 197 by month end.
        val p = Projector.project(Reading(1000, 5230.0), Reading(1018, 5348.0), 30, mp)
        assertEquals(118.0, p.unitsSoFar, 1e-9)
        assertEquals(12, p.daysLeft)
        assertEquals(118.0 + 118.0 / 18 * 12, p.projectedUnits, 1e-9)
        val a = p.alert
        assertNotNull(a)
        a!!
        assertEquals(150, a.threshold)
        assertTrue(a.isSubsidyLimit)
        assertEquals((150 - 118) / 12.0, a.safePerDay, 1e-9)
        assertEquals(1018L + 5, a.crossOnEpochDay) // 32 units left at 6.56/day → crossed on day 5
        assertTrue(a.extraCost > 0)
        assertFalse(p.subsidyAlreadyLost)
    }

    @Test fun projectionWithoutSubsidyPicksNextSlab() {
        val p = Projector.project(Reading(0, 0.0), Reading(10, 40.0), 30, noSubsidy)
        assertEquals(120.0, p.projectedUnits, 1e-9)
        assertEquals(50, p.alert!!.threshold)
    }

    @Test fun noAlertWhenComfortablyUnder() {
        val p = Projector.project(Reading(0, 0.0), Reading(15, 30.0), 30, mp)
        assertNull(p.alert)
    }

    @Test fun subsidyAlreadyLostIsReported() {
        val p = Projector.project(Reading(0, 0.0), Reading(20, 160.0), 30, mp)
        assertTrue(p.subsidyAlreadyLost)
    }

    @Test fun sameDayReadingDoesNotDivideByZero() {
        val p = Projector.project(Reading(5, 10.0), Reading(5, 12.0), 30, mp)
        assertEquals(0.0, p.perDay, 1e-9)
        assertEquals(2.0, p.projectedUnits, 1e-9)
    }

    @Test fun tenantBill() {
        val t = Tenant("1", "Ramesh", "9876543210", 1200.0, 1290.0, 9.0, 50.0)
        assertEquals(90.0, t.units, 1e-9)
        assertEquals(860.0, t.amount, 1e-9)
        val msg = t.billMessage("Nov 2026")
        assertTrue(msg.contains("1200 → 1290 = 90 units"))
        assertTrue(msg.contains("Total: ₹860"))
    }
}
