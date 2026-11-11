package md.moldsign.app.presentation

import android.net.Uri
import androidx.annotation.StringRes
import md.moldsign.app.application.AppStatus

sealed interface UiMessage {
    data class Error(val error: Throwable) : UiMessage
    data class Text(@StringRes val res: Int) : UiMessage

    /** A signed document was saved at [uri]: the snackbar offers to open it. */
    data class Saved(@StringRes val res: Int, val uri: Uri) : UiMessage

    /** "Why can't I sign": the status light's text. */
    data class Status(val status: AppStatus) : UiMessage
}
