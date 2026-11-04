package md.moldsign.app.ui

import androidx.annotation.StringRes
import android.content.Intent
import md.moldsign.app.DemoMode
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
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
import md.moldsign.core.ConsentResult

private enum class Dest(val route: String, @StringRes val label: Int, val icon: ImageVector) {
    Sign("sign", R.string.nav_sign, Icons.Outlined.Draw),
    Verify("verify", R.string.nav_verify, Icons.Outlined.VerifiedUser),
    Activity("activity", R.string.nav_activity, Icons.Outlined.History),
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
    md.moldsign.app.ui.components.GovernmentDisclosure()
    var settingsOpen by remember { mutableStateOf(false) }
    var settingsTab by remember { mutableIntStateOf(0) }
    var confirmDemoEnable by remember { mutableStateOf(false) }
    val nav = rememberNavController()
    val backStack by nav.currentBackStackEntryAsState()
    val dest = Dest.entries.firstOrNull { it.route == backStack?.destination?.route } ?: Dest.Sign
    val status by vm.status.collectAsStateWithLifecycle()
    val items by vm.signItems.collectAsStateWithLifecycle()
    val working by vm.working.collectAsStateWithLifecycle()
    val pending by vm.pendingConsent.collectAsStateWithLifecycle()
    val message by vm.message.collectAsStateWithLifecycle()
    val snackbar = remember { SnackbarHostState() }
    val context = LocalContext.current
    val openLabel = stringResource(R.string.action_open)
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior()

    LaunchedEffect(demoPage) {
        Dest.entries.firstOrNull { it.route == demoPage }?.let { nav.go(it) }
    }

    LaunchedEffect(dest.route, status.wallet, items, working, pending, demoGeneration) {
        val activity = context as? android.app.Activity
        val isDemo = activity?.intent?.hasExtra("demo") == true
        val isPinDemo = activity?.intent?.getStringExtra("demo") == "pin"
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
        val expanded = maxWidth >= 600.dp
        Scaffold(
            modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
            topBar = {
                Column {
                TopAppBar(
                    // Home shows the public name (UX-12); the other destinations their own title.
                    title = { Text(stringResource(if (dest == Dest.Sign) R.string.app_name else dest.label)) },
                    actions = {
                        IconButton(onClick = { settingsOpen = true }) {
                            Icon(Icons.Outlined.Settings, contentDescription = stringResource(R.string.demo_mode_settings))
                        }
                        if ((dest == Dest.Sign || dest == Dest.Card || dest == Dest.Browser) && status.wallet.cards.isNotEmpty()) {
                            IconButton(onClick = vm::rereadCards, enabled = !status.busy) {
                                Icon(Icons.Rounded.Refresh, contentDescription = stringResource(R.string.action_reread))
                            }
                        }
                        StatusLightChip(status, onClick = { nav.go(Dest.Card) })
                        Spacer(Modifier.width(Tokens.S3))
                    },
                    scrollBehavior = scrollBehavior,
                )
                if (vm.demoMode && !DemoMode.screenshotCapture((context as? android.app.Activity)?.intent)) Surface(color = MaterialTheme.colorScheme.secondaryContainer) {
                    Text(stringResource(R.string.demo_mode_disclaimer),
                        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp),
                        style = MaterialTheme.typography.labelLarge)
                }
                }
            },
            bottomBar = {
                if (!expanded) NavigationBar {
                    Dest.entries.forEach { d ->
                        NavigationBarItem(
                            selected = dest == d,
                            onClick = { nav.go(d) },
                            icon = { Icon(d.icon, contentDescription = null) },
                            label = { Text(stringResource(d.label)) },
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
                if (expanded) {
                    NavigationRail(
                        modifier = Modifier.fillMaxHeight().width(96.dp)
                            .verticalScroll(rememberScrollState()).padding(vertical = 12.dp),
                        windowInsets = WindowInsets(0, 0, 0, 0),
                    ) {
                        Dest.entries.forEach { d ->
                            NavigationRailItem(
                                selected = dest == d,
                                onClick = { nav.go(d) },
                                icon = { Icon(d.icon, contentDescription = null) },
                                label = { Text(stringResource(d.label)) },
                            )
                        }
                    }
                }
                // Scaffold insets are consumed once around the rail and destination, never once per pane.
                NavHost(nav, startDestination = Dest.Sign.route, modifier = Modifier.weight(1f).fillMaxHeight()) {
                    composable(Dest.Sign.route) {
                        SignScreen(vm, PaddingValues(0.dp), onOpenCard = { nav.go(Dest.Card) }, expanded = expanded)
                    }
                    composable(Dest.Verify.route) { VerifyScreen(vm, PaddingValues(0.dp)) }
                    composable(Dest.Activity.route) { ActivityScreen(vm, PaddingValues(0.dp)) }
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
            Column {
                androidx.compose.material3.TabRow(selectedTabIndex = settingsTab) {
                    androidx.compose.material3.Tab(selected = settingsTab == 0, onClick = { settingsTab = 0 }, text = { Text(stringResource(R.string.settings_general)) })
                    androidx.compose.material3.Tab(selected = settingsTab == 1, onClick = { settingsTab = 1 }, text = { Text(stringResource(R.string.about_title)) })
                }
                Spacer(Modifier.size(12.dp))
                if (settingsTab == 0) {
                    Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                        Text(stringResource(R.string.demo_mode_title), modifier = Modifier.weight(1f))
                        Switch(checked = vm.demoMode, enabled = !working && !status.busy && pending == null,
                            onCheckedChange = { enabled ->
                                settingsOpen = false
                                if (enabled) confirmDemoEnable = true
                                else (context as? MainActivity)?.changeDemoMode(false)
                            })
                    }
                    Text(stringResource(R.string.demo_mode_description), style = MaterialTheme.typography.bodyMedium)
                } else {
                    AboutContent()
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
            (context as? MainActivity)?.changeDemoMode(true)
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
