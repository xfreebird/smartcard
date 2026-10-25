package md.moldsign.app.ui

import androidx.annotation.StringRes
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CreditCard
import androidx.compose.material.icons.outlined.Draw
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.VerifiedUser
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import md.moldsign.app.MainViewModel
import md.moldsign.app.R
import md.moldsign.app.messageText
import md.moldsign.app.ui.components.PinSheet
import md.moldsign.app.ui.components.ReaderStatusChip
import md.moldsign.app.ui.screens.BrowserScreen
import md.moldsign.app.ui.screens.CardScreen
import md.moldsign.app.ui.screens.SignScreen
import md.moldsign.app.ui.screens.VerifyScreen
import md.moldsign.core.ConsentResult
import md.moldsign.core.ReaderState

private enum class Dest(val route: String, @StringRes val label: Int, val icon: ImageVector) {
    Sign("sign", R.string.nav_sign, Icons.Outlined.Draw),
    Verify("verify", R.string.nav_verify, Icons.Outlined.VerifiedUser),
    Browser("browser", R.string.nav_browser, Icons.Outlined.Language),
    Card("card", R.string.nav_card, Icons.Outlined.CreditCard),
}

/** docs/10 §4.5: top app bar with the reader chip, bottom NavigationBar, FAB "Semnează" on Semnează. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MoldSignRoot(vm: MainViewModel = viewModel()) {
    val nav = rememberNavController()
    val backStack by nav.currentBackStackEntryAsState()
    val route = backStack?.destination?.route ?: Dest.Sign.route
    val readerState by vm.readerState.collectAsStateWithLifecycle()
    val signDoc by vm.signDoc.collectAsStateWithLifecycle()
    val working by vm.working.collectAsStateWithLifecycle()
    val pending by vm.pendingConsent.collectAsStateWithLifecycle()
    val message by vm.message.collectAsStateWithLifecycle()
    val snackbar = remember { SnackbarHostState() }
    val context = LocalContext.current

    LaunchedEffect(message) {
        val m = message ?: return@LaunchedEffect
        val text = messageText(context, m)
        vm.consumeMessage()
        if (text.isNotEmpty()) snackbar.showSnackbar(text)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.app_name)) },
                actions = { ReaderStatusChip(readerState) },
            )
        },
        bottomBar = {
            NavigationBar {
                Dest.entries.forEach { d ->
                    NavigationBarItem(
                        selected = route == d.route,
                        onClick = {
                            nav.navigate(d.route) {
                                popUpTo(nav.graph.findStartDestination().id) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { Icon(d.icon, contentDescription = null) },
                        label = { Text(stringResource(d.label)) },
                    )
                }
            }
        },
        floatingActionButton = {
            if (route == Dest.Sign.route && signDoc != null) {
                val enabled = !working && readerState is ReaderState.CardPresent
                ExtendedFloatingActionButton(
                    onClick = { if (enabled) vm.sign() },
                    icon = { Icon(Icons.Outlined.Draw, contentDescription = null) },
                    text = { Text(stringResource(R.string.action_sign)) },
                    expanded = true,
                )
            }
        },
        snackbarHost = { SnackbarHost(snackbar) },
    ) { padding ->
        NavHost(nav, startDestination = Dest.Sign.route) {
            composable(Dest.Sign.route) { SignScreen(vm, padding) }
            composable(Dest.Verify.route) { VerifyScreen(vm, padding) }
            composable(Dest.Browser.route) { BrowserScreen(vm, padding) }
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
