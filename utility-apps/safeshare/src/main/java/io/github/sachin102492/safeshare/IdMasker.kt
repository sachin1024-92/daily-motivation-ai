package io.github.sachin102492.safeshare

import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

data class Box(val left: Int, val top: Int, val right: Int, val bottom: Int) {
    val width: Int get() = right - left
    val height: Int get() = bottom - top
    fun contains(x: Int, y: Int): Boolean = x in left..right && y in top..bottom
    fun padded(p: Int): Box = Box(left - p, top - p, right + p, bottom + p)
}

/** One word found by the on-device text reader, with its position in the image. */
data class Word(val text: String, val box: Box)

/** Words in reading order on one printed line. */
data class Line(val words: List<Word>)

enum class MaskKind { ID_NUMBER, QR_CODE, MANUAL }

data class Mask(val box: Box, val kind: MaskKind)

/**
 * Finds ID numbers that should be hidden before an ID photo is shared.
 *
 * Aadhaar numbers are printed as three groups of four digits ("1234 5678 9012"); UIDAI's
 * "masked Aadhaar" format hides the first eight digits, so those two groups are masked and the
 * last four stay readable. A 16-digit Virtual ID is printed as four groups; the first twelve
 * digits are hidden. A number printed without spaces is masked except its last four digits.
 *
 * Pure Kotlin with no Android code, so it is unit-tested on the JVM.
 */
object IdMasker {
    /** Letters the text reader commonly confuses with digits on printed cards. */
    private val confusions = mapOf(
        'O' to '0', 'o' to '0', 'D' to '0', 'Q' to '0',
        'I' to '1', 'l' to '1', 'i' to '1', '|' to '1',
        'S' to '5', 'B' to '8', 'Z' to '2',
    )

    fun normalise(token: String): String =
        token.trim().map { confusions[it] ?: it }.joinToString("").trimEnd('.', ',', ':', ';')

    private fun isGroupOf4(token: String): Boolean {
        val n = normalise(token)
        return n.length == 4 && n.all { it.isDigit() }
    }

    fun findNumberMasks(lines: List<Line>): List<Mask> {
        val masks = mutableListOf<Mask>()
        for (line in lines) {
            val w = line.words
            var i = 0
            while (i < w.size) {
                if (isGroupOf4(w[i].text)) {
                    var j = i
                    while (j < w.size && isGroupOf4(w[j].text)) j++
                    val run = j - i
                    if (run == 3 || run == 4) {
                        // Hide every group except the last one.
                        for (k in i until j - 1) masks += Mask(w[k].box, MaskKind.ID_NUMBER)
                    }
                    i = j
                } else {
                    val digits = normalise(w[i].text)
                    if ((digits.length == 12 || digits.length == 16) && digits.all { it.isDigit() }) {
                        val b = w[i].box
                        val keep = (b.width * 4.0 / digits.length).toInt()
                        masks += Mask(Box(b.left, b.top, b.right - keep, b.bottom), MaskKind.ID_NUMBER)
                    }
                    i++
                }
            }
        }
        return masks
    }

    /** Returns the indices of masks that contain the tapped point, topmost (last) first. */
    fun hit(masks: List<Mask>, x: Int, y: Int): Int? = masks.indices.lastOrNull { masks[it].box.contains(x, y) }

    fun watermarkText(purpose: String, date: LocalDate): String {
        val what = purpose.trim().ifEmpty { "the stated purpose" }
        return "Only for $what · ${date.format(DateTimeFormatter.ofPattern("d MMM yyyy", Locale.ENGLISH))}"
    }
}
