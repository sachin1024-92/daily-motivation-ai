package io.github.sachin102492.seeti

import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.log10
import kotlin.math.sin
import kotlin.math.sqrt

enum class Sensitivity(val label: String) { LOW("Low"), MEDIUM("Medium"), HIGH("High") }

/**
 * Counts pressure-cooker whistles in 16 kHz mono audio, one 1024-sample frame (64 ms) at a time.
 *
 * A frame is "whistle-like" when it is clearly louder than the room's background level AND most
 * of its energy sits in the 1.5–6.5 kHz band, where a steam whistle's hiss and pitch live (speech,
 * TV dialogue and kitchen clatter sit mostly lower). A whistle is counted once that sound lasts
 * long enough without a real break. After a counted whistle, sounds within a few seconds of its
 * end are treated as the same whistle sputtering, so one long whistle is never counted twice.
 *
 * Pure Kotlin with no Android code, so it is unit-tested on the JVM.
 */
class WhistleDetector(
    private val sampleRate: Int = 16_000,
    sensitivity: Sensitivity = Sensitivity.MEDIUM,
) {
    companion object {
        const val FRAME = 1024
        private const val BAND_LOW_HZ = 1_500.0
        private const val BAND_HIGH_HZ = 6_500.0
        private const val TOTAL_LOW_HZ = 100.0
        private const val ABSOLUTE_FLOOR_DB = -60.0
        private const val MAX_GAP_SECONDS = 0.35
        private const val REFRACTORY_SECONDS = 6.0
        private const val WARMUP_FRAMES = 8
    }

    data class Frame(
        val levelDb: Float,
        val bandRatio: Float,
        val whistleLike: Boolean,
        val newWhistle: Boolean,
    )

    private val marginDb: Double
    private val minRatio: Double
    private val minSeconds: Double

    init {
        when (sensitivity) {
            Sensitivity.LOW -> { marginDb = 18.0; minRatio = 0.70; minSeconds = 1.0 }
            Sensitivity.MEDIUM -> { marginDb = 12.0; minRatio = 0.60; minSeconds = 0.7 }
            Sensitivity.HIGH -> { marginDb = 8.0; minRatio = 0.50; minSeconds = 0.45 }
        }
    }

    private val frameSeconds = FRAME.toDouble() / sampleRate
    private val window = DoubleArray(FRAME) { 0.5 - 0.5 * cos(2.0 * PI * it / (FRAME - 1)) }
    private val re = DoubleArray(FRAME)
    private val im = DoubleArray(FRAME)
    private val bitReverse = IntArray(FRAME).also { table ->
        val bits = Integer.numberOfTrailingZeros(FRAME)
        for (i in 0 until FRAME) table[i] = Integer.reverse(i) ushr (32 - bits)
    }

    private var frames = 0
    private var noiseFloorDb = Double.NaN
    private var inRun = false
    private var runSeconds = 0.0
    private var gapSeconds = 0.0
    private var runQualified = false
    private var secondsSinceWhistleEnded = 1e9

    /** Background level the detector has learned, in dBFS (for display and tests). */
    val noiseFloor: Double get() = noiseFloorDb

    fun process(samples: ShortArray): Frame {
        require(samples.size == FRAME) { "Expected $FRAME samples, got ${samples.size}" }
        frames++

        // Loudness (dB relative to full scale).
        var sumSq = 0.0
        for (s in samples) {
            val v = s / 32768.0
            sumSq += v * v
        }
        val levelDb = 20.0 * log10(sqrt(sumSq / FRAME) + 1e-9)

        // Share of energy in the whistle band.
        for (i in 0 until FRAME) {
            re[i] = samples[i] / 32768.0 * window[i]
            im[i] = 0.0
        }
        fft()
        val binHz = sampleRate.toDouble() / FRAME
        var band = 0.0
        var total = 0.0
        for (k in 1..FRAME / 2) {
            val hz = k * binHz
            if (hz < TOTAL_LOW_HZ) continue
            val p = re[k] * re[k] + im[k] * im[k]
            total += p
            if (hz in BAND_LOW_HZ..BAND_HIGH_HZ) band += p
        }
        val ratio = if (total > 0.0) band / total else 0.0

        if (noiseFloorDb.isNaN()) noiseFloorDb = levelDb
        val warmedUp = frames > WARMUP_FRAMES
        val loudEnough = levelDb > maxOf(noiseFloorDb + marginDb, ABSOLUTE_FLOOR_DB)
        val whistleLike = warmedUp && loudEnough && ratio >= minRatio

        if (!whistleLike) {
            // Follow drops in background noise quickly and rises slowly, so a whistle never
            // drags the background estimate up.
            val alpha = if (levelDb < noiseFloorDb) 0.2 else 0.02
            noiseFloorDb = (noiseFloorDb + alpha * (levelDb - noiseFloorDb)).coerceAtLeast(-100.0)
        }

        var newWhistle = false
        secondsSinceWhistleEnded += frameSeconds
        if (whistleLike) {
            if (!inRun) {
                inRun = true
                runSeconds = 0.0
                runQualified = false
            }
            runSeconds += frameSeconds
            gapSeconds = 0.0
            if (!runQualified && runSeconds >= minSeconds) {
                runQualified = true
                if (secondsSinceWhistleEnded >= REFRACTORY_SECONDS) newWhistle = true
            }
        } else if (inRun) {
            gapSeconds += frameSeconds
            if (gapSeconds > MAX_GAP_SECONDS) {
                inRun = false
                if (runQualified) secondsSinceWhistleEnded = 0.0
            }
        }

        return Frame(levelDb.toFloat(), ratio.toFloat(), whistleLike, newWhistle)
    }

    /** In-place iterative radix-2 FFT on [re] and [im]. */
    private fun fft() {
        for (i in 0 until FRAME) {
            val j = bitReverse[i]
            if (j > i) {
                val tr = re[i]; re[i] = re[j]; re[j] = tr
                val ti = im[i]; im[i] = im[j]; im[j] = ti
            }
        }
        var size = 2
        while (size <= FRAME) {
            val half = size / 2
            val step = -2.0 * PI / size
            for (start in 0 until FRAME step size) {
                for (k in 0 until half) {
                    val angle = step * k
                    val wr = cos(angle)
                    val wi = sin(angle)
                    val a = start + k
                    val b = a + half
                    val xr = re[b] * wr - im[b] * wi
                    val xi = re[b] * wi + im[b] * wr
                    re[b] = re[a] - xr
                    im[b] = im[a] - xi
                    re[a] += xr
                    im[a] += xi
                }
            }
            size *= 2
        }
    }
}
