package md.moldsign.app.ui

import md.moldsign.app.presentation.toStatusContent
import md.moldsign.app.presentation.toPinPromptContent

import md.moldsign.app.hostActivity
import md.moldsign.app.AppShortcuts
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.saveable.rememberSaveable

import androidx.annotation.StringRes
import android.content.Intent
import md.moldsign.app.DemoMode
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.layout.requiredWidth
import androidx.compose.foundation.layout.Box
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import md.moldsign.app.ui.screens.FileProtectionDialog
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CreditCard
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Draw
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.VerifiedUser
import androidx.compose.material.icons.rounded.Draw
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Switch
import androidx.compose.material3.Surface
import androidx.compose.material3.TextButton
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import md.moldsign.app.MainActivity
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationRail
import androidx.compose.material3.NavigationRailItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SnackbarResult
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.key
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.launch
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import md.moldsign.app.presentation.MainViewModel
import md.moldsign.app.R
import md.moldsign.app.presentation.UiMessage
import md.moldsign.app.presentation.messageText
import md.moldsign.app.ui.components.PinSheet
import md.moldsign.app.ui.components.StatusLightChip
import md.moldsign.app.ui.screens.ActivityScreen
import md.moldsign.app.ui.screens.AboutContent
import md.moldsign.app.ui.screens.BrowserScreen
import md.moldsign.app.ui.screens.CardScreen
import md.moldsign.app.ui.screens.SignScreen
import md.moldsign.app.ui.screens.VerifyScreen
import md.moldsign.app.ui.theme.Tokens
import androidx.compose.material.icons.outlined.FolderOpen
import md.moldsign.core.ConsentResult

private enum class Dest(val route: String, @StringRes val label: Int, val icon: ImageVector) {
    Sign("sign", R.string.nav_sign, Icons.Outlined.Draw),
    Verify("verify", R.string.nav_verify, Icons.Outlined.VerifiedUser),
    Activity("activity", R.string.nav_activity, Icons.Outlined.FolderOpen),
    Browser("browser", R.string.nav_browser, Icons.Outlined.Language),
    Settings("settings", R.string.demo_mode_settings, Icons.Outlined.Settings),
}

private fun NavHostController.go(d: Dest) = navigate(d.route) {
    popUpTo(graph.findStartDestination().id) { saveState = true }
    launchSingleTop = true
    restoreState = true
}

/**
 * Adaptive Material 3 shell. Expanded windows use a navigation rail and in-pane signing controls;
 * compact windows use the navigation bar and a floating primary action. Classification follows the
 * current window constraints, including split screen and rotation, rather than the device model.
 */
