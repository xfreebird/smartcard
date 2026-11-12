package md.moldsign.app.presentation

import md.moldsign.app.ui.components.PinPromptContent
import md.moldsign.core.ConsentRequest

fun ConsentRequest.toPinPromptContent() =
    PinPromptContent(certificate.commonName, requester, documentNames, format, attemptsLeft)
