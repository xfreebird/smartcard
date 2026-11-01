package md.moldsign.app.ui.screens

import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.webkit.CookieManager
import android.webkit.ValueCallback
import android.webkit.URLUtil
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.webkit.WebStorage
import androidx.compose.material.icons.outlined.Delete
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.selection.toggleable
import androidx.compose.ui.semantics.Role
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.ArrowForward
import androidx.compose.material.icons.outlined.Bookmarks
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import md.moldsign.app.R
import java.util.Locale

private const val DESKTOP_USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
private val desktopLoginHosts = setOf("mpass.gov.md", "testmpass.gov.md", "mpass.staging.egov.md")

/** Used to explain the ID-login behavior while the authentication service is visible. */
private fun needsDesktopLogin(url: String): Boolean =
    Uri.parse(url).host?.lowercase(Locale.ROOT) in desktopLoginHosts

private fun browserUrl(input: String): String? {
    val value = input.trim()
    if (value.isEmpty() || value.any { it.isWhitespace() }) return null
    val withScheme = if (value.contains("://")) value else "https://$value"
    val uri = Uri.parse(withScheme)
    return withScheme.takeIf { uri.scheme?.lowercase(Locale.ROOT) in setOf("https", "http") && !uri.host.isNullOrBlank() && uri.userInfo == null }
}

