package md.moldsign.app.ui

import androidx.annotation.StringRes
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CreditCard
import androidx.compose.material.icons.outlined.Draw
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.VerifiedUser
import androidx.compose.material.icons.rounded.Draw
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
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
import md.moldsign.app.MainViewModel
import md.moldsign.app.R
import md.moldsign.app.messageText
import md.moldsign.app.ui.components.PinSheet
import md.moldsign.app.ui.components.StatusLightChip
import md.moldsign.app.ui.screens.ActivityScreen
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
 * Material 3 shell (docs/10 §0.3, §4.5, UX-05): edge-to-edge Scaffold, TopAppBar with the status light chip
 * (tap → Card) and a "Recitește cardul" action, bottom NavigationBar, ExtendedFloatingActionButton
 * "Semnează" on Semnează, PIN in a ModalBottomSheet.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MoldSignRoot(vm: MainViewModel = viewModel()) {
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
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior()

    LaunchedEffect(message) {
        val m = message ?: return@LaunchedEffect
        val text = messageText(context, m)
        vm.consumeMessage()
        if (text.isNotEmpty()) snackbar.showSnackbar(text)
    }

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            TopAppBar(
                // Home shows the public name (UX-12); the other destinations their own title.
                title = { Text(stringResource(if (dest == Dest.Sign) R.string.app_name else dest.label)) },
                actions = {
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
        },
        bottomBar = {
            NavigationBar {
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
                visible = dest == Dest.Sign && canSign,
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
        NavHost(nav, startDestination = Dest.Sign.route) {
            composable(Dest.Sign.route) { SignScreen(vm, padding, onOpenCard = { nav.go(Dest.Card) }) }
            composable(Dest.Verify.route) { VerifyScreen(vm, padding) }
            composable(Dest.Activity.route) { ActivityScreen(vm, padding) }
            composable(Dest.Browser.route) { BrowserScreen(vm, padding, onOpenCard = { nav.go(Dest.Card) }) }
            composable(Dest.Card.route) { CardScreen(vm, padding) }
        }
    }

    pending?.let { p ->
        PinSheet(
            request = p.request,
            rememberAvailable = vm.pinVaultAvailable,
            onConfirm = { pin, _ ->
                // TODO(AND-06): if "Ține minte PIN-ul" is on, PinVault.save(...) after a successful VERIFY.
                p.answer(ConsentResult.Pin(pin))
            },
            onDismiss = { p.answer(ConsentResult.Cancelled) },
        )
    }
}
