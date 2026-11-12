package md.moldsign.app.ui.components

sealed interface EmptyWalletContent {
    data object Connect : EmptyWalletContent
    data class Permission(val id: String, val name: String) : EmptyWalletContent
    data class Insert(val name: String) : EmptyWalletContent
    data class Error(val name: String) : EmptyWalletContent
}
