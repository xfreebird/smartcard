package md.moldsign.app.presentation

import md.moldsign.app.ui.components.PinPromptContent
import md.moldsign.core.ConsentRequest

fun ConsentRequest.toPinPromptContent() =
    PinPromptContent(certificate.commonName, requester, documentNames, format, attemptsLeft)

fun md.moldsign.app.application.PinRequest.toPinPromptContent(unknownHolder: String) =
    PinPromptContent(certificate?.commonName ?: unknownHolder, requester, documentNames, format, attemptsLeft)
