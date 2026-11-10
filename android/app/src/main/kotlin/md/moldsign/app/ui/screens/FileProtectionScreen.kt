package md.moldsign.app.ui.screens

import md.moldsign.app.hostActivity
import android.net.Uri
import android.provider.OpenableColumns
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import md.moldsign.app.R
import md.moldsign.app.presentation.MainViewModel
import md.moldsign.core.protection.PasswordFileProtection

/** Password-only protection: the national identity card does not expose an encryption key. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FileProtectionDialog(vm: MainViewModel, initialFile: Uri? = null, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var decrypt by remember { mutableStateOf(initialFile != null) }
    var source by remember { mutableStateOf(initialFile) }
    var sourceName by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmation by remember { mutableStateOf("") }
    var busy by remember { mutableStateOf(false) }
    var output by remember { mutableStateOf<Uri?>(null) }
    var saved by remember { mutableStateOf(false) }
    var notice by remember { mutableStateOf<Int?>(null) }
    var failed by remember { mutableStateOf(false) }
    var helpExpanded by remember { mutableStateOf(false) }
    val guide = if (decrypt) R.string.protect_password_decrypt_guide else R.string.protect_password_encrypt_guide
    val help = if (decrypt) R.string.protect_password_decrypt_help else R.string.protect_password_encrypt_help
    fun displayName(uri: Uri): String = context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
        if (c.moveToFirst()) c.getString(0) else null
    } ?: "document"
    LaunchedEffect(initialFile) { initialFile?.let { sourceName = displayName(it) } }
    val captureIntent = context.hostActivity()?.intent
    LaunchedEffect(Unit) {
        if (md.moldsign.app.DemoMode.screenshotCapture(captureIntent)) {
            val scenario = captureIntent?.getStringExtra("capture_dialog") ?: ""
            if (scenario.startsWith("protect-")) {
                sourceName = if (scenario.contains("decrypt")) "Contract.pdf.symmetric.p7m" else "Contract.pdf"
                decrypt = scenario.contains("decrypt")
                if (scenario == "protect-complete" || scenario == "protect-decrypt-complete") {
                    busy = true
                    val secret = "Example-only-2026".toCharArray()
                    try {
                        val bytes = withContext(Dispatchers.IO) {
                            val encrypted = PasswordFileProtection.encrypt("Example document".toByteArray(), secret)
                            if (decrypt) try { PasswordFileProtection.decrypt(encrypted, secret) } finally { encrypted.fill(0) } else encrypted
                        }
                        sourceName = if (decrypt) "Contract.txt" + PasswordFileProtection.SUFFIX else "Contract.txt"
                        val name = if (decrypt) "decrypted-Contract.txt" else sourceName + PasswordFileProtection.SUFFIX
                        try { output = vm.saveProtectedDocument(name, bytes, decrypt) } finally { bytes.fill(0) }
                        saved = true; notice = R.string.protect_saved
                    } finally { secret.fill('\u0000'); busy = false }
                }
            }
        }
    }
    fun reset() { output = null; notice = null; failed = false; saved = false }
    fun fail() { notice = R.string.protect_error; failed = true }
    suspend fun read(uri: Uri): ByteArray = withContext(Dispatchers.IO) {
        context.contentResolver.openInputStream(uri)?.use { stream ->
            val out = java.io.ByteArrayOutputStream()
            val buffer = ByteArray(65536)
            while (true) {
                val count = stream.read(buffer)
                if (count < 0) break
                require(out.size() + count <= PasswordFileProtection.MAXIMUM_SIZE + 8192)
                out.write(buffer, 0, count)
            }
            out.toByteArray()
        } ?: error("Cannot read document")
    }
    val pickFile = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) { reset(); source = uri; sourceName = displayName(uri); password = ""; confirmation = "" }
    }
    val save = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/octet-stream")) { uri ->
        vm.saveCopy(output, uri)
    }
    val lifecycleOwner = androidx.lifecycle.compose.LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = androidx.lifecycle.LifecycleEventObserver { _, event ->
            if (event == androidx.lifecycle.Lifecycle.Event.ON_STOP) { password = ""; confirmation = "" }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }
    DisposableEffect(Unit) { onDispose { password = ""; confirmation = "" } }
    Dialog(onDismissRequest = { if (!busy) onDismiss() }, properties = DialogProperties(usePlatformDefaultWidth = false, dismissOnClickOutside = !busy, dismissOnBackPress = !busy)) {
        Surface(shape = MaterialTheme.shapes.extraLarge, modifier = Modifier.padding(16.dp).widthIn(max = 640.dp).fillMaxWidth().fillMaxHeight(.94f)) {
            Column(Modifier.imePadding().padding(20.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Outlined.Lock, null, tint = MaterialTheme.colorScheme.primary)
                    Text(stringResource(R.string.protect_title), style = MaterialTheme.typography.titleLarge, modifier = Modifier.weight(1f).padding(horizontal = 12.dp))
                    TextButton(onClick = onDismiss, enabled = !busy) {
                        Text(stringResource(if (output != null || saved) R.string.action_close else R.string.action_cancel))
                    }
                }
                Column(Modifier.weight(1f).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                        SegmentedButton(icon = {}, shape = SegmentedButtonDefaults.itemShape(0, 2), selected = !decrypt, onClick = { decrypt = false; reset(); password = ""; confirmation = "" }, enabled = !busy, label = { Text(stringResource(R.string.protect_encrypt)) })
                        SegmentedButton(icon = {}, shape = SegmentedButtonDefaults.itemShape(1, 2), selected = decrypt, onClick = { decrypt = true; reset(); password = ""; confirmation = "" }, enabled = !busy, label = { Text(stringResource(R.string.protect_decrypt)) })
                    }
                    if (!saved && output == null) {
                        Text(stringResource(R.string.protect_file_step), style = MaterialTheme.typography.titleSmall)
                        OutlinedButton(onClick = { pickFile.launch(arrayOf("*/*")) }, enabled = !busy, modifier = Modifier.fillMaxWidth()) {
                            Text(sourceName.ifEmpty { stringResource(R.string.protect_choose_file) }, modifier = Modifier.padding(vertical = 8.dp))
                        }
                        Text(stringResource(R.string.protect_access_step), style = MaterialTheme.typography.titleSmall)
                        val mismatch = !decrypt && confirmation.isNotEmpty() && password != confirmation
                        OutlinedTextField(value = password, onValueChange = { password = it; reset() }, enabled = !busy, label = { Text(stringResource(R.string.protect_password)) }, visualTransformation = PasswordVisualTransformation(), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password), singleLine = true, modifier = Modifier.fillMaxWidth())
                        if (!decrypt) OutlinedTextField(value = confirmation, onValueChange = { confirmation = it; reset() }, enabled = !busy, isError = mismatch,
                            supportingText = if (mismatch) { { Text(stringResource(R.string.protect_mismatch)) } } else null,
                            label = { Text(stringResource(R.string.protect_confirm_password)) }, visualTransformation = PasswordVisualTransformation(), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password), singleLine = true, modifier = Modifier.fillMaxWidth())
                        Text(stringResource(guide), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        TextButton(onClick = { helpExpanded = !helpExpanded }, enabled = !busy) { Text(stringResource(R.string.protect_help)) }
                        if (helpExpanded) {
                            Text(stringResource(help), style = MaterialTheme.typography.bodyMedium)
                            Text(stringResource(R.string.protect_compatibility), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    } else {
                        Icon(Icons.Outlined.CheckCircle, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(48.dp))
                        Text(if (decrypt) "decrypted-" + sourceName.removeSuffix(PasswordFileProtection.SUFFIX) else sourceName + PasswordFileProtection.SUFFIX, style = MaterialTheme.typography.titleMedium)
                    }
                    if (busy) LinearProgressIndicator(Modifier.fillMaxWidth())
                    notice?.let { Text(stringResource(it), color = if (failed) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary) }
                }
                Text(stringResource(R.string.protect_original), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(vertical = 12.dp))
                if (output != null) OutlinedButton(onClick = {
                    val name = if (decrypt) "decrypted-" + sourceName.removeSuffix(PasswordFileProtection.SUFFIX) else sourceName + PasswordFileProtection.SUFFIX
                    save.launch(name)
                }, enabled = !busy, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.action_save_as)) }
                if (saved) Button(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.action_close)) }
                else Button(enabled = !busy && source != null && password.isNotEmpty() && (decrypt || password == confirmation), modifier = Modifier.fillMaxWidth(), onClick = {
                    val uri = source ?: return@Button
                    val secret = password.toCharArray()
                    password = ""; confirmation = ""
                    scope.launch {
                        busy = true; reset()
                        try {
                            val bytes = read(uri)
                            val result = try {
                                withContext(Dispatchers.IO) {
                                    if (decrypt) PasswordFileProtection.decrypt(bytes, secret) else PasswordFileProtection.encrypt(bytes, secret)
                                }
                            } finally { bytes.fill(0) }
                            val name = if (decrypt) "decrypted-" + sourceName.removeSuffix(PasswordFileProtection.SUFFIX) else sourceName + PasswordFileProtection.SUFFIX
                            try { output = vm.saveProtectedDocument(name, result, decrypt) } finally { result.fill(0) }
                            saved = true
                            notice = R.string.protect_saved
                        } catch (_: Exception) { fail() }
                        finally { secret.fill('\u0000'); busy = false }
                    }
                }) { Text(stringResource(if (decrypt) R.string.protect_decrypt else R.string.protect_encrypt)) }
            }
        }
    }
}
