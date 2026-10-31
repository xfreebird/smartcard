package md.moldsign.app.infrastructure

import md.moldsign.app.application.ReaderGateway

import android.app.Application
import kotlinx.coroutines.CoroutineScope
import md.moldsign.transport.usb.UsbReaderMonitor

/** USB platform adapter. Application policies depend on ReaderGateway only. */
class UsbReaderGateway(app: Application, scope: CoroutineScope) : ReaderGateway {
    private val monitor = UsbReaderMonitor(app, scope)
    override val readers get() = monitor.readers
    override val state get() = monitor.state
    override val transportProvider get() = monitor.transportProvider
    override fun start() = monitor.start()
    override fun stop() = monitor.stop()
    override fun rescan() = monitor.rescan()
    override fun requestPermission(readerId: String?) = monitor.requestPermission(readerId)
}
