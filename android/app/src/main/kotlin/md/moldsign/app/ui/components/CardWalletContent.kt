package md.moldsign.app.ui.components

data class CardWalletContent(
    val cards: List<IdentityCardContent>,
    val selectedId: String?,
    val empty: EmptyWalletContent,
)
