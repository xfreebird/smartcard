package md.moldsign.app.application

import kotlinx.coroutines.flow.StateFlow
import md.moldsign.core.ReaderSlot
import md.moldsign.core.ReaderState
import md.moldsign.core.TransportProvider

/** Application-owned reader port; USB and deterministic fixtures implement the same contract. */
interface ReaderGateway {
    val readers: StateFlow<List<ReaderSlot>>
    val state: StateFlow<ReaderState>
    val transportProvider: TransportProvider
    fun start()
    fun stop()
    fun rescan()
    fun requestPermission(readerId: String?)
}