@OptIn(ExperimentalMaterial3Api::class, androidx.compose.ui.ExperimentalComposeUiApi::class)
@Composable
fun MoldSignRoot(vm: MainViewModel = viewModel(), demoPage: String? = null, demoGeneration: Int = 0) {
    val captureIntent = LocalContext.current.hostActivity()?.intent
    val captureDialog = if (DemoMode.screenshotCapture(captureIntent)) captureIntent?.getStringExtra("capture_dialog") else null
    md.moldsign.app.ui.features.GovernmentDisclosure(forceVisible = captureDialog == "disclosure")
    var confirmDemoEnable by remember { mutableStateOf(false) }
    var settingsPage by rememberSaveable { mutableStateOf(if (captureDialog == "about") "about" else "settings") }
    var cardDetails by remember { mutableStateOf(false) }
    val nfcIdentity by vm.nfcIdentity.collectAsStateWithLifecycle()
    if (cardDetails) md.moldsign.app.ui.screens.CardDetailsSheet(vm) { cardDetails = false }
    val nav = rememberNavController()
    val backStack by nav.currentBackStackEntryAsState()
    val navigationReady = backStack != null
    val dest = Dest.entries.firstOrNull { it.route == backStack?.destination?.route } ?: Dest.Sign
    val liveStatus by vm.status.collectAsStateWithLifecycle()
    val captureProgress = DemoMode.screenshotCapture(captureIntent) && captureIntent?.hasExtra("capture_step") == true
    val status = if (captureProgress) liveStatus.copy(light = md.moldsign.core.StatusLight.Busy, busy = true) else liveStatus
    val items by vm.signItems.collectAsStateWithLifecycle()
    val verifiedDocuments by vm.verifiedDocuments.collectAsStateWithLifecycle()
    val verifyDocument by vm.verifyDoc.collectAsStateWithLifecycle()
    val signingMethod by vm.signingMethod.collectAsStateWithLifecycle()
    val savedPinIds by vm.savedPinIds.collectAsStateWithLifecycle()
    val pendingPinSave by vm.pendingPinSave.collectAsStateWithLifecycle()
    val nfcPhase by vm.nfcPhase.collectAsStateWithLifecycle()
    val working by vm.working.collectAsStateWithLifecycle()
    val pending by vm.pendingConsent.collectAsStateWithLifecycle()
    val stamp by vm.pendingStamp.collectAsStateWithLifecycle()
    stamp?.let { request ->
        md.moldsign.app.ui.screens.PdfStampEditor(request.item, request.holder,
            onDismiss = { request.answer(md.moldsign.core.PdfStampDecision.Cancel) },
            onSave = { request.answer(md.moldsign.core.PdfStampDecision.Proceed(it)) }, requester = request.requester)
    }
    val message by vm.message.collectAsStateWithLifecycle()
    val snackbar = remember { SnackbarHostState() }
    val context = LocalContext.current
    val openLabel = stringResource(R.string.action_open)
    var protectionOpen by remember { mutableStateOf(false) }
    var toolsOpen by remember { mutableStateOf(false) }
    LaunchedEffect(captureDialog) { if (captureDialog == "protect-menu") toolsOpen = true }
    if (protectionOpen) FileProtectionDialog(vm) { protectionOpen = false }
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior()

    val shortcutRequest by vm.shortcutRequest.collectAsStateWithLifecycle()
    // Saved with the ActivityResult registry so rotation/process recreation cannot change the result's purpose.
    var activeShortcut by rememberSaveable { mutableStateOf<String?>(null) }
    val shortcutPicker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        val purpose = AppShortcuts.Destination.fromId(activeShortcut)
        activeShortcut = null
        // A newer request supersedes this picker. Cancellation never changes the existing document list.
        if (uri != null && vm.shortcutRequest.value == null) {
            when (purpose) {
                AppShortcuts.Destination.Verify -> vm.pickMultipleForVerify(listOf(uri))
                AppShortcuts.Destination.PrepareSigning -> vm.addForSigning(listOf(uri))
                else -> Unit
            }
        }
    }
    LaunchedEffect(shortcutRequest?.id, activeShortcut, working, pending, stamp, navigationReady) {
        if (!navigationReady) return@LaunchedEffect
        val request = shortcutRequest ?: return@LaunchedEffect
        // Do not replace a consent sheet, signature operation or another system picker.
        if (working || pending != null || stamp != null || activeShortcut != null) return@LaunchedEffect
        vm.selectWidgetDocument(request.documentID)
        when (request.destination) {
            AppShortcuts.Destination.Verify -> nav.go(Dest.Verify)
            AppShortcuts.Destination.PrepareSigning -> nav.go(Dest.Sign)
            AppShortcuts.Destination.Documents -> nav.go(Dest.Activity)
        }
        vm.consumeShortcut(request.id)
        if (request.destination != AppShortcuts.Destination.Documents) {
            activeShortcut = request.destination.id
            shortcutPicker.launch(arrayOf("application/pdf"))
        }
    }

    LaunchedEffect(demoGeneration, captureDialog, navigationReady) {
        if (DemoMode.screenshotCapture(captureIntent)) {
            if (navigationReady && captureDialog in listOf("settings", "about")) nav.go(Dest.Settings)
            confirmDemoEnable = captureDialog == "demo-confirm"
        }
    }

    LaunchedEffect(demoPage, navigationReady) {
        if (!navigationReady) return@LaunchedEffect
        Dest.entries.firstOrNull { it.route == (if (demoPage == "card") "settings" else demoPage) }?.let { nav.go(it) }
    }

    LaunchedEffect(dest.route, status.wallet, items, working, pending, demoGeneration) {
        val activity = context.hostActivity()
        val isDemo = activity?.intent?.hasExtra("demo") == true
        val isPinDemo = activity?.intent?.getStringExtra("demo")?.startsWith("pin") == true
        val consentReady = if (isPinDemo) pending != null else pending == null
        if (isDemo && !working && consentReady) {
            androidx.compose.runtime.withFrameNanos { }
            androidx.compose.runtime.withFrameNanos { }
            android.util.Log.i("MoldSignDemo", "ready:${dest.route}")
        }
    }

    LaunchedEffect(navigationReady) {
        if (!navigationReady) return@LaunchedEffect
        vm.showSign.collect { nav.go(Dest.Sign) }
    }

    LaunchedEffect(message) {
        val m = message ?: return@LaunchedEffect
        val text = messageText(context, m)
        if (text.isEmpty()) { vm.consumeMessage(); return@LaunchedEffect }
        if (m is UiMessage.Saved) {
            // long, with an action: the signed file is otherwise easy to lose in the Downloads folder
            val result = snackbar.showSnackbar(text, actionLabel = openLabel, duration = SnackbarDuration.Long)
            if (result == SnackbarResult.ActionPerformed) {
                runCatching {
                    context.startActivity(
                        Intent(Intent.ACTION_VIEW, m.uri).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK),
                    )
                }
            }
        } else {
            snackbar.showSnackbar(text)
        }
        // Consuming before showSnackbar changes this effect's key and cancels the visible message.
        vm.consumeMessage()
    }

    BoxWithConstraints(Modifier.fillMaxSize().semantics { testTagsAsResourceId = true }.testTag("app.window")) {
        val expanded = maxWidth >= 600.dp || (maxWidth >= 480.dp && maxWidth > maxHeight)
        val shortLandscape = maxHeight < 400.dp && maxWidth > maxHeight
        val compactStatus = maxWidth < 400.dp
        val showsNfcChoice = signingMethod == MainViewModel.SigningMethod.NFC && (dest == Dest.Sign || dest == Dest.Settings)
        val navigationLabelWidth = maxWidth / Dest.entries.size - 4.dp
        Scaffold(
            modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
            contentWindowInsets = WindowInsets.safeDrawing,
            topBar = {
                Column {
                TopAppBar(
                    // Home shows the public name (UX-12); the other destinations their own title.
                    title = { Text(stringResource(if (dest == Dest.Sign) R.string.app_name else dest.label),
                        modifier = Modifier.testTag("navigation.title"),
                        maxLines = 1, overflow = TextOverflow.Ellipsis) },
                    actions = {
                        if (dest == Dest.Verify && (verifiedDocuments.isNotEmpty() || verifyDocument != null)) {
                            IconButton(onClick = vm::clearVerifyResults,
                                modifier = Modifier.semantics { testTagsAsResourceId = true }.testTag("verify.clearResults")) {
                                Icon(Icons.Outlined.Delete, contentDescription = stringResource(R.string.clear_results),
                                    tint = MaterialTheme.colorScheme.error)
                            }
                        }
                        if (dest == Dest.Sign) IconButton(onClick = { cardDetails = true },
                            enabled = (if (signingMethod == MainViewModel.SigningMethod.NFC) nfcIdentity else status.wallet.selectedCard?.certificate) != null,
                            modifier = Modifier.testTag("sign.cardDetails")) {
                            Icon(Icons.Outlined.Info, stringResource(R.string.card_details_title))
                        }
                        if (dest == Dest.Activity) Box {
                            IconButton(onClick = { toolsOpen = true }) { Icon(Icons.Outlined.MoreVert, contentDescription = stringResource(R.string.action_more)) }
                            DropdownMenu(expanded = toolsOpen, onDismissRequest = { toolsOpen = false }) {
                                DropdownMenuItem(text = { Text(stringResource(R.string.protect_title)) }, onClick = { toolsOpen = false; protectionOpen = true })
                            }
                        }
                        if (dest == Dest.Browser && status.wallet.cards.isNotEmpty()) {
                            IconButton(onClick = vm::rereadCards, enabled = !status.busy) {
                                Icon(Icons.Rounded.Refresh, contentDescription = stringResource(R.string.action_reread))
                            }
                        }
                        if (dest == Dest.Browser) StatusLightChip(status.toStatusContent(context),
                            onClick = { nav.go(Dest.Settings) }, compact = compactStatus)
                        Spacer(Modifier.width(Tokens.S3))
                    },
                    scrollBehavior = scrollBehavior,
                )
                if (vm.demoMode && !DemoMode.screenshotCapture(context.hostActivity()?.intent)) Surface(color = MaterialTheme.colorScheme.secondaryContainer) {
                    Text(stringResource(R.string.demo_mode_disclaimer),
                        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp),
                        style = MaterialTheme.typography.labelLarge)
                }
                }
            },
            bottomBar = {
                if (!expanded || shortLandscape) NavigationBar(modifier = if (shortLandscape) Modifier.navigationBarsPadding().height(56.dp) else Modifier, windowInsets = if (shortLandscape) WindowInsets(0, 0, 0, 0) else androidx.compose.material3.NavigationBarDefaults.windowInsets) {
                    Dest.entries.forEach { d ->
                        NavigationBarItem(
                            modifier = Modifier.testTag("nav.${d.route}"),
                            selected = dest == d,
                            onClick = { nav.go(d) },
                            icon = { Icon(d.icon, contentDescription = stringResource(d.label)) },
                            alwaysShowLabel = !shortLandscape,
                            label = if (shortLandscape) null else { { Text(stringResource(when (d) { Dest.Activity -> R.string.nav_files; Dest.Sign -> R.string.nav_sign_short; Dest.Verify -> R.string.nav_verify_short; else -> d.label }), modifier = Modifier.requiredWidth(navigationLabelWidth), textAlign = TextAlign.Center, maxLines = 1, softWrap = false, overflow = TextOverflow.Ellipsis) } },
                        )
                    }
                }
            },
            snackbarHost = { SnackbarHost(snackbar) },
        ) { padding ->
            // Tell descendants that Scaffold's system-bar/cutout padding is already applied.
            Row(Modifier.fillMaxSize().padding(padding).consumeWindowInsets(padding)) {
                if (expanded && !shortLandscape) {
                    NavigationRail(
                        modifier = Modifier.fillMaxHeight().width(96.dp)
                            .verticalScroll(rememberScrollState()).padding(vertical = 12.dp),
                        windowInsets = WindowInsets(0, 0, 0, 0),
                    ) {
                        Dest.entries.forEach { d ->
                            NavigationRailItem(
                                modifier = Modifier.testTag("nav.${d.route}"),
                                selected = dest == d,
                                onClick = { nav.go(d) },
                                icon = { Icon(d.icon, contentDescription = stringResource(d.label)) },
                                label = { Text(stringResource(d.label)) },
                            )
                        }
                    }
                }
                // Scaffold insets are consumed once around the rail and destination, never once per pane.
                NavHost(nav, startDestination = Dest.Sign.route, modifier = Modifier.weight(1f).fillMaxHeight()) {
                    composable(Dest.Sign.route) {
                        SignScreen(vm, PaddingValues(0.dp), onOpenCard = { nav.go(Dest.Settings) }, onOpenDocuments = { nav.go(Dest.Activity) }, expanded = expanded)
                    }
                    composable(Dest.Verify.route) { VerifyScreen(vm, PaddingValues(0.dp)) }
                    composable(Dest.Activity.route) { ActivityScreen(vm, PaddingValues(0.dp), onVerify = { uri -> nav.go(Dest.Verify); vm.pickForVerify(uri) }) }
                    composable(Dest.Browser.route) { BrowserScreen(vm, PaddingValues(0.dp), onOpenCard = { nav.go(Dest.Settings) }) }
                    composable(Dest.Settings.route) {
                        md.moldsign.app.ui.screens.SettingsScreen(vm,
                            enabled = !working && !status.busy && pending == null && stamp == null,
                            page = settingsPage, onPageChange = { settingsPage = it }, onDemoChange = { enabled ->
                                if (enabled) confirmDemoEnable = true
                                else (context.hostActivity() as? MainActivity)?.changeDemoMode(false)
                            })
                    }
                }
            }
        }
    }

    if (confirmDemoEnable) AlertDialog(
        onDismissRequest = { confirmDemoEnable = false },
        title = { Text(stringResource(R.string.demo_mode_title)) },
        text = { Column {
            Text(stringResource(R.string.demo_mode_description))
            Spacer(Modifier.size(12.dp))
            Text(stringResource(R.string.demo_mode_disclaimer), style = MaterialTheme.typography.titleSmall)
        } },
        confirmButton = { TextButton(onClick = {
            confirmDemoEnable = false
            (context.hostActivity() as? MainActivity)?.changeDemoMode(true)
        }) { Text(stringResource(R.string.demo_mode_enable)) } },
        dismissButton = { TextButton(onClick = { confirmDemoEnable = false }) { Text(stringResource(R.string.action_cancel)) } },
    )

    nfcPhase?.let { phase ->
        AlertDialog(onDismissRequest = vm::cancelNfc,
            title = { Text(stringResource(R.string.nfc_scan_title)) },
            text = { Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                androidx.compose.material3.CircularProgressIndicator()
                Text(stringResource(if (phase == md.moldsign.app.nfc.NfcSigningController.Phase.Waiting) R.string.nfc_scan_hold else R.string.nfc_scan_keep))
            } },
            confirmButton = { TextButton(onClick = vm::cancelNfc) { Text(stringResource(R.string.action_cancel)) } })
    }
    pendingPinSave?.let { candidate ->
        LaunchedEffect(candidate) {
            (context.hostActivity() as? androidx.fragment.app.FragmentActivity)?.let { vm.savePin(it, candidate) }
        }
    }
    pending?.let { p ->
        key(p) {
            val pinScope = rememberCoroutineScope()
            var loadingSaved by remember { mutableStateOf(false) }
            PinSheet(
                request = p.request.toPinPromptContent(stringResource(R.string.nfc_another_card)),
                rememberAvailable = vm.pinVaultAvailable && p.request.requester == null,
                onConfirm = { pin, remember -> p.answer(ConsentResult.Pin(pin), remember) },
                onDismiss = { p.answer(ConsentResult.Cancelled) },
                loadingSaved = loadingSaved,
                onUseSaved = if (p.request.certificate?.sha1Hex in savedPinIds) ({
                    pinScope.launch {
                        loadingSaved = true
                        try { (context.hostActivity() as? androidx.fragment.app.FragmentActivity)?.let { vm.useSavedPin(it, p) } }
                        finally { loadingSaved = false }
                    }
                }) else null,
            )
        }
    }
}
