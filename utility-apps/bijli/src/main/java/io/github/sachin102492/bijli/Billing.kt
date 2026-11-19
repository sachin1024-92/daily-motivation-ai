package io.github.sachin102492.bijli

import java.util.Locale
import kotlin.math.ceil

/** One slab: units up to and including [upTo] (null = no upper limit) cost [rate] ₹/unit. */
data class Slab(val upTo: Int?, val rate: Double)

/**
 * A domestic tariff. Every number is editable in the app because tariffs change every April and
 * differ by state. The default is Madhya Pradesh's domestic (LV-1.2) tariff for FY 2026-27.
 */
data class Tariff(
    val slabs: List<Slab>,
    /** Fuel and power purchase adjustment surcharge, % of energy charges. */
    val surchargePercent: Double,
    /** Electricity duty, % of energy charges plus surcharge. */
    val dutyPercent: Double,
    /** Fixed charge and meter rent per month, copied from the user's own bill. */
    val fixedMonthly: Double,
    /** MP's Atal Griha Jyoti subsidy: ₹1/unit for the first 100 units if the month stays ≤ 150. */
    val subsidyEnabled: Boolean,
    val subsidyLimit: Int = 150,
    val subsidyUnits: Int = 100,
    val subsidyRate: Double = 1.0,
) {
    /**
     * Usage levels worth warning about. With the subsidy on, slab edges below its limit don't
     * matter (those units cost ₹1 or the same slab rate either way), only the limit and higher.
     */
    fun thresholds(): List<Int> {
        val edges = slabs.mapNotNull { it.upTo }
        val relevant = if (subsidyEnabled) edges.filter { it > subsidyLimit } + subsidyLimit else edges
        return relevant.distinct().sorted()
    }

    companion object {
        val MP_2026_27 = Tariff(
            slabs = listOf(Slab(50, 4.71), Slab(150, 5.67), Slab(300, 7.05), Slab(null, 7.24)),
            surchargePercent = 5.06,
            dutyPercent = 9.0,
            fixedMonthly = 0.0,
            subsidyEnabled = true,
        )
    }
}

data class Bill(
    val units: Double,
    val energy: Double,
    val surcharge: Double,
    val duty: Double,
    val fixed: Double,
    val subsidised: Boolean,
) {
    val total: Double get() = energy + surcharge + duty + fixed
}

object BillCalculator {
    /** Telescopic slabs: each unit is charged at the rate of the slab it falls in. Units in (from, to]. */
    fun energyBetween(from: Double, to: Double, slabs: List<Slab>): Double {
        if (to <= from) return 0.0
        var total = 0.0
        var lower = 0.0
        for (slab in slabs) {
            val upper = slab.upTo?.toDouble() ?: Double.MAX_VALUE
            val a = maxOf(from, lower)
            val b = minOf(to, upper)
            if (b > a) total += (b - a) * slab.rate
            lower = upper
            if (lower >= to) break
        }
        return total
    }

    fun bill(units: Double, t: Tariff): Bill {
        val u = units.coerceAtLeast(0.0)
        return if (t.subsidyEnabled && u <= t.subsidyLimit) {
            // Subsidised month: ₹1/unit for the first 100 units; units 101–150 at the normal rate.
            val base = minOf(u, t.subsidyUnits.toDouble()) * t.subsidyRate
            val extraEnergy = energyBetween(t.subsidyUnits.toDouble(), u, t.slabs)
            val surcharge = extraEnergy * t.surchargePercent / 100
            val duty = (extraEnergy + surcharge) * t.dutyPercent / 100
            Bill(u, base + extraEnergy, surcharge, duty, 0.0, subsidised = true)
        } else {
            val energy = energyBetween(0.0, u, t.slabs)
            val surcharge = energy * t.surchargePercent / 100
            val duty = (energy + surcharge) * t.dutyPercent / 100
            Bill(u, energy, surcharge, duty, t.fixedMonthly, subsidised = false)
        }
    }
}

data class Reading(val epochDay: Long, val value: Double)

data class Alert(
    val threshold: Int,
    val crossOnEpochDay: Long,
    /** Units per day that keep the month at or under the threshold. */
    val safePerDay: Double,
    /** How much more the projected month costs than staying exactly at the threshold. */
    val extraCost: Double,
    val isSubsidyLimit: Boolean,
)

data class Projection(
    val unitsSoFar: Double,
    val daysElapsed: Int,
    val perDay: Double,
    val daysLeft: Int,
    val projectedUnits: Double,
    val billSoFar: Bill,
    val projectedBill: Bill,
    val alert: Alert?,
    val subsidyAlreadyLost: Boolean,
)

object Projector {
    fun project(start: Reading, latest: Reading, cycleDays: Int, tariff: Tariff): Projection {
        val units = (latest.value - start.value).coerceAtLeast(0.0)
        val elapsed = (latest.epochDay - start.epochDay).toInt().coerceAtLeast(0)
        val perDay = if (elapsed > 0) units / elapsed else 0.0
        val daysLeft = (cycleDays - elapsed).coerceAtLeast(0)
        val projected = units + perDay * daysLeft

        val crossed = tariff.thresholds().filter { t -> units <= t && projected > t }
        // The subsidy limit matters most (crossing it can add hundreds of rupees at once).
        val pick = crossed.firstOrNull { tariff.subsidyEnabled && it == tariff.subsidyLimit } ?: crossed.firstOrNull()
        val alert = pick?.let { t ->
            val daysToCross = if (perDay > 0) ceil((t - units) / perDay).toLong().coerceAtLeast(1) else daysLeft.toLong()
            Alert(
                threshold = t,
                crossOnEpochDay = latest.epochDay + daysToCross,
                safePerDay = if (daysLeft > 0) (t - units) / daysLeft else 0.0,
                extraCost = BillCalculator.bill(projected, tariff).total - BillCalculator.bill(t.toDouble(), tariff).total,
                isSubsidyLimit = tariff.subsidyEnabled && t == tariff.subsidyLimit,
            )
        }
        return Projection(
            unitsSoFar = units,
            daysElapsed = elapsed,
            perDay = perDay,
            daysLeft = daysLeft,
            projectedUnits = projected,
            billSoFar = BillCalculator.bill(units, tariff),
            projectedBill = BillCalculator.bill(projected, tariff),
            alert = alert,
            subsidyAlreadyLost = tariff.subsidyEnabled && units > tariff.subsidyLimit,
        )
    }
}

/** A tenant on a sub-meter, billed by the landlord at a flat rate per unit. */
data class Tenant(
    val id: String,
    val name: String,
    val phone: String,
    val previous: Double,
    val current: Double,
    val rate: Double,
    val fixedShare: Double,
) {
    val units: Double get() = (current - previous).coerceAtLeast(0.0)
    val amount: Double get() = units * rate + fixedShare

    fun billMessage(month: String): String = buildString {
        appendLine("Electricity bill – $month")
        appendLine("Name: $name")
        appendLine("Meter: ${fmt(previous)} → ${fmt(current)} = ${fmt(units)} units")
        appendLine("Rate: ₹${fmt(rate)} per unit")
        if (fixedShare > 0) appendLine("Fixed charge share: ₹${fmt(fixedShare)}")
        append("Total: ₹${String.format(Locale.ENGLISH, "%,.0f", amount)}")
    }

    private fun fmt(v: Double): String =
        if (v == Math.floor(v)) String.format(Locale.ENGLISH, "%.0f", v) else String.format(Locale.ENGLISH, "%.2f", v)
}