@Composable
fun InAppBrowser(onClose: () -> Unit) {
    val context = LocalContext.current
    var address by remember { mutableStateOf("https://msign.gov.md/#/") }
    var servicesExpanded by remember { mutableStateOf(false) }
    var showingDataReset by remember { mutableStateOf(false) }
    var clearCache by remember { mutableStateOf(true) }
    var clearCookies by remember { mutableStateOf(true) }
    var clearHistory by remember { mutableStateOf(true) }
    var clearingData by remember { mutableStateOf(false) }
    var browserGeneration by remember { mutableIntStateOf(0) }
    var invalidAddress by remember { mutableStateOf(false) }
    var canBack by remember { mutableStateOf(false) }
    var canForward by remember { mutableStateOf(false) }
    var desktopLogin by remember { mutableStateOf(false) }
    var loadFailed by remember { mutableStateOf(false) }
    var fileCallback by remember { mutableStateOf<ValueCallback<Array<Uri>>?>(null) }
    val uploadView = remember { arrayOfNulls<WebView>(1) }
    val pageGeneration = remember { intArrayOf(0) }
    val uploadGeneration = remember { intArrayOf(-1) }
    val filePicker = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        val callback = fileCallback
        fileCallback = null
        val files = WebChromeClient.FileChooserParams.parseResult(result.resultCode, result.data)
        // Only document-provider URIs selected by the user are valid: do not let a picker
        // return a file URI or an app-owned provider whose permissions the WebView inherits.
        val accepted = files?.takeIf { selected -> selected.isNotEmpty() && selected.all { uri ->
            val authority = uri.authority
            val provider = authority?.let { context.packageManager.resolveContentProvider(it, 0) }
            uri.scheme == "content" && authority != null &&
                authority != context.packageName && !authority.startsWith(context.packageName + ".") &&
                provider?.packageName != context.packageName &&
                context.checkUriPermission(uri, android.os.Process.myPid(), android.os.Process.myUid(),
                    Intent.FLAG_GRANT_READ_URI_PERMISSION) == android.content.pm.PackageManager.PERMISSION_GRANTED
        } }
        // Chromium may need content access for the returned picker URIs. Enable it only after a
        // valid selection and retain it through a form POST; clear after the subsequent page loads.
        uploadView[0]?.settings?.allowContentAccess = accepted != null
        uploadGeneration[0] = if (accepted != null) pageGeneration[0] else -1
        callback?.onReceiveValue(accepted)
    }
    val webView = remember(browserGeneration) {
        WebView(context).apply {
            // WebView has no pre-request callback for POST navigation. Set this before the first
            // request so MPASS receives it on redirects and form submissions without replaying POSTs.
            settings.userAgentString = DESKTOP_USER_AGENT
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.useWideViewPort = true
            settings.loadWithOverviewMode = true
            settings.builtInZoomControls = true
            settings.displayZoomControls = false
            settings.allowFileAccess = false
            settings.allowContentAccess = false
            settings.mixedContentMode = android.webkit.WebSettings.MIXED_CONTENT_NEVER_ALLOW
            webChromeClient = object : WebChromeClient() {
                override fun onShowFileChooser(view: WebView, callback: ValueCallback<Array<Uri>>,
                                               params: FileChooserParams): Boolean {
                    fileCallback?.onReceiveValue(null)
                    fileCallback = callback
                    return try {
                        filePicker.launch(params.createIntent())
                        true
                    } catch (_: Exception) {
                        fileCallback = null
                        callback.onReceiveValue(null)
                        true
                    }
                }
            }
            setDownloadListener { url, userAgent, disposition, mimeType, _ ->
                val uri = Uri.parse(url)
                val hasCookies = !CookieManager.getInstance().getCookie(url).isNullOrBlank()
                val started = !hasCookies && runCatching {
                    require(uri.scheme.equals("https", true) || uri.scheme.equals("http", true))
                    val request = DownloadManager.Request(uri)
                        .setTitle(URLUtil.guessFileName(url, disposition, mimeType))
                        .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                    if (!userAgent.isNullOrBlank()) request.addRequestHeader("User-Agent", userAgent)
                    if (!mimeType.isNullOrBlank()) request.setMimeType(mimeType)
                    (context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager).enqueue(request)
                }.isSuccess
                val message = if (started) R.string.browser_download_started
                    else if (hasCookies) R.string.browser_download_signin else R.string.browser_download_failed
                Toast.makeText(context, message, Toast.LENGTH_LONG).show()
            }
            webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                    if (!request.isForMainFrame) return false
                    val uri = request.url
                    if (uri.scheme.equals("https", true) || uri.scheme.equals("http", true)) {
                        return false
                    }
                    // Only user-initiated standard external links may leave the browser.
                    if (request.hasGesture() && uri.scheme?.lowercase(Locale.ROOT) in setOf("mailto", "tel", "sms")) {
                        runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, uri)) }
                    }
                    return true
                }
                override fun onPageStarted(view: WebView, url: String, favicon: android.graphics.Bitmap?) {
                    if (uploadView[0] !== view) return
                    pageGeneration[0]++
                    desktopLogin = needsDesktopLogin(url)
                    loadFailed = false
                    address = url
                    invalidAddress = false
                    canBack = view.canGoBack()
                    canForward = view.canGoForward()
                }
                override fun onReceivedError(view: WebView, request: WebResourceRequest, error: android.webkit.WebResourceError) {
                    if (request.isForMainFrame) loadFailed = true
                }
                override fun onReceivedHttpError(view: WebView, request: WebResourceRequest, response: android.webkit.WebResourceResponse) {
                    if (request.isForMainFrame && response.statusCode >= 400) loadFailed = true
                }
                override fun onReceivedSslError(view: WebView, handler: android.webkit.SslErrorHandler, error: android.net.http.SslError) {
                    loadFailed = true
                    handler.cancel()
                }
                override fun onPageFinished(view: WebView, url: String) {
                    if (uploadView[0] !== view) return
                    if (uploadGeneration[0] >= 0 && pageGeneration[0] > uploadGeneration[0]) {
                        view.settings.allowContentAccess = false
                        uploadGeneration[0] = -1
                    }
                    address = url
                    canBack = view.canGoBack()
                    canForward = view.canGoForward()
                }
            }
            uploadView[0] = this
            if (address.isNotBlank()) loadUrl(address)
        }
    }
    DisposableEffect(webView) {
        onDispose {
            fileCallback?.onReceiveValue(null)
            fileCallback = null
            webView.stopLoading()
            if (uploadView[0] === webView) uploadView[0] = null
            webView.destroy()
        }
    }
    BackHandler { if (webView.canGoBack()) webView.goBack() else onClose() }
    fun navigate() {
        val url = browserUrl(address)
        invalidAddress = url == null
        if (url != null) {
            webView.loadUrl(url)
        }
    }
    fun resetBrowsingData() {
        clearingData = true
        webView.stopLoading()
        fileCallback?.onReceiveValue(null)
        fileCallback = null
        webView.settings.allowContentAccess = false
        if (clearCache) webView.clearCache(true)
        if (clearCookies || clearHistory) {
            // A fresh WebView clears its navigation list and removes live page authentication state.
            webView.loadUrl("about:blank")
        }
        fun finishReset() {
            if (clearCookies || clearHistory) {
                address = ""
                canBack = false
                canForward = false
                desktopLogin = false
                invalidAddress = false
                loadFailed = false
                browserGeneration++
            }
            clearingData = false
            showingDataReset = false
        }
        if (clearCookies) {
            CookieManager.getInstance().removeAllCookies {
                CookieManager.getInstance().flush()
                WebStorage.getInstance().deleteAllData()
                finishReset()
            }
        } else finishReset()
    }
    if (showingDataReset) {
        AlertDialog(
            onDismissRequest = { if (!clearingData) showingDataReset = false },
            title = { Text(stringResource(R.string.browser_clear_data)) },
            text = {
                Column {
                    Text(stringResource(R.string.browser_data_reset_note))
                    Row(Modifier.fillMaxWidth().toggleable(value = clearCache, enabled = !clearingData, role = Role.Checkbox,
                        onValueChange = { clearCache = it }), verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                        Checkbox(checked = clearCache, onCheckedChange = null, enabled = !clearingData)
                        Text(stringResource(R.string.browser_cache))
                    }
                    Row(Modifier.fillMaxWidth().toggleable(value = clearCookies, enabled = !clearingData, role = Role.Checkbox,
                        onValueChange = { clearCookies = it }), verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                        Checkbox(checked = clearCookies, onCheckedChange = null, enabled = !clearingData)
                        Text(stringResource(R.string.browser_cookies))
                    }
                    Row(Modifier.fillMaxWidth().toggleable(value = clearHistory, enabled = !clearingData, role = Role.Checkbox,
                        onValueChange = { clearHistory = it }), verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                        Checkbox(checked = clearHistory, onCheckedChange = null, enabled = !clearingData)
                        Text(stringResource(R.string.browser_history))
                    }
                    if (clearingData) LinearProgressIndicator(Modifier.fillMaxWidth())
                }
            },
            confirmButton = {
                TextButton(onClick = { resetBrowsingData() }, enabled = !clearingData && (clearCache || clearCookies || clearHistory)) {
                    Text(stringResource(R.string.browser_clear_selected))
                }
            },
            dismissButton = {
                TextButton(onClick = { showingDataReset = false }, enabled = !clearingData) { Text(stringResource(R.string.action_cancel)) }
            },
        )
    }
    Column(Modifier.fillMaxSize().padding(horizontal = 12.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            IconButton(onClick = { webView.goBack() }, enabled = canBack) { Icon(Icons.AutoMirrored.Outlined.ArrowBack, stringResource(R.string.browser_back)) }
            IconButton(onClick = { webView.goForward() }, enabled = canForward) { Icon(Icons.AutoMirrored.Outlined.ArrowForward, stringResource(R.string.browser_forward)) }
            IconButton(onClick = { webView.reload() }) { Icon(Icons.Outlined.Refresh, stringResource(R.string.browser_reload)) }
            Box {
                IconButton(onClick = { servicesExpanded = true }) {
                    Icon(Icons.Outlined.Bookmarks, stringResource(R.string.browser_services))
                }
                DropdownMenu(expanded = servicesExpanded, onDismissRequest = { servicesExpanded = false }) {
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.browser_clear_data)) },
                        leadingIcon = { Icon(Icons.Outlined.Delete, contentDescription = null) },
                        onClick = { servicesExpanded = false; showingDataReset = true },
                    )
                    HorizontalDivider()
                    PortalService.all.forEach { service ->
                        DropdownMenuItem(
                            text = { Text(service.name ?: stringResource(service.titleResource!!)) },
                            leadingIcon = { Image(painterResource(service.imageResource), contentDescription = null, modifier = Modifier.size(20.dp)) },
                            onClick = {
                                servicesExpanded = false
                                invalidAddress = false
                                address = service.url
                                webView.loadUrl(service.url)
                            },
                        )
                    }
                }
            }
            Spacer(Modifier.weight(1f))
            IconButton(onClick = onClose) { Icon(Icons.Outlined.Close, stringResource(R.string.browser_close)) }
        }
        OutlinedTextField(
            value = address, onValueChange = { address = it; invalidAddress = false },
            modifier = Modifier.fillMaxWidth(), singleLine = true,
            label = { Text(stringResource(R.string.browser_address)) },
            isError = invalidAddress,
            supportingText = if (invalidAddress) ({ Text(stringResource(R.string.browser_invalid_address)) }) else null,
            trailingIcon = { TextButton(onClick = { navigate() }) { Text(stringResource(R.string.browser_go)) } },
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Go),
            keyboardActions = androidx.compose.foundation.text.KeyboardActions(onGo = { navigate() }),
        )
        if (desktopLogin) Text(stringResource(R.string.browser_login_desktop), style = MaterialTheme.typography.labelSmall)
        if (loadFailed) Text(stringResource(R.string.browser_load_error), color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
        Spacer(Modifier.height(8.dp))
        key(browserGeneration) {
            AndroidView(factory = { webView }, modifier = Modifier.fillMaxWidth().weight(1f))
        }
    }
}
