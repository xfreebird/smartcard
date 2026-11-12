package md.moldsign.app.ui.components

data class PinPromptContent(
    val holder: String,
    val requester: String?,
    val documentNames: List<String>,
    val format: String,
    val attemptsLeft: Int?,
)
