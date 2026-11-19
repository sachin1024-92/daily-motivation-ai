package io.github.sachin102492.safeshare

import android.content.ClipData
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.core.content.FileProvider
import androidx.exifinterface.media.ExifInterface
import com.google.android.gms.common.api.OptionalModuleApi
import com.google.android.gms.common.moduleinstall.ModuleInstall
import com.google.android.gms.common.moduleinstall.ModuleInstallRequest
import com.google.android.gms.tasks.Task
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import kotlinx.coroutines.delay
import kotlinx.coroutines.suspendCancellableCoroutine
import java.io.File
import java.io.FileOutputStream
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.math.hypot

object ImageTools {
    private const val MAX_DIMENSION = 2400

    /** Decodes a picked/shared photo, downsized and turned upright using its EXIF orientation. */
    fun load(context: Context, uri: Uri): Bitmap? {
        val resolver = context.contentResolver
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        // A bounds-only decode always returns null, so read the sizes from the options instead.
        val probe = resolver.openInputStream(uri) ?: return null
        probe.use { BitmapFactory.decodeStream(it, null, bounds) }
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        var sample = 1
        while (bounds.outWidth / sample > MAX_DIMENSION || bounds.outHeight / sample > MAX_DIMENSION) sample *= 2
        val options = BitmapFactory.Options().apply { inSampleSize = sample }
        val raw = resolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, options) } ?: return null
        val orientation = try {
            resolver.openInputStream(uri)?.use {
                ExifInterface(it).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
            } ?: ExifInterface.ORIENTATION_NORMAL
        } catch (e: Exception) {
            ExifInterface.ORIENTATION_NORMAL
        }
        val degrees = when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> 90f
            ExifInterface.ORIENTATION_ROTATE_180 -> 180f
            ExifInterface.ORIENTATION_ROTATE_270 -> 270f
            else -> 0f
        }
        if (degrees == 0f) return raw
        val rotated = Bitmap.createBitmap(raw, 0, 0, raw.width, raw.height, Matrix().apply { postRotate(degrees) }, true)
        if (rotated != raw) raw.recycle()
        return rotated
    }

    /**
     * Burns the black boxes and the watermark into a fresh copy. The output is re-encoded from
     * pixels, so the original photo's EXIF data (including GPS location) is not carried over.
     */
    fun render(source: Bitmap, masks: List<Mask>, watermark: String): Bitmap {
        val out = source.copy(Bitmap.Config.ARGB_8888, true)
        val canvas = Canvas(out)
        val black = Paint().apply { color = Color.BLACK; style = Paint.Style.FILL }
        val pad = (out.width / 250).coerceAtLeast(3)
        masks.forEach { m ->
            val b = m.box.padded(pad)
            canvas.drawRect(b.left.toFloat(), b.top.toFloat(), b.right.toFloat(), b.bottom.toFloat(), black)
        }
        if (watermark.isNotBlank()) drawWatermark(canvas, out.width, out.height, watermark)
        return out
    }

    private fun drawWatermark(canvas: Canvas, w: Int, h: Int, text: String) {
        val size = (minOf(w, h) / 20f).coerceAtLeast(16f)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(115, 200, 0, 0)
            textSize = size
            typeface = Typeface.DEFAULT_BOLD
        }
        val stepX = paint.measureText(text) + size * 2
        val stepY = size * 3.4f
        val reach = hypot(w.toFloat(), h.toFloat())
        canvas.save()
        canvas.rotate(-30f, w / 2f, h / 2f)
        var y = h / 2f - reach
        var row = 0
        while (y < h / 2f + reach) {
            var x = w / 2f - reach + if (row % 2 == 1) stepX / 2 else 0f
            while (x < w / 2f + reach) {
                canvas.drawText(text, x, y, paint)
                x += stepX
            }
            y += stepY
            row++
        }
        canvas.restore()

        // A clear strip along the bottom edge, so the purpose stays readable even if cropped.
        val footer = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE; textSize = size * 0.75f }
        val bandHeight = footer.textSize * 1.9f
        canvas.drawRect(0f, h - bandHeight, w.toFloat(), h.toFloat(), Paint().apply { color = Color.argb(185, 0, 0, 0) })
        canvas.drawText(text, size * 0.5f, h - bandHeight * 0.32f, footer)
    }

    /** Writes the protected copy to app cache and returns a content:// Uri other apps can read. */
    fun saveForSharing(context: Context, bitmap: Bitmap): Uri {
        val dir = File(context.cacheDir, "shared").apply { mkdirs() }
        dir.listFiles()?.forEach { it.delete() } // keep only the latest copy
        val file = File(dir, "safeshare_${System.currentTimeMillis()}.jpg")
        FileOutputStream(file).use { bitmap.compress(Bitmap.CompressFormat.JPEG, 90, it) }
        return FileProvider.getUriForFile(context, "${context.packageName}.files", file)
    }

    fun shareImage(context: Context, uri: Uri) {
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "image/jpeg"
            putExtra(Intent.EXTRA_STREAM, uri)
            clipData = ClipData.newRawUri("", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        context.startActivity(Intent.createChooser(send, "Send protected copy"))
    }

    /** Saves to Pictures/SafeShare. Android 10+ only (no storage permission needed there). */
    fun saveToGallery(context: Context, bitmap: Bitmap): Boolean {
        if (Build.VERSION.SDK_INT < 29) return false
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "SafeShare_${System.currentTimeMillis()}.jpg")
            put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/SafeShare")
        }
        val resolver = context.contentResolver
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return false
        return resolver.openOutputStream(uri)?.use { bitmap.compress(Bitmap.CompressFormat.JPEG, 90, it) } ?: false
    }

    /** Removes old protected copies left in the cache. */
    fun clearCache(context: Context) {
        File(context.cacheDir, "shared").listFiles()?.forEach { it.delete() }
    }
}

