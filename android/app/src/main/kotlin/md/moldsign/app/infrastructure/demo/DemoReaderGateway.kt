package md.moldsign.app.infrastructure.demo

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import md.moldsign.app.application.ReaderGateway
import md.moldsign.core.*
import java.util.Date

/** This adapter never initializes Android's USB service and can never open an APDU transport. */
internal class DemoReaderGateway : ReaderGateway {
    override val readers = MutableStateFlow(DemoFixtures.readers).asStateFlow()
    override val state = MutableStateFlow<ReaderState>(ReaderState.CardPresent("Demo reader 1")).asStateFlow()
    override val transportProvider = TransportProvider { throw CardError.NoReader() }
    override fun start() = Unit
    override fun stop() = Unit
    override fun rescan() = Unit
    override fun requestPermission(readerId: String?) = Unit
}
