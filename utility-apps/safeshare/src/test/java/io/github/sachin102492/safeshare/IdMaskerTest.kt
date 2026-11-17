package io.github.sachin102492.safeshare

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class IdMaskerTest {
    /** Lays words out left to right, 100 px wide each, on one line. */
    private fun line(vararg words: String, y: Int = 0): Line =
        Line(words.mapIndexed { i, t -> Word(t, Box(i * 110, y, i * 110 + 100, y + 30)) })

    @Test fun aadhaarHidesFirstEightDigits() {
        val masks = IdMasker.findNumberMasks(listOf(line("1234", "5678", "9012")))
        assertEquals(2, masks.size)
        assertEquals(Box(0, 0, 100, 30), masks[0].box)
        assertEquals(Box(110, 0, 210, 30), masks[1].box)
        assertTrue(masks.all { it.kind == MaskKind.ID_NUMBER })
    }

    @Test fun aadhaarAfterALabelOnTheSameLine() {
        val masks = IdMasker.findNumberMasks(listOf(line("Aadhaar", "No:", "2345", "6789", "0123")))
        assertEquals(listOf(220, 330), masks.map { it.box.left })
    }

    @Test fun virtualIdHidesFirstTwelveDigits() {
        val masks = IdMasker.findNumberMasks(listOf(line("VID", ":", "9123", "4567", "8901", "2345")))
        assertEquals(3, masks.size)
    }

    @Test fun numberWithoutSpacesKeepsLastFourDigits() {
        val masks = IdMasker.findNumberMasks(listOf(Line(listOf(Word("123456789012", Box(0, 0, 120, 20))))))
        assertEquals(1, masks.size)
        assertEquals(Box(0, 0, 80, 20), masks[0].box)
    }

    @Test fun readerConfusionsAreTolerated() {
        val masks = IdMasker.findNumberMasks(listOf(line("12O4", "5678", "9Ol2")))
        assertEquals(2, masks.size)
    }

    @Test fun otherNumbersAreLeftAlone() {
        val lines = listOf(
            line("Mobile:", "98765", "43210"),
            line("DOB:", "12/04/1990"),
            line("PIN", "452001"),
            line("1234", "5678"),
            line("XXXX", "XXXX", "9012"),
            line("Year", "2019"),
        )
        assertEquals(0, IdMasker.findNumberMasks(lines).size)
    }

    @Test fun twoCardsOnOnePhotoAreBothMasked() {
        val masks = IdMasker.findNumberMasks(listOf(line("1111", "2222", "3333"), line("4444", "5555", "6666", y = 400)))
        assertEquals(4, masks.size)
    }

    @Test fun tapFindsTopmostMask() {
        val masks = listOf(Mask(Box(0, 0, 100, 100), MaskKind.ID_NUMBER), Mask(Box(50, 50, 150, 150), MaskKind.MANUAL))
        assertEquals(1, IdMasker.hit(masks, 60, 60))
        assertEquals(0, IdMasker.hit(masks, 10, 10))
        assertNull(IdMasker.hit(masks, 400, 400))
    }

    @Test fun watermarkNamesPurposeAndDate() {
        assertEquals(
            "Only for Hotel Raj check-in · 17 Nov 2026",
            IdMasker.watermarkText("  Hotel Raj check-in ", LocalDate.of(2026, 11, 17)),
        )
        assertEquals("Only for the stated purpose · 1 Jan 2027", IdMasker.watermarkText("", LocalDate.of(2027, 1, 1)))
    }
}
