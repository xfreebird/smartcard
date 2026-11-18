package md.moldsign.app.ui.screens

import md.moldsign.app.hostActivity
import android.net.Uri
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
import kotlinx.coroutines.launch
import md.moldsign.app.R
import md.moldsign.app.presentation.MainViewModel
import md.moldsign.core.protection.PasswordFileProtection
import md.moldsign.core.protection.CertificateFileProtection
import md.moldsign.core.protection.CardEncryptionIdentity
import md.moldsign.core.protection.ProtectionHeader
import md.moldsign.core.CertificateSummary
import md.moldsign.core.CardError
import md.moldsign.app.presentation.errorText
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FileProtectionDialog(vm: MainViewModel, initialFile: Uri? = null, initialDecrypt: Boolean = false, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var decrypt by remember { mutableStateOf(initialDecrypt) }
    var source by remember { mutableStateOf(initialFile) }
    var sourceName by remember { mutableStateOf("") }
    var certificateMethod by remember { mutableStateOf(false) }
    var header by remember { mutableStateOf<ProtectionHeader?>(null) }
    val rsa = if (decrypt) header?.certificate == true else certificateMethod
    var keySize by remember { mutableIntStateOf(256) }
    var recipient by remember { mutableStateOf<X509Certificate?>(null) }
    var reader by remember { mutableStateOf<String?>(null) }
    var identities by remember { mutableStateOf(emptyList<CardEncryptionIdentity>()) }
    var identity by remember { mutableStateOf<CardEncryptionIdentity?>(null) }
    var pin by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmation by remember { mutableStateOf("") }
    var busy by remember { mutableStateOf(false) }
    var output by remember { mutableStateOf<Uri?>(null) }
    var saved by remember { mutableStateOf(false) }
    var notice by remember { mutableStateOf<Int?>(null) }
    var failed by remember { mutableStateOf(false) }
    var helpExpanded by remember { mutableStateOf(false) }
    var cardError by remember { mutableStateOf<String?>(null) }
    var inspected by remember { mutableStateOf(false) }
    val suffix = if (rsa) CertificateFileProtection.SUFFIX else PasswordFileProtection.SUFFIX
    val outputName = if (decrypt) "decrypted-" + sourceName.removeSuffix(suffix) else sourceName + suffix
    val help = when {
        rsa && decrypt -> R.string.protect_certificate_decrypt_help
        rsa -> R.string.protect_certificate_encrypt_help
        decrypt -> R.string.protect_password_decrypt_help
        else -> R.string.protect_password_encrypt_help
    }
    LaunchedEffect(source) {
        source?.let { uri ->
            try {
                sourceName = vm.protectionDocumentName(uri)
                header = vm.protectionHeader(uri)
                inspected = true
            } catch (cancelled: kotlinx.coroutines.CancellationException) { throw cancelled }
            catch (_: Exception) { notice = R.string.protect_error; failed = true }
        }
    }
    val captureIntent = context.hostActivity()?.intent
    LaunchedEffect(Unit) {
        if (md.moldsign.app.DemoMode.screenshotCapture(captureIntent)) {
            val scenario = captureIntent?.getStringExtra("capture_dialog") ?: ""
            val preview = vm.protectionPreviewState(scenario)
            if (preview != null) {
                sourceName = preview.sourceName
                decrypt = preview.decrypt
                certificateMethod = preview.certificate
                if (decrypt) header = ProtectionHeader(preview.certificate, if (preview.certificate) null else 256)
                if (preview.completed) {
                    busy = true
                    try {
                        output = vm.protectionPreview(decrypt)
                        sourceName = preview.completionSourceName
                        saved = true; notice = R.string.protect_saved
                    } finally { busy = false }
                }
            }
        }
    }
    fun reset() { cardError = null; output = null; notice = null; failed = false; saved = false }
    fun clearSecrets() { password = ""; confirmation = ""; pin = "" }
    fun fail(error: Exception) {
        failed = true
        if (error is CardError) cardError = errorText(context, error) else notice = R.string.protect_error
    }
    fun selectIdentity(item: CardEncryptionIdentity) {
        identity = item
        recipient = CertificateFactory.getInstance("X.509").generateCertificate(item.certificate.inputStream()) as X509Certificate
        pin = ""
    }
    fun changeOperation(toDecrypt: Boolean) {
        if (decrypt == toDecrypt) return
        decrypt = toDecrypt
        reset()
        clearSecrets()
        recipient = null
        identity = null
        identities = emptyList()
    }
    val pickRecipient = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) scope.launch {
            reset()
            busy = true
            identity = null
            identities = emptyList()
            recipient = null
            try { recipient = vm.importRecipient(uri) }
            catch (cancelled: kotlinx.coroutines.CancellationException) { throw cancelled }
            catch (_: Exception) { notice = R.string.protect_no_key; failed = true }
            finally { busy = false }
        }
    }
    val pickFile = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) {
            reset()
            clearSecrets()
            if (source != uri) { sourceName = ""; header = null; inspected = false }
            source = uri
        }
    }
    val save = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/octet-stream")) { uri ->
        vm.saveCopy(output, uri)
    }
    val lifecycleOwner = androidx.lifecycle.compose.LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = androidx.lifecycle.LifecycleEventObserver { _, event ->
            if (event == androidx.lifecycle.Lifecycle.Event.ON_STOP) { clearSecrets() }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }
    DisposableEffect(Unit) { onDispose { clearSecrets() } }
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
                Column(Modifier.weight(1f).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                        SegmentedButton(icon = {}, shape = SegmentedButtonDefaults.itemShape(0, 2), selected = !decrypt, onClick = { changeOperation(false) }, enabled = !busy, label = { Text(stringResource(R.string.protect_encrypt)) })
                        SegmentedButton(icon = {}, shape = SegmentedButtonDefaults.itemShape(1, 2), selected = decrypt, onClick = { changeOperation(true) }, enabled = !busy, label = { Text(stringResource(R.string.protect_decrypt)) })
                    }
                    if (!saved && output == null) {
                        Text(stringResource(R.string.protect_file_step), style = MaterialTheme.typography.titleSmall)
                        OutlinedButton(onClick = { pickFile.launch(arrayOf("*/*")) }, enabled = !busy, modifier = Modifier.fillMaxWidth()) {
                            Text(sourceName.ifEmpty { stringResource(R.string.protect_choose_file) }, modifier = Modifier.padding(vertical = 8.dp))
                        }
                        Text(stringResource(R.string.protect_access_step), style = MaterialTheme.typography.titleSmall)
                        if (!decrypt) {
                            ProtectionChoices(listOf(stringResource(R.string.protect_password), stringResource(R.string.protect_rsa_recipient)),
                                if (rsa) 1 else 0, enabled = !busy) { choice ->
                                certificateMethod = choice == 1
                                clearSecrets()
                                reset()
                            }
                        } else {
                            Text(stringResource(R.string.protect_detect_algorithm), style = MaterialTheme.typography.bodyMedium)
                            header?.let {
                                val algorithm = if (it.certificate) stringResource(R.string.protect_rsa_recipient)
                                    else it.aesKeySize?.let { bits -> "AES-$bits" } ?: stringResource(R.string.protect_password)
                                Text(algorithm, style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.primary)
                            }
                            if (inspected && header == null) Text(stringResource(R.string.protect_error), color = MaterialTheme.colorScheme.error)
                        }
                        if (rsa) {
                            Text(stringResource(if (decrypt) R.string.protect_certificate_decrypt_guide else R.string.protect_certificate_encrypt_guide),
                                style = MaterialTheme.typography.bodyMedium)
                            if (!decrypt) OutlinedButton(onClick = { pickRecipient.launch(arrayOf("*/*")) }, enabled = !busy) {
                                Text(stringResource(R.string.protect_choose_certificate))
                            }
                            OutlinedButton(enabled = !busy, onClick = {
                                scope.launch {
                                    reset()
                                    busy = true
                                    identity = null
                                    recipient = null
                                    identities = emptyList()
                                    pin = ""
                                    try {
                                        val (selectedReader, keys) = vm.encryptionIdentities()
                                        reader = selectedReader
                                        identities = keys
                                        if (keys.isEmpty()) { notice = R.string.protect_no_key; failed = true }
                                        else selectIdentity(keys.first())
                                    } catch (cancelled: kotlinx.coroutines.CancellationException) { throw cancelled }
                                    catch (error: Exception) { fail(error) }
                                    finally { busy = false }
                                }
                            }) { Text(stringResource(R.string.protect_read_card)) }
                            if (identities.size > 1) identities.forEach { item ->
                                FilterChip(selected = item == identity, enabled = !busy, onClick = { reset(); selectIdentity(item) },
                                    label = { Text(item.label + " · " + item.fingerprint.takeLast(8)) })
                            }
                            recipient?.let { cert ->
                                Text(stringResource(R.string.protect_recipient), style = MaterialTheme.typography.labelMedium)
                                Text(remember(cert) { CertificateSummary.parse(cert.encoded).commonName }, style = MaterialTheme.typography.titleMedium)
                            }
                            if (decrypt && identity != null) OutlinedTextField(value = pin, onValueChange = {
                                if (it.length <= 8 && it.all { c -> c in '0'..'9' }) { pin = it; reset() }
                            }, enabled = !busy, label = { Text(stringResource(R.string.protect_card_pin)) },
                                visualTransformation = PasswordVisualTransformation(), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                                singleLine = true, modifier = Modifier.fillMaxWidth())
                        } else if (!decrypt || header != null) {
                            if (!decrypt) {
                                Text(stringResource(R.string.protect_key_size), style = MaterialTheme.typography.labelLarge)
                                val sizes = PasswordFileProtection.keySizes
                                ProtectionChoices(sizes.map { it.toString() }, sizes.indexOf(keySize), enabled = !busy) {
                                    keySize = sizes[it]; reset()
                                }
                            }
                            val mismatch = !decrypt && confirmation.isNotEmpty() && password != confirmation
                            OutlinedTextField(value = password, onValueChange = { password = it; reset() }, enabled = !busy, label = { Text(stringResource(R.string.protect_password)) }, visualTransformation = PasswordVisualTransformation(), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password), singleLine = true, modifier = Modifier.fillMaxWidth())
                            if (!decrypt) OutlinedTextField(value = confirmation, onValueChange = { confirmation = it; reset() }, enabled = !busy, isError = mismatch,
                                supportingText = if (mismatch) { { Text(stringResource(R.string.protect_mismatch)) } } else null,
                                label = { Text(stringResource(R.string.protect_confirm_password)) }, visualTransformation = PasswordVisualTransformation(), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password), singleLine = true, modifier = Modifier.fillMaxWidth())
                        }
                        TextButton(onClick = { helpExpanded = !helpExpanded }, enabled = !busy) { Text(stringResource(R.string.protect_help)) }
                        if (helpExpanded) {
                            Text(stringResource(help), style = MaterialTheme.typography.bodyMedium)
                            Text(stringResource(R.string.protect_compatibility), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    } else {
                        Icon(Icons.Outlined.CheckCircle, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(48.dp))
                        Text(outputName, style = MaterialTheme.typography.titleMedium)
                    }
                    cardError?.let { Text(it, color = MaterialTheme.colorScheme.error) }
                    if (busy) LinearProgressIndicator(Modifier.fillMaxWidth())
                    notice?.let { Text(stringResource(it), color = if (failed) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary) }
                }
                Text(stringResource(R.string.protect_original), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(vertical = 12.dp))
                if (output != null) OutlinedButton(onClick = {
                    save.launch(outputName)
                }, enabled = !busy, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.action_save_as)) }
                if (saved) Button(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.action_close)) }
                else Button(enabled = !busy && source != null && when {
                    rsa && decrypt -> identity?.pinLengths?.contains(pin.length) == true
                    rsa -> recipient != null
                    else -> (!decrypt || header != null) && password.isNotEmpty() && (decrypt || password == confirmation)
                }, modifier = Modifier.fillMaxWidth(), onClick = {
                    val uri = source ?: return@Button
                    val secret = (if (rsa) pin else password).toCharArray()
                    clearSecrets()
                    scope.launch {
                        busy = true; reset()
                        try {
                            output = when {
                                rsa && decrypt -> vm.decryptProtectedFile(uri, requireNotNull(identity), secret, reader)
                                rsa -> vm.encryptForRecipient(uri, requireNotNull(recipient))
                                else -> vm.protectDocument(uri, secret, decrypt, keySize)
                            }
                            saved = true
                            notice = R.string.protect_saved
                        } catch (cancelled: kotlinx.coroutines.CancellationException) { throw cancelled }
                        catch (error: Exception) { fail(error) }
                        finally { secret.fill('\u0000'); busy = false }
                    }
                }) { Text(stringResource(if (decrypt) R.string.protect_decrypt else R.string.protect_encrypt)) }
            }
        }
    }
}


@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ProtectionChoices(labels: List<String>, selected: Int, enabled: Boolean, select: (Int) -> Unit) {
    SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
        labels.forEachIndexed { index, label ->
            SegmentedButton(icon = {}, shape = SegmentedButtonDefaults.itemShape(index, labels.size), selected = index == selected,
                enabled = enabled, onClick = { if (index != selected) select(index) }) { Text(label) }
        }
    }
}