data class Detection(val masks: List<Mask>, val note: String?)

/**
 * Reads the photo with Google's on-device ML Kit (via Google Play services). The image never
 * leaves the phone. The reader is downloaded once by Play services; until then, detection
 * reports a note and the user can still hide areas by hand.
 */
object IdDetector {
    /**
     * [onStatus] reports progress while Google Play services fetches the readers the first time
     * (for apps not installed from the Play Store, that only starts when the app asks for it).
     */
    suspend fun detect(context: Context, bitmap: Bitmap, onStatus: (String) -> Unit = {}): Detection {
        val image = InputImage.fromBitmap(bitmap, 0)
        val masks = mutableListOf<Mask>()
        var note: String? = null
        val reader = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        val scanner = BarcodeScanning.getClient(
            BarcodeScannerOptions.Builder().setBarcodeFormats(Barcode.FORMAT_QR_CODE).build(),
        )
        try {
            if (!ensureReaders(context, reader, scanner, onStatus)) {
                return Detection(
                    emptyList(),
                    "The on-device reader isn't ready yet (Google Play services downloads it once and needs internet). " +
                        "You can still hide parts by hand with \"Hide more\", or go back and try again in a minute.",
                )
            }
            try {
                val text = reader.process(image).await()
                val lines = text.textBlocks.flatMap { block ->
                    block.lines.map { line ->
                        Line(
                            line.elements.mapNotNull { e ->
                                e.boundingBox?.let { r -> Word(e.text, Box(r.left, r.top, r.right, r.bottom)) }
                            },
                        )
                    }
                }
                masks += IdMasker.findNumberMasks(lines)
            } catch (e: Exception) {
                note = "The ID number couldn't be read automatically. Hide it by hand with \"Hide more\"."
            }
            try {
                scanner.process(image).await().forEach { code ->
                    code.boundingBox?.let { r -> masks += Mask(Box(r.left, r.top, r.right, r.bottom).padded(6), MaskKind.QR_CODE) }
                }
            } catch (e: Exception) {
                if (note == null) note = "QR codes couldn't be checked automatically. Hide them by hand if needed."
            }
        } finally {
            reader.close()
            scanner.close()
        }
        return Detection(masks, note)
    }

    /** Makes sure Google Play services has the text and QR readers, asking for them if needed. */
    private suspend fun ensureReaders(
        context: Context,
        reader: OptionalModuleApi,
        scanner: OptionalModuleApi,
        onStatus: (String) -> Unit,
    ): Boolean {
        val client = ModuleInstall.getClient(context)
        return try {
            if (client.areModulesAvailable(reader, scanner).await().areModulesAvailable()) return true
            onStatus("Getting the on-device reader ready (one time only)…")
            client.installModules(ModuleInstallRequest.newBuilder().addApi(reader).addApi(scanner).build()).await()
            repeat(45) {
                delay(2_000)
                if (client.areModulesAvailable(reader, scanner).await().areModulesAvailable()) return true
            }
            false
        } catch (e: Exception) {
            false
        }
    }

    private suspend fun <T> Task<T>.await(): T = suspendCancellableCoroutine { cont ->
        addOnSuccessListener { cont.resume(it) }
        addOnFailureListener { cont.resumeWithException(it) }
        addOnCanceledListener { cont.cancel() }
    }
}
