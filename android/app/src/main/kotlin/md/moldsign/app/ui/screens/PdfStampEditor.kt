package md.moldsign.app.ui.screens

import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import androidx.compose.foundation.pager.VerticalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.selection.selectable
import androidx.compose.ui.semantics.Role
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import kotlinx.coroutines.launch
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.Image
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import md.moldsign.app.R
import md.moldsign.app.application.SignItem
import md.moldsign.core.PdfStampPlacement
import java.io.File
import kotlin.math.roundToInt

/** Uses Android's PDF renderer on a private temporary copy. The picked document is never changed. */
@Composable
fun PdfStampEditor(item: SignItem, holder: String, onDismiss: () -> Unit, onSave: (PdfStampPlacement?) -> Unit, requester: String? = null, onBatch: ((PdfStampPlacement?) -> Unit)? = null) {
    val context = LocalContext.current
    var placement by remember(item.doc.uri) { mutableStateOf(item.stamp ?: PdfStampPlacement()) }
    var enabled by remember(item.doc.uri) { mutableStateOf(true) }
    var applyToQueue by remember { mutableStateOf(false) }
    var file by remember { mutableStateOf<File?>(null) }
    var count by remember { mutableIntStateOf(0) }
    val pager = rememberPagerState(initialPage = item.stamp?.page ?: 0, pageCount = { maxOf(count, 1) })
    val scope = rememberCoroutineScope()
    LaunchedEffect(pager.currentPage, count) {
        if (count > 0) placement = placement.copy(page = pager.currentPage)
    }
    var error by remember { mutableStateOf<String?>(null) }
    DisposableEffect(item.doc.uri) { onDispose { file?.delete() } }
    LaunchedEffect(item.doc.uri) {
        var temp: File? = null
        try {
            val loaded = withContext(Dispatchers.IO) {
                val copy = File.createTempFile("pdf-preview-", ".pdf", context.cacheDir)
                temp = copy
                context.contentResolver.openInputStream(item.doc.uri).use { source ->
                    requireNotNull(source); copy.outputStream().use { source.copyTo(it) }
                }
                val pages = PdfRenderer(ParcelFileDescriptor.open(copy, ParcelFileDescriptor.MODE_READ_ONLY)).use { it.pageCount }
                copy to pages
            }
            val digest = withContext(Dispatchers.IO) { java.security.MessageDigest.getInstance("SHA-256").digest(loaded.first.readBytes()).joinToString("") { "%02x".format(it) } }
            placement = placement.copy(documentSHA256 = digest)
            file = loaded.first; count = loaded.second
        } catch (e: CancellationException) { temp?.delete(); throw e }
        catch (e: Exception) { temp?.delete(); error = e.localizedMessage }
    }
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Surface(Modifier.fillMaxSize()) {
            BoxWithConstraints(Modifier.fillMaxSize().safeDrawingPadding().padding(16.dp)) {
                val landscape = maxWidth > maxHeight && maxHeight < 480.dp
                val preview: @Composable (Modifier) -> Unit = { modifier ->
                VerticalPager(state = pager, modifier = modifier) { pageIndex ->
                    var bitmap by remember(file, pageIndex) { mutableStateOf<Bitmap?>(null) }
                    LaunchedEffect(file, pageIndex) {
        val source = file ?: return@LaunchedEffect
        bitmap = null
        try {
            bitmap = withContext(Dispatchers.IO) {
                PdfRenderer(ParcelFileDescriptor.open(source, ParcelFileDescriptor.MODE_READ_ONLY)).use { renderer ->
                    renderer.openPage(pageIndex).use { page ->
                        val scale = minOf(1200.0 / page.width, 1600.0 / page.height)
                        val image = Bitmap.createBitmap(maxOf(1, (page.width * scale).toInt()), maxOf(1, (page.height * scale).toInt()), Bitmap.Config.ARGB_8888)
                        image.eraseColor(android.graphics.Color.WHITE)
                        page.render(image, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                        image
                    }
                }
            }
        } catch (e: CancellationException) { throw e }
        catch (e: Exception) { error = e.localizedMessage }
    }
                BoxWithConstraints(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    bitmap?.let { image ->
                        val ratio = image.width.toFloat() / image.height
                        val width = minOf(maxWidth, maxHeight * ratio)
                        val height = width / ratio
                        val density = LocalDensity.current
                        val pixelWidth = with(density) { width.toPx() }; val pixelHeight = with(density) { height.toPx() }
                        val move: (androidx.compose.ui.geometry.Offset) -> Unit = { point ->
                            if (enabled) placement = placement.copy(
                                x = (point.x / pixelWidth - placement.width/2).coerceIn(0.0, 1-placement.width),
                                y = (point.y / pixelHeight - placement.height/2).coerceIn(0.0, 1-placement.height))
                        }
                        Box(Modifier.size(width, height)
                            .pointerInput(enabled, pixelWidth, pixelHeight) { detectTapGestures(onTap = move) }) {
                            Image(image.asImageBitmap(), stringResource(R.string.stamp_move_hint), Modifier.fillMaxSize())
                            if (enabled) Box(Modifier.offset { IntOffset((pixelWidth*placement.x).roundToInt(), (pixelHeight*placement.y).roundToInt()) }
                                .size(width * placement.width.toFloat(), height * placement.height.toFloat())
                                .pointerInput(enabled, pixelWidth, pixelHeight) {
                                    detectDragGestures { change, drag ->
                                        change.consume()
                                        placement = placement.copy(
                                            x = (placement.x + drag.x/pixelWidth).coerceIn(0.0, 1-placement.width),
                                            y = (placement.y + drag.y/pixelHeight).coerceIn(0.0, 1-placement.height))
                                    }
                                }
                                .border(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = .65f)), contentAlignment = Alignment.Center) {
                                Canvas(Modifier.fillMaxSize()) {
                                    val canvas = drawContext.canvas.nativeCanvas
                                    canvas.save()
                                    canvas.scale(size.width / 240f, size.height / 96f)
                                    val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
                                        color = android.graphics.Color.GRAY; style = android.graphics.Paint.Style.STROKE; strokeWidth = .5f
                                    }
                                    canvas.drawRect(.5f,65f,174.5f,86f,paint)
                                    paint.color = android.graphics.Color.BLACK; paint.style = android.graphics.Paint.Style.FILL
                                    paint.typeface = android.graphics.Typeface.create("serif", android.graphics.Typeface.NORMAL)
                                    val lines = listOf("Digitally signed by $holder", "Date: ${java.time.ZonedDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm:ss z"))}", "Reason: MoldSign Signature", "Location: Moldova", "MOLDOVA EUROPEANĂ", "Signed with eSemnBun")
                                    lines.forEachIndexed { index, line ->
                                        paint.textSize = if (index == 5) 7f else 13f
                                        val measured = paint.measureText(line)
                                        if (measured > 228) paint.textSize *= 228/measured
                                        canvas.drawText(line, if (index == 4) 5f else 0f, listOf(14f,29f,44f,59f,80f,94f)[index], paint)
                                    }
                                    canvas.restore()
                                }

                            }
                            if (enabled) repeat(4) { corner ->
                                val right = corner % 2 == 1; val bottom = corner >= 2
                                val targetPixels = with(density) { 48.dp.toPx() }
                                Box(Modifier.offset { IntOffset(
                                    (pixelWidth*(placement.x + if(right) placement.width else 0.0) - targetPixels/2).roundToInt(),
                                    (pixelHeight*(placement.y + if(bottom) placement.height else 0.0) - targetPixels/2).roundToInt()) }
                                    .size(48.dp)
                                    .pointerInput(corner, pixelWidth, pixelHeight) {
                                        var start = placement; var dx = 0.0; var dy = 0.0
                                        detectDragGestures(onDragStart = { start = placement; dx=0.0; dy=0.0 }) { change, drag ->
                                            change.consume(); dx += drag.x/pixelWidth; dy += drag.y/pixelHeight
                                            placement = start.resized(corner,dx,dy)
                                        }
                                    }, contentAlignment = Alignment.Center) {
                                    Box(Modifier.size(10.dp).background(MaterialTheme.colorScheme.primary, CircleShape).border(1.dp, Color.White, CircleShape))
                                }
                            }
                        }
                    } ?: if (error == null) CircularProgressIndicator() else Text(error ?: "", color = MaterialTheme.colorScheme.error)
                }
                }
                }
                val controls: @Composable () -> Unit = {
                if (landscape) {
                    requester?.let { Text(it, style = MaterialTheme.typography.bodyMedium) }
                    Text(stringResource(R.string.stamp_title), style = MaterialTheme.typography.titleLarge)
                }
                Surface(shape = MaterialTheme.shapes.medium, color = MaterialTheme.colorScheme.surfaceContainerLow) {
                    Column(Modifier.padding(horizontal = 12.dp, vertical = 4.dp)) {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
                            FilledTonalIconButton(onClick = { scope.launch { pager.animateScrollToPage(pager.currentPage-1) } }, enabled = pager.currentPage>0, modifier = Modifier.size(48.dp)) {
                                Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, stringResource(R.string.stamp_previous_page), Modifier.size(28.dp))
                            }
                            Text("${stringResource(R.string.stamp_page_label)} ${pager.currentPage+1} / $count", Modifier.padding(horizontal = 20.dp))
                            FilledTonalIconButton(onClick = { scope.launch { pager.animateScrollToPage(pager.currentPage+1) } }, enabled = pager.currentPage+1<count, modifier = Modifier.size(48.dp)) {
                                Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, stringResource(R.string.stamp_next_page), Modifier.size(28.dp))
                            }
                        }
                        SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                            val modes = listOf(R.string.stamp_off, R.string.stamp_single, R.string.stamp_every)
                            modes.forEachIndexed { index, label ->
                                SegmentedButton(
                                    selected = index == if (!enabled) 0 else if (placement.allPages) 2 else 1,
                                    onClick = { enabled = index != 0; if (index != 0) placement = placement.copy(allPages = index == 2) },
                                    shape = SegmentedButtonDefaults.itemShape(index, modes.size),
                                    icon = {}
                                ) { Text(stringResource(label), maxLines = 1) }
                            }
                        }
                        if (onBatch != null) {
                            HorizontalDivider()
                            Row(Modifier.heightIn(min=48.dp), verticalAlignment=Alignment.CenterVertically) {
                                Text(stringResource(R.string.stamp_queue), Modifier.weight(1f), style=MaterialTheme.typography.bodySmall)
                                Switch(checked=applyToQueue, onCheckedChange={ applyToQueue=it })
                            }
                        }
                    }
                }
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                    TextButton(onClick = onDismiss) { Text(stringResource(R.string.action_cancel)) }
                    TextButton(onClick = { val value = if (enabled) placement else null; onSave(value); if (applyToQueue) onBatch?.invoke(value) }, enabled = !enabled || count > 0 && error == null) { Text(stringResource(R.string.stamp_save)) }
                }
                }
                if (landscape) {
                    Row(Modifier.fillMaxSize(), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                        preview(Modifier.weight(1f).fillMaxHeight())
                        Column(Modifier.width(280.dp).fillMaxHeight().verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(8.dp)) { controls() }
                    }
                } else {
                    Column(Modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        requester?.let { Text(it, style = MaterialTheme.typography.bodyMedium) }
                        Text(stringResource(R.string.stamp_title), style = MaterialTheme.typography.titleLarge)
                        preview(Modifier.fillMaxWidth().weight(1f))
                        controls()
                    }
                }
            }
        }
    }
}
