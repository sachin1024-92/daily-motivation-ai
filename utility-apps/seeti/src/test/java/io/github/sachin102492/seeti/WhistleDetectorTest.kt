package io.github.sachin102492.seeti

import org.junit.Assert.assertEquals
import org.junit.Test
import kotlin.math.PI
import kotlin.math.sin
import kotlin.random.Random

/** Feeds synthetic kitchen audio to the detector and checks the whistle count. */
class WhistleDetectorTest {

    private val rate = 16_000

    /** Builds audio from (seconds, generator) segments; generator gets the sample index. */
    private class Audio(private val rate: Int, seed: Int = 7) {
        private val random = Random(seed)
        val samples = ArrayList<Double>()
        private var t = 0L

        fun quiet(seconds: Double, noise: Double = 0.004) = add(seconds) { 0.0 + noise * (random.nextDouble() * 2 - 1) }

        fun tone(seconds: Double, hz: Double, amp: Double, noise: Double = 0.004) = add(seconds) {
            amp * sin(2 * PI * hz * it / rate) + noise * (random.nextDouble() * 2 - 1)
        }

        /** Steam-like hiss: several random-phase tones spread over 2–5 kHz plus a pitch at 3.2 kHz. */
        fun hiss(seconds: Double, amp: Double) {
            val freqs = DoubleArray(12) { 2_000.0 + it * 250.0 }
            val phases = DoubleArray(12) { random.nextDouble() * 2 * PI }
            add(seconds) { n ->
                var v = 0.5 * sin(2 * PI * 3_200.0 * n / rate)
                for (i in freqs.indices) v += 0.12 * sin(2 * PI * freqs[i] * n / rate + phases[i])
                amp * v / 2.0 + 0.004 * (random.nextDouble() * 2 - 1)
            }
        }

        /** Voice-like sound: 180 Hz fundamental with falling harmonics, all below ~1.3 kHz. */
        fun voice(seconds: Double, amp: Double) = add(seconds) { n ->
            var v = 0.0
            for (h in 1..7) v += sin(2 * PI * 180.0 * h * n / rate) / h
            amp * v / 2.0
        }

        private fun add(seconds: Double, gen: (Long) -> Double) {
            val n = (seconds * rate).toLong()
            repeat(n.toInt()) { samples += gen(t++) }
        }
    }

    private fun count(audio: Audio, sensitivity: Sensitivity = Sensitivity.MEDIUM): Int {
        val d = WhistleDetector(rate, sensitivity)
        val frame = ShortArray(WhistleDetector.FRAME)
        var whistles = 0
        var i = 0
        while (i + WhistleDetector.FRAME <= audio.samples.size) {
            for (k in 0 until WhistleDetector.FRAME) {
                frame[k] = (audio.samples[i + k].coerceIn(-1.0, 1.0) * 32767).toInt().toShort()
            }
            if (d.process(frame).newWhistle) whistles++
            i += WhistleDetector.FRAME
        }
        return whistles
    }

    @Test fun silenceCountsNothing() {
        val a = Audio(rate).apply { quiet(20.0) }
        assertEquals(0, count(a))
    }

    @Test fun oneWhistleCountsOnce() {
        val a = Audio(rate).apply { quiet(3.0); hiss(2.5, 0.4); quiet(5.0) }
        assertEquals(1, count(a))
    }

    @Test fun pureHighToneCountsOnce() {
        val a = Audio(rate).apply { quiet(3.0); tone(2.0, 3_000.0, 0.3); quiet(4.0) }
        assertEquals(1, count(a))
    }

    @Test fun threeWhistlesCountThree() {
        val a = Audio(rate).apply {
            quiet(3.0)
            repeat(3) { hiss(2.0, 0.4); quiet(15.0) }
        }
        assertEquals(3, count(a))
    }

    @Test fun longWhistleWithSputterCountsOnce() {
        val a = Audio(rate).apply { quiet(3.0); hiss(2.0, 0.4); quiet(0.6); hiss(2.0, 0.4); quiet(4.0) }
        assertEquals(1, count(a))
    }

    @Test fun talkingIsIgnored() {
        val a = Audio(rate).apply { quiet(3.0); voice(8.0, 0.5); quiet(3.0) }
        assertEquals(0, count(a))
    }

    @Test fun shortBeepsAreIgnored() {
        // Microwave-style 0.2 s beeps once a second.
        val a = Audio(rate).apply {
            quiet(3.0)
            repeat(8) { tone(0.2, 3_000.0, 0.3); quiet(0.8) }
            quiet(3.0)
        }
        assertEquals(0, count(a))
    }

    @Test fun distantWhistleNeedsHighSensitivity() {
        val a = Audio(rate).apply { quiet(3.0, 0.002); hiss(2.0, 0.02); quiet(4.0, 0.002) }
        assertEquals(1, count(a, Sensitivity.HIGH))
    }

    @Test fun whistleOverTalkingStillCounts() {
        val a = Audio(rate).apply { quiet(3.0); voice(3.0, 0.05); hiss(2.5, 0.5); voice(3.0, 0.05) }
        assertEquals(1, count(a))
    }
}
