package md.moldsign.app.ui

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
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
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
    Card("card", R.string.nav_card, Icons.Outlined.CreditCard),
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
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MoldSignRoot(vm: MainViewModel = viewModel(), demoPage: String? = null, demoGeneration: Int = 0) {
    val captureIntent = LocalContext.current.hostActivity()?.intent
    val captureDialog = if (DemoMode.screenshotCapture(captureIntent)) captureIntent?.getStringExtra("capture_dialog") else null
    md.moldsign.app.ui.components.GovernmentDisclosure(forceVisible = captureDialog == "disclosure")
    var settingsOpen by androidx.compose.runtime.saveable.rememberSaveable { mutableStateOf(false) }
    var settingsTab by androidx.compose.runtime.saveable.rememberSaveable { mutableIntStateOf(0) }
    var confirmDemoEnable by remember { mutableStateOf(false) }
    val nav = rememberNavController()
    val backStack by nav.currentBackStackEntryAsState()
    val dest = Dest.entries.firstOrNull { it.route == backStack?.destination?.route } ?: Dest.Sign
    val liveStatus by vm.status.collectAsStateWithLifecycle()
    val captureProgress = DemoMode.screenshotCapture(captureIntent) && captureIntent?.hasExtra("capture_step") == true
    val status = if (captureProgress) liveStatus.copy(light = md.moldsign.core.StatusLight.Busy, busy = true) else liveStatus
    val items by vm.signItems.collectAsStateWithLifecycle()
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
    LaunchedEffect(shortcutRequest?.id, activeShortcut, working, pending, stamp) {
        val request = shortcutRequest ?: return@LaunchedEffect
        // Do not replace a consent sheet, signature operation or another system picker.
        if (working || pending != null || stamp != null || activeShortcut != null) return@LaunchedEffect
        settingsOpen = false
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

    LaunchedEffect(demoGeneration, captureDialog) {
        if (DemoMode.screenshotCapture(captureIntent)) {
            settingsOpen = captureDialog == "settings" || captureDialog == "about"
            settingsTab = if (captureDialog == "about") 1 else 0
            confirmDemoEnable = captureDialog == "demo-confirm"
        }
    }

    LaunchedEffect(demoPage) {
        Dest.entries.firstOrNull { it.route == demoPage }?.let { nav.go(it) }
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

    LaunchedEffect(Unit) {
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

    BoxWithConstraints(Modifier.fillMaxSize()) {
        val expanded = maxWidth >= 600.dp || (maxWidth >= 480.dp && maxWidth > maxHeight)
        val shortLandscape = maxHeight < 400.dp && maxWidth > maxHeight
        val compactStatus = maxWidth < 400.dp
        val navigationLabelWidth = maxWidth / Dest.entries.size - 4.dp
        Scaffold(
            modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
            topBar = {
                Column {
                TopAppBar(
                    // Home shows the public name (UX-12); the other destinations their own title.
                    title = { Text(stringResource(if (dest == Dest.Sign) R.string.app_name else dest.label), maxLines = 1, overflow = TextOverflow.Ellipsis) },
                    actions = {
                        Box {
                            IconButton(onClick = { toolsOpen = true }) { Icon(Icons.Outlined.MoreVert, contentDescription = stringResource(R.string.action_more)) }
                            DropdownMenu(expanded = toolsOpen, onDismissRequest = { toolsOpen = false }) {
                                DropdownMenuItem(text = { Text(stringResource(R.string.protect_title)) }, onClick = { toolsOpen = false; protectionOpen = true })
                            }
                        }
                        IconButton(onClick = { settingsOpen = true }) {
                            Icon(Icons.Outlined.Settings, contentDescription = stringResource(R.string.demo_mode_settings))
                        }
                        if ((dest == Dest.Sign || dest == Dest.Card || dest == Dest.Browser) && status.wallet.cards.isNotEmpty()) {
                            IconButton(onClick = vm::rereadCards, enabled = !status.busy) {
                                Icon(Icons.Rounded.Refresh, contentDescription = stringResource(R.string.action_reread))
                            }
                        }
                        StatusLightChip(status, onClick = { nav.go(Dest.Card) }, compact = compactStatus)
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
                            selected = dest == d,
                            onClick = { nav.go(d) },
                            icon = { Icon(d.icon, contentDescription = stringResource(d.label)) },
                            alwaysShowLabel = !shortLandscape,
                            label = if (shortLandscape) null else { { Text(stringResource(when (d) { Dest.Activity -> R.string.nav_files; Dest.Sign -> R.string.nav_sign_short; Dest.Verify -> R.string.nav_verify_short; else -> d.label }), modifier = Modifier.requiredWidth(navigationLabelWidth), textAlign = TextAlign.Center, maxLines = 1, softWrap = false, overflow = TextOverflow.Ellipsis) } },
                        )
                    }
                }
            },
            floatingActionButton = {
                // Never an accent FAB while signing is impossible: only with documents and a ready, idle card. Otherwise
                // the Semnează screen says why under the list, and the step card shows a running signature.
                val canSign = items.isNotEmpty() && status.wallet.selectedCard?.isReady == true && !status.busy && !working
                AnimatedVisibility(
                    visible = !expanded && dest == Dest.Sign && canSign,
                    enter = scaleIn(tween(200)) + fadeIn(tween(200)),
                    exit = scaleOut(tween(150)) + fadeOut(tween(150)),
                ) {
                    ExtendedFloatingActionButton(
                        onClick = vm::sign,
                        icon = { Icon(Icons.Rounded.Draw, contentDescription = null) },
                        text = { Text(pluralStringResource(R.plurals.sign_n, items.size, items.size)) },
                    )
                }
            },
            snackbarHost = { SnackbarHost(snackbar) },
        ) { padding ->
            Row(Modifier.fillMaxSize().padding(padding)) {
                if (expanded && !shortLandscape) {
                    NavigationRail(
                        modifier = Modifier.fillMaxHeight().width(96.dp)
                            .verticalScroll(rememberScrollState()).padding(vertical = 12.dp),
                        windowInsets = WindowInsets(0, 0, 0, 0),
                    ) {
                        Dest.entries.forEach { d ->
                            NavigationRailItem(
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
                        SignScreen(vm, PaddingValues(0.dp), onOpenCard = { nav.go(Dest.Card) }, onOpenDocuments = { nav.go(Dest.Activity) }, expanded = expanded)
                    }
                    composable(Dest.Verify.route) { VerifyScreen(vm, PaddingValues(0.dp)) }
                    composable(Dest.Activity.route) { ActivityScreen(vm, PaddingValues(0.dp), onVerify = { uri -> nav.go(Dest.Verify); vm.pickForVerify(uri) }) }
                    composable(Dest.Browser.route) { BrowserScreen(vm, PaddingValues(0.dp), onOpenCard = { nav.go(Dest.Card) }) }
                    composable(Dest.Card.route) { CardScreen(vm, PaddingValues(0.dp)) }
                }
            }
        }
    }

    if (settingsOpen) AlertDialog(
        onDismissRequest = { settingsOpen = false },
        title = { Text(stringResource(R.string.demo_mode_settings)) },
        text = {
            Column(Modifier.heightIn(max = 480.dp)) {
                androidx.compose.material3.TabRow(selectedTabIndex = settingsTab) {
                    androidx.compose.material3.Tab(selected = settingsTab == 0, onClick = { settingsTab = 0 }, text = { Text(stringResource(R.string.settings_general)) })
                    androidx.compose.material3.Tab(selected = settingsTab == 1, onClick = { settingsTab = 1 }, text = { Text(stringResource(R.string.about_title)) })
                }
                Spacer(Modifier.size(12.dp))
                if (settingsTab == 0) {
                    Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState())) {
                        md.moldsign.app.ui.components.AppSettings(vm, enabled = !working && !status.busy && pending == null && stamp == null)
                        Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                            Text(stringResource(R.string.demo_mode_title), modifier = Modifier.weight(1f))
                            Switch(checked = vm.demoMode, enabled = !working && !status.busy && pending == null && stamp == null,
                                onCheckedChange = { enabled ->
                                    settingsOpen = false
                                    if (enabled) confirmDemoEnable = true
                                    else (context.hostActivity() as? MainActivity)?.changeDemoMode(false)
                                })
                        }
                        Text(stringResource(R.string.demo_mode_description), style = MaterialTheme.typography.bodyMedium)
                    }
                } else {
                    Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState())) { AboutContent() }
                }
            }
        },
        confirmButton = { TextButton(onClick = { settingsOpen = false }) { Text(stringResource(R.string.action_close)) } },
    )

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

    pending?.let { p ->
        PinSheet(
            request = p.request,
            rememberAvailable = false,
            onConfirm = { pin, _ ->
                // TODO(AND-06): if "Ține minte PIN-ul" is on, PinVault.save(...) after a successful VERIFY.
                p.answer(ConsentResult.Pin(pin))
            },
            onDismiss = { p.answer(ConsentResult.Cancelled) },
        )
    }
}
