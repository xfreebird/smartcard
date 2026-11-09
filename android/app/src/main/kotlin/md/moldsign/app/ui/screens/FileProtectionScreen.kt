package md.moldsign.app.ui.screens

import md.moldsign.app.hostActivity
import android.net.Uri
import android.provider.OpenableColumns
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.ExpandLess
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
import md.moldsign.core.protection.*
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FileProtectionDialog(vm: MainViewModel,onDismiss: () -> Unit) {
    val context=LocalContext.current;val scope=rememberCoroutineScope()
    var decrypt by remember { mutableStateOf(false) }
    var cardMode by remember { mutableStateOf(false) }
    var source by remember { mutableStateOf<Uri?>(null) }
    var sourceName by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmation by remember { mutableStateOf("") }
    var pin by remember { mutableStateOf("") }
    var certificate by remember { mutableStateOf<X509Certificate?>(null) }
    var identities by remember { mutableStateOf<List<CardEncryptionIdentity>>(emptyList()) }
    var identity by remember { mutableStateOf<CardEncryptionIdentity?>(null) }
    var reader by remember { mutableStateOf<String?>(null) }
    var busy by remember { mutableStateOf(false) }
    var output by remember { mutableStateOf<ByteArray?>(null) }
    var notice by remember { mutableStateOf<Int?>(null) }
    var failed by remember { mutableStateOf(false) }
    var helpExpanded by remember { mutableStateOf(false) }
    var detailsExpanded by remember { mutableStateOf(false) }
    val guide = if(cardMode) { if(decrypt) R.string.protect_certificate_decrypt_guide else R.string.protect_certificate_encrypt_guide } else { if(decrypt) R.string.protect_password_decrypt_guide else R.string.protect_password_encrypt_guide }
    val help = if(cardMode) { if(decrypt) R.string.protect_certificate_decrypt_help else R.string.protect_certificate_encrypt_help } else { if(decrypt) R.string.protect_password_decrypt_help else R.string.protect_password_encrypt_help }
    val captureIntent=context.hostActivity()?.intent
    LaunchedEffect(Unit) {
        if(md.moldsign.app.DemoMode.screenshotCapture(captureIntent)) {
            val scenario=captureIntent?.getStringExtra("capture_dialog") ?: ""
            if(scenario.startsWith("protect-")) {
                sourceName="Contract.pdf";decrypt=scenario.contains("decrypt");cardMode=scenario.contains("certificate")
            }
        }
    }
    fun reset() { output?.fill(0);output=null;notice=null;failed=false }
    fun fail() { notice=R.string.protect_error;failed=true }
    suspend fun read(uri: Uri): ByteArray = withContext(Dispatchers.IO) {
        context.contentResolver.openInputStream(uri)?.use { stream ->
            val out=java.io.ByteArrayOutputStream();val buffer=ByteArray(65536)
            while(true) {
                val count=stream.read(buffer);if(count<0) break
                require(out.size()+count <= PasswordFileProtection.MAXIMUM_SIZE+8192)
                out.write(buffer,0,count)
            }
            out.toByteArray()
        } ?: error("Cannot read document")
    }
    val pickFile=rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if(uri!=null) {
            reset();source=uri
            sourceName=context.contentResolver.query(uri,arrayOf(OpenableColumns.DISPLAY_NAME),null,null,null)?.use { c -> if(c.moveToFirst()) c.getString(0) else null } ?: "document"
        }
    }
    val pickCertificate=rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if(uri!=null) scope.launch {
            busy=true;reset()
            try {
                val bytes=read(uri);require(bytes.size<=65536)
                val cert=withContext(Dispatchers.IO) {
                    (CertificateFactory.getInstance("X.509").generateCertificate(bytes.inputStream()) as X509Certificate).also {
                        CertificateFileProtection.encrypt(ByteArray(0),it)
                    }
                }
                certificate=cert;identity=null;identities=emptyList()
            } catch(_:Exception) { fail() }
            finally { busy=false }
        }
    }
    val save=rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/octet-stream")) { uri ->
        val bytes=output
        if(uri!=null && bytes!=null) scope.launch {
            busy=true
            try {
                require(uri!=source)
                withContext(Dispatchers.IO) { context.contentResolver.openOutputStream(uri,"w")?.use { it.write(bytes);it.flush() } ?: error("Cannot save") }
                reset();notice=R.string.protect_saved
            } catch(_:Exception) { fail() }
            finally { busy=false }
        }
    }
    var certificateExport by remember { mutableStateOf<ByteArray?>(null) }
    val exportCertificate=rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/pkix-cert")) { uri ->
        val bytes=certificateExport;certificateExport=null
        if(uri!=null && bytes!=null) scope.launch {
            busy=true
            try {
                withContext(Dispatchers.IO) { context.contentResolver.openOutputStream(uri,"w")?.use { it.write(bytes);it.flush() } ?: error("Cannot save certificate") }
                notice=R.string.protect_saved;failed=false
            } catch(_:Exception) { fail() } finally { busy=false }
        }
    }
    val lifecycleOwner=androidx.lifecycle.compose.LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer=androidx.lifecycle.LifecycleEventObserver { _,event ->
            if(event==androidx.lifecycle.Lifecycle.Event.ON_STOP) {password="";confirmation="";pin=""}
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {lifecycleOwner.lifecycle.removeObserver(observer)}
    }
    DisposableEffect(Unit) { onDispose { password="";confirmation="";pin="";output?.fill(0) } }
    Dialog(onDismissRequest={ if(!busy) onDismiss() },properties=DialogProperties(usePlatformDefaultWidth=false,dismissOnClickOutside=!busy,dismissOnBackPress=!busy)) {
        Surface(shape=MaterialTheme.shapes.extraLarge,modifier=Modifier.padding(16.dp).widthIn(max=640.dp).fillMaxWidth().fillMaxHeight(.94f)) {
            Column(Modifier.imePadding().padding(20.dp)) {
                Row(verticalAlignment=Alignment.CenterVertically) {
                    Icon(Icons.Outlined.Lock,null,tint=MaterialTheme.colorScheme.primary)
                    Text(stringResource(R.string.protect_title),style=MaterialTheme.typography.titleLarge,modifier=Modifier.weight(1f).padding(horizontal=12.dp))
                    TextButton(onClick=onDismiss,enabled=!busy) { Text(stringResource(R.string.action_cancel)) }
                }
                Column(Modifier.weight(1f).verticalScroll(rememberScrollState()),verticalArrangement=Arrangement.spacedBy(16.dp)) {
                    SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                        SegmentedButton(icon={},shape=SegmentedButtonDefaults.itemShape(0,2),selected=!decrypt,onClick={ decrypt=false;reset();password="";confirmation="";pin="" },enabled=!busy,label={Text(stringResource(R.string.protect_encrypt))})
                        SegmentedButton(icon={},shape=SegmentedButtonDefaults.itemShape(1,2),selected=decrypt,onClick={ decrypt=true;reset();password="";confirmation="";pin="" },enabled=!busy,label={Text(stringResource(R.string.protect_decrypt))})
                    }
                    Text(stringResource(R.string.protect_file_step),style=MaterialTheme.typography.titleSmall)
                    OutlinedButton(onClick={pickFile.launch(arrayOf("*/*"))},enabled=!busy,modifier=Modifier.fillMaxWidth()) {
                        Text(sourceName.ifEmpty { stringResource(R.string.protect_choose_file) },modifier=Modifier.padding(vertical=8.dp))
                    }
                    Text(stringResource(R.string.protect_access_step),style=MaterialTheme.typography.titleSmall)
                    SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                        SegmentedButton(icon={},shape=SegmentedButtonDefaults.itemShape(0,2),selected=!cardMode,onClick={cardMode=false;reset();pin=""},enabled=!busy,label={Text(stringResource(R.string.protect_password))})
                        SegmentedButton(icon={},shape=SegmentedButtonDefaults.itemShape(1,2),selected=cardMode,onClick={cardMode=true;reset();password="";confirmation=""},enabled=!busy,label={Text(stringResource(R.string.protect_certificate))})
                    }
                    Text(stringResource(guide),style=MaterialTheme.typography.bodyMedium,color=MaterialTheme.colorScheme.onSurfaceVariant)
                    val mismatch = !decrypt && confirmation.isNotEmpty() && password != confirmation
                    if(!cardMode) {
                        OutlinedTextField(value=password,onValueChange={password=it;reset()},enabled=!busy,label={Text(stringResource(R.string.protect_password))},visualTransformation=PasswordVisualTransformation(),singleLine=true,modifier=Modifier.fillMaxWidth())
                        if(!decrypt) {
                            OutlinedTextField(value=confirmation,onValueChange={confirmation=it;reset()},enabled=!busy,isError=mismatch,supportingText=if(mismatch) { { Text(stringResource(R.string.protect_mismatch)) } } else null,label={Text(stringResource(R.string.protect_confirm_password))},visualTransformation=PasswordVisualTransformation(),singleLine=true,modifier=Modifier.fillMaxWidth())
                        }
                    } else {
                        if(!decrypt) OutlinedButton(onClick={pickCertificate.launch(arrayOf("*/*"))},enabled=!busy) { Text(stringResource(R.string.protect_choose_certificate)) }
                        OutlinedButton(enabled=!busy,onClick={scope.launch {
                            busy=true;reset();certificate=null;identity=null;identities=emptyList()
                            try {
                                val found=vm.encryptionIdentities();reader=found.first;identities=found.second
                                identity=found.second.firstOrNull()
                                certificate=identity?.let { CertificateFactory.getInstance("X.509").generateCertificate(it.certificate.inputStream()) as X509Certificate }
                                if(identity==null) {notice=R.string.protect_no_key;failed=true}
                            } catch(_:Exception) {fail()} finally {busy=false}
                        }}) { Text(stringResource(R.string.protect_read_card)) }
                        if(identities.size>1) identities.forEach { item ->
                            FilterChip(selected=identity==item,enabled=!busy,onClick={identity=item;certificate=CertificateFactory.getInstance("X.509").generateCertificate(item.certificate.inputStream()) as X509Certificate;pin="";reset()},label={Text(item.label+" · "+item.fingerprint.takeLast(8))})
                        }
                        if(certificate!=null) {
                            Text(identity?.label ?: certificate!!.subjectX500Principal.name,style=MaterialTheme.typography.bodyMedium,maxLines=2,overflow=androidx.compose.ui.text.style.TextOverflow.Ellipsis)
                            TextButton(onClick={detailsExpanded=!detailsExpanded},enabled=!busy) {
                                Text(stringResource(R.string.protect_details),modifier=Modifier.weight(1f))
                                Icon(if(detailsExpanded) Icons.Outlined.ExpandLess else Icons.Outlined.ExpandMore,null)
                            }
                        }
                        if(detailsExpanded) {
                        certificate?.let { Text(it.subjectX500Principal.name,style=MaterialTheme.typography.bodyMedium) }
                        identity?.let { selected ->
                            Text(selected.fingerprint,style=MaterialTheme.typography.bodySmall)
                            OutlinedButton(enabled=!busy,onClick={
                                certificateExport=selected.certificate.copyOf()
                                exportCertificate.launch("encryption-${selected.fingerprint}.cer")
                            }) { Text(stringResource(R.string.protect_export_certificate)) }
                            Text(stringResource(R.string.protect_export_certificate_hint),style=MaterialTheme.typography.bodySmall)
                        }
                        }
                        if(decrypt && identity!=null) OutlinedTextField(value=pin,onValueChange={pin=it;reset()},enabled=!busy,label={Text(stringResource(R.string.protect_card_pin))},visualTransformation=PasswordVisualTransformation(),singleLine=true,modifier=Modifier.fillMaxWidth())
                    }
                    TextButton(onClick={helpExpanded=!helpExpanded},enabled=!busy) {
                        Text(stringResource(R.string.protect_help),modifier=Modifier.weight(1f))
                        Icon(if(helpExpanded) Icons.Outlined.ExpandLess else Icons.Outlined.ExpandMore,null)
                    }
                    if(helpExpanded) {
                        Text(stringResource(help),style=MaterialTheme.typography.bodyMedium)
                        Text(stringResource(R.string.protect_compatibility),style=MaterialTheme.typography.bodySmall,color=MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    if(busy) LinearProgressIndicator(Modifier.fillMaxWidth())
                    notice?.let { Text(stringResource(it),color=if(failed) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary) }
                }
                Text(stringResource(R.string.protect_original),style=MaterialTheme.typography.bodySmall,color=MaterialTheme.colorScheme.onSurfaceVariant,modifier=Modifier.padding(vertical=12.dp))
                    if(output!=null) Button(onClick={
                        val name=if(decrypt) "decrypted-"+sourceName.removeSuffix(PasswordFileProtection.SUFFIX).removeSuffix(CertificateFileProtection.SUFFIX) else sourceName+if(cardMode) CertificateFileProtection.SUFFIX else PasswordFileProtection.SUFFIX
                        save.launch(name)
                    },enabled=!busy,modifier=Modifier.fillMaxWidth()) {Text(stringResource(R.string.protect_save))}
                    else Button(enabled=!busy && source!=null && (if(cardMode) {if(decrypt) identity!=null && pin.isNotEmpty() else certificate!=null} else password.isNotEmpty() && (decrypt || password==confirmation)),modifier=Modifier.fillMaxWidth(),onClick={
                        val uri=source ?: return@Button;val secret=password.toCharArray();val cardPin=pin.toCharArray()
                        password="";confirmation="";pin=""
                        scope.launch {
                            busy=true;reset()
                            try {
                                val bytes=read(uri)
                                output=withContext(Dispatchers.IO) {
                                    if(!cardMode) {if(decrypt) PasswordFileProtection.decrypt(bytes,secret) else PasswordFileProtection.encrypt(bytes,secret)}
                                    else if(!decrypt) CertificateFileProtection.encrypt(bytes,requireNotNull(certificate))
                                    else vm.decryptProtectedFile(bytes,requireNotNull(identity),cardPin,reader)
                                }
                                notice=R.string.protect_ready
                            } catch(_:Exception) {fail()}
                            finally {secret.fill('\u0000');cardPin.fill('\u0000');busy=false}
                        }
                    }) {Text(stringResource(if(decrypt) R.string.protect_decrypt else R.string.protect_encrypt))}

            }
        }
    }
}
