@file:OptIn(ExperimentalMaterial3Api::class)

package io.github.sachin102492.safeshare

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.core.content.IntentCompat
import io.github.sachin102492.core.AboutScreen
import io.github.sachin102492.core.AdsConsent
import io.github.sachin102492.core.AppScaffold
import io.github.sachin102492.core.UtilityTheme
import io.github.sachin102492.core.formatDay
import io.github.sachin102492.core.today
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.LocalDate
import kotlin.math.abs
import io.github.sachin102492.safeshare.Box as ImageBox

class MainActivity : ComponentActivity() {
    /** A photo shared into SafeShare from the gallery or WhatsApp. */
    private val incoming = mutableStateOf<Uri?>(null)
    private val demoSample = mutableStateOf(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        if (savedInstanceState == null) {
            ImageTools.clearCache(this)
            handle(intent)
        }
        AdsConsent.gather(this)
        setContent {
            UtilityTheme(seed = Color(0xFF2E7D32)) {
                SafeShareApp(
                    incoming = incoming.value,
                    demoSample = demoSample.value,
                    onIncomingHandled = { incoming.value = null; demoSample.value = false },
                )
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handle(intent)
    }

    private fun handle(intent: Intent?) {
        if (intent == null) return
        if (intent.action == Intent.ACTION_SEND) {
            incoming.value = IntentCompat.getParcelableExtra(intent, Intent.EXTRA_STREAM, Uri::class.java)
        }
        // Debug builds only: opens a bundled sample card so the emulator test can exercise the editor.
        if (BuildConfig.DEBUG && intent.getBooleanExtra("demo_sample", false)) demoSample.value = true
    }
}

@Composable
fun SafeShareApp(incoming: Uri?, demoSample: Boolean, onIncomingHandled: () -> Unit) {
    val context = LocalContext.current
    var bitmap by remember { mutableStateOf<Bitmap?>(null) }
    var loading by remember { mutableStateOf(false) }
    var showAbout by rememberSaveable { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    val open: (Uri) -> Unit = { uri ->
        loading = true
        scope.launch {
            val b = withContext(Dispatchers.IO) { runCatching { ImageTools.load(context, uri) }.getOrNull() }
            loading = false
            if (b == null) Toast.makeText(context, "Couldn't open that image.", Toast.LENGTH_LONG).show() else bitmap = b
        }
    }
    LaunchedEffect(incoming, demoSample) {
        if (incoming != null) open(incoming)
        if (demoSample) {
            bitmap = withContext(Dispatchers.IO) { context.assets.open("sample_id.png").use { BitmapFactory.decodeStream(it) } }
        }
        if (incoming != null || demoSample) onIncomingHandled()
    }

    val current = bitmap
    when {
        showAbout -> AboutScreen(
            appName = "SafeShare ID",
            versionName = BuildConfig.VERSION_NAME,
            about = "Before you send a photo of an ID card to a hotel, office or app, SafeShare hides the " +
                "ID number (keeping only the last 4 digits, like a masked Aadhaar) and the QR code, and stamps " +
                "who the copy is for and the date across it, so a leaked copy can't be reused elsewhere.",
            privacy = listOf(
                "Photos are processed entirely on your phone with Google's on-device text reader. No image is uploaded.",
                "The protected copy is saved only where you choose to send or save it. Location data in the original photo is removed.",
                "The list of who has a copy is stored only on this phone.",
                "Check the result before sending: automatic detection can miss things.",
            ),
            onBack = { showAbout = false },
        )
        current != null -> EditorScreen(current, onClose = { bitmap = null })
        else -> HomeScreen(loading = loading, onPicked = open, onAbout = { showAbout = true })
    }
}

@Composable
private fun HomeScreen(loading: Boolean, onPicked: (Uri) -> Unit, onAbout: () -> Unit) {
    val context = LocalContext.current
    val log = remember { ShareLog(context) }
    var records by remember { mutableStateOf(log.all()) }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) onPicked(uri)
    }

    AppScaffold(
        title = "SafeShare ID",
        bannerId = BuildConfig.BANNER_ID,
        actions = { IconButton(onClick = onAbout) { Icon(Icons.Default.Info, contentDescription = "About SafeShare") } },
    ) { padding ->
        LazyColumn(
            Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item {
                Card(Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text("Share ID photos safely", style = MaterialTheme.typography.titleLarge)
                        Text("1. Pick a photo of your ID card.")
                        Text("2. SafeShare hides the number (keeps the last 4 digits) and the QR code.")
                        Text("3. Type who it's for. That name and today's date are stamped across the copy.")
                        Text("Everything happens on your phone.", style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
            item {
                Button(
                    onClick = { picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)) },
                    enabled = !loading,
                    modifier = Modifier.fillMaxWidth().height(56.dp),
                ) { Text(if (loading) "Opening…" else "Choose ID photo") }
            }
            item {
                Text(
                    "Tip: in the gallery or WhatsApp, tap Share on a photo and pick SafeShare.",
                    style = MaterialTheme.typography.bodySmall,
                )
            }
            item { Text("Who has a copy", style = MaterialTheme.typography.titleMedium) }
            if (records.isEmpty()) item { Text("Copies you share will be listed here, so you remember who has one.") }
            items(records) { r ->
                Card(Modifier.fillMaxWidth()) {
                    Row(Modifier.padding(start = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f).padding(vertical = 12.dp)) {
                            Text(r.purpose, style = MaterialTheme.typography.bodyLarge)
                            Text(formatDay(r.epochDay), style = MaterialTheme.typography.bodySmall)
                        }
                        IconButton(onClick = { log.remove(r); records = log.all() }) {
                            Icon(Icons.Default.Delete, contentDescription = "Remove from list")
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun EditorScreen(bitmap: Bitmap, onClose: () -> Unit) {
    BackHandler(onBack = onClose)
    val context = LocalContext.current
    val masks = remember(bitmap) { mutableStateListOf<Mask>() }
    var detecting by remember(bitmap) { mutableStateOf(true) }
    var note by remember(bitmap) { mutableStateOf<String?>(null) }
    var drawMode by remember { mutableStateOf(false) }
    var purpose by rememberSaveable { mutableStateOf("") }
    val scope = rememberCoroutineScope()

    var status by remember(bitmap) { mutableStateOf("Looking for the ID number and QR code…") }
    LaunchedEffect(bitmap) {
        val result = IdDetector.detect(context, bitmap) { status = it }
        masks.clear()
        masks.addAll(result.masks)
        note = result.note
        detecting = false
    }

    fun finished(): Bitmap = ImageTools.render(bitmap, masks.toList(), IdMasker.watermarkText(purpose, LocalDate.now()))

    // No ads on this screen: it is for careful checking before sending.
    AppScaffold(title = "Hide & stamp", bannerId = null, onBack = onClose) { padding ->
        Column(
            Modifier.fillMaxSize().padding(padding).padding(horizontal = 12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Box(Modifier.fillMaxWidth().weight(1f), contentAlignment = Alignment.Center) {
                MaskCanvas(
                    bitmap = bitmap,
                    masks = masks,
                    drawMode = drawMode,
                    onTap = { x, y -> IdMasker.hit(masks, x, y)?.let { masks.removeAt(it) } },
                    onDrawn = { masks.add(Mask(it, MaskKind.MANUAL)) },
                )
                if (detecting) CircularProgressIndicator()
            }
            val ids = masks.count { it.kind == MaskKind.ID_NUMBER }
            val qrs = masks.count { it.kind == MaskKind.QR_CODE }
            val manual = masks.count { it.kind == MaskKind.MANUAL }
            Text(
                when {
                    detecting -> status
                    masks.isEmpty() -> "Nothing found automatically. Tap \"Hide more\" and drag over anything private."
                    else -> "Hidden: " + listOfNotNull(
                        if (ids > 0) "$ids part(s) of the ID number" else null,
                        if (qrs > 0) "$qrs QR code(s)" else null,
                        if (manual > 0) "$manual area(s) you marked" else null,
                    ).joinToString(", ") + ". Tap a box to un-hide it."
                },
                style = MaterialTheme.typography.bodyMedium,
            )
            note?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.error) }
            FilterChip(
                selected = drawMode,
                onClick = { drawMode = !drawMode },
                label = { Text(if (drawMode) "Drawing: drag over anything to hide" else "Hide more") },
            )
            OutlinedTextField(
                value = purpose,
                onValueChange = { purpose = it.take(60) },
                label = { Text("Only for… (e.g. Hotel Raj check-in)") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
            Row(Modifier.fillMaxWidth().padding(bottom = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedButton(
                    onClick = {
                        scope.launch {
                            val ok = withContext(Dispatchers.IO) { ImageTools.saveToGallery(context, finished()) }
                            Toast.makeText(
                                context,
                                if (ok) "Saved to Pictures/SafeShare" else "Saving needs Android 10 or newer. Use Send instead.",
                                Toast.LENGTH_LONG,
                            ).show()
                        }
                    },
                    enabled = !detecting,
                    modifier = Modifier.weight(1f),
                ) { Text("Save copy") }
                Button(
                    onClick = {
                        scope.launch {
                            val uri = withContext(Dispatchers.IO) { ImageTools.saveForSharing(context, finished()) }
                            ShareLog(context).add(ShareRecord(today(), purpose.trim().ifEmpty { "Unnamed" }))
                            ImageTools.shareImage(context, uri)
                        }
                    },
                    enabled = !detecting,
                    modifier = Modifier.weight(1f),
                ) { Text("Send copy") }
            }
        }
    }
}

/** Shows the photo with mask boxes; tap a box to remove it, or drag (in draw mode) to add one. */
@Composable
private fun MaskCanvas(
    bitmap: Bitmap,
    masks: List<Mask>,
    drawMode: Boolean,
    onTap: (Int, Int) -> Unit,
    onDrawn: (ImageBox) -> Unit,
) {
    val image = remember(bitmap) { bitmap.asImageBitmap() }
    var dragStart by remember { mutableStateOf<Offset?>(null) }
    var dragNow by remember { mutableStateOf<Offset?>(null) }
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val cw = constraints.maxWidth.toFloat()
        val ch = constraints.maxHeight.toFloat()
        val scale = minOf(cw / bitmap.width, ch / bitmap.height)
        val dw = bitmap.width * scale
        val dh = bitmap.height * scale
        val ox = (cw - dw) / 2f
        val oy = (ch - dh) / 2f

        fun toImage(o: Offset): Pair<Int, Int> = Pair(
            ((o.x - ox) / scale).toInt().coerceIn(0, bitmap.width),
            ((o.y - oy) / scale).toInt().coerceIn(0, bitmap.height),
        )

        Canvas(
            Modifier
                .fillMaxSize()
                .pointerInput(drawMode, bitmap, cw, ch) {
                    if (drawMode) {
                        detectDragGestures(
                            onDragStart = { dragStart = it; dragNow = it },
                            onDrag = { change, _ ->
                                change.consume()
                                dragNow = change.position
                            },
                            onDragEnd = {
                                val s = dragStart
                                val n = dragNow
                                if (s != null && n != null) {
                                    val (x1, y1) = toImage(s)
                                    val (x2, y2) = toImage(n)
                                    if (abs(x2 - x1) > 8 && abs(y2 - y1) > 8) {
                                        onDrawn(ImageBox(minOf(x1, x2), minOf(y1, y2), maxOf(x1, x2), maxOf(y1, y2)))
                                    }
                                }
                                dragStart = null
                                dragNow = null
                            },
                            onDragCancel = { dragStart = null; dragNow = null },
                        )
                    } else {
                        detectTapGestures(onTap = { o ->
                            val (x, y) = toImage(o)
                            onTap(x, y)
                        })
                    }
                },
        ) {
            drawImage(
                image = image,
                dstOffset = IntOffset(ox.toInt(), oy.toInt()),
                dstSize = IntSize(dw.toInt(), dh.toInt()),
            )
            masks.forEach { m ->
                val topLeft = Offset(ox + m.box.left * scale, oy + m.box.top * scale)
                val size = Size(m.box.width * scale, m.box.height * scale)
                drawRect(Color.Black.copy(alpha = 0.85f), topLeft = topLeft, size = size)
                drawRect(
                    if (m.kind == MaskKind.MANUAL) Color(0xFFFF9800) else Color(0xFF4CAF50),
                    topLeft = topLeft,
                    size = size,
                    style = Stroke(width = 2.dp.toPx()),
                )
            }
            val s = dragStart
            val n = dragNow
            if (s != null && n != null) {
                drawRect(
                    Color.Red.copy(alpha = 0.35f),
                    topLeft = Offset(minOf(s.x, n.x), minOf(s.y, n.y)),
                    size = Size(abs(n.x - s.x), abs(n.y - s.y)),
                )
            }
        }
    }
}
