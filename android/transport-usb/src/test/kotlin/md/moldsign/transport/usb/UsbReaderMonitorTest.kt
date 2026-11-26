package md.moldsign.transport.usb

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import md.moldsign.core.CardError
import md.moldsign.core.ReaderSlot
import md.moldsign.core.ReaderState
import md.moldsign.core.decodeHex
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import java.util.concurrent.ConcurrentHashMap

class UsbReaderMonitorTest {
    private class Host : UsbHost {
        val attached = mutableListOf<UsbHost.Reader>()
        val permitted = ConcurrentHashMap.newKeySet<String>()
        val simulated = ConcurrentHashMap<String, SimulatedCcidReader>()
        val failOpen = ConcurrentHashMap.newKeySet<String>()
        val requests = mutableListOf<String>()
        var events: UsbHost.Events? = null
        var listening = false

        fun plug(id: String, name: String = "miniLector EVO", permission: Boolean = true): SimulatedCcidReader {
            val reader = SimulatedCcidReader(apdu = { it + "9000".decodeHex() }).apply { atr = SimulatedCcidReader.T0_ATR }
            simulated[id] = reader
            attached += UsbHost.Reader(id, name)
            if (permission) permitted += id
            return reader
        }

        override fun readers() = attached.toList()
        override fun hasPermission(reader: UsbHost.Reader) = reader.id in permitted
        override fun open(reader: UsbHost.Reader): CcidTransport {
            if (reader.id in failOpen) throw CardError.NoReader("Cannot open ${reader.name}")
            return CcidTransport(requireNotNull(simulated[reader.id]), null, reader.name, SimulatedCcidReader.SHORT_APDU, 100)
        }
        override fun requestPermission(reader: UsbHost.Reader) { synchronized(requests) { requests += reader.id } }
        override fun listen(events: UsbHost.Events) { this.events = events; listening = true }
        override fun stopListening() { listening = false }
    }

    private val host = Host()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val monitor = UsbReaderMonitor(host, scope, pollIntervalMs = 10)

    @After fun tearDown() {
        monitor.stop()
        scope.cancel()
    }

    private fun readersUntil(predicate: (List<ReaderSlot>) -> Boolean): List<ReaderSlot> =
        runBlocking { withTimeout(5_000) { monitor.readers.first(predicate) } }

    private fun stateUntil(predicate: (ReaderState) -> Boolean): ReaderState =
        runBlocking { withTimeout(5_000) { monitor.state.first(predicate) } }

    @Test fun readerWithCardIsPolledAndGetsAGeneration() {
        host.plug("/dev/bus/usb/001/002")
        monitor.start()
        monitor.start() // idempotent
        assertTrue(host.listening)
        val slot = readersUntil { it.singleOrNull()?.state == ReaderSlot.State.Card }.single()
        assertEquals("miniLector EVO", slot.name)
        assertTrue(slot.generation > 0)
        assertEquals(ReaderState.CardPresent("miniLector EVO"), stateUntil { it is ReaderState.CardPresent })
    }

    @Test fun removingAndReinsertingTheCardChangesTheGeneration() {
        val reader = host.plug("r1")
        monitor.start()
        val first = readersUntil { it.singleOrNull()?.state == ReaderSlot.State.Card }.single().generation
        reader.cardPresent = false
        readersUntil { it.single().state == ReaderSlot.State.Empty }
        assertEquals(ReaderState.Empty("miniLector EVO"), stateUntil { it is ReaderState.Empty })
        reader.cardPresent = true
        val second = readersUntil { it.single().state == ReaderSlot.State.Card }.single().generation
        assertTrue(second != first)
    }

    @Test fun permissionIsRequestedAndGrantedThroughEvents() {
        host.plug("r1", permission = false)
        monitor.start()
        readersUntil { it.singleOrNull()?.state == ReaderSlot.State.PermissionRequired }
        assertEquals(ReaderState.PermissionRequired("miniLector EVO"), stateUntil { it is ReaderState.PermissionRequired })
        monitor.requestPermission()
        monitor.requestPermission("r1")
        // An unknown id falls back to the first reader still waiting for access.
        monitor.requestPermission("unknown")
        assertEquals(listOf("r1", "r1", "r1"), host.requests)

        host.events!!.permission(host.attached.single(), granted = false)
        assertEquals(ReaderSlot.State.PermissionRequired, monitor.readers.value.single().state)
        host.permitted += "r1"
        host.events!!.permission(host.attached.single(), granted = true)
        readersUntil { it.single().state == ReaderSlot.State.Card }
    }

    @Test fun identicalReadersAreNumberedAndDetachedOnes() {
        monitor.start()
        host.plug("r1")
        host.events!!.attached(host.attached[0])
        host.plug("r2")
        host.events!!.attached(host.attached[1])
        val both = readersUntil { list -> list.size == 2 && list.all { it.state == ReaderSlot.State.Card } }
        assertEquals(listOf("miniLector EVO", "miniLector EVO #2"), both.map { it.name })
        // A repeated attach for a reader that is already open is ignored.
        host.events!!.attached(host.attached[0])
        host.events!!.detached("r1")
        assertEquals(listOf("r2"), readersUntil { it.size == 1 }.map { it.id })
        host.events!!.detached("unknown")
        host.attached.removeAt(0)
        host.attached.clear()
        monitor.rescan()
        readersUntil { it.isEmpty() }
        assertEquals(ReaderState.NoReader, monitor.state.value)
    }

    @Test fun openFailureShowsAnError() {
        host.plug("r1")
        host.failOpen += "r1"
        monitor.start()
        readersUntil { it.singleOrNull()?.state == ReaderSlot.State.Error }
        assertEquals(ReaderState.Error("miniLector EVO"), stateUntil { it is ReaderState.Error })
    }

    @Test fun slotStatusFailureShowsAnError() {
        val reader = host.plug("r1")
        monitor.start()
        readersUntil { it.singleOrNull()?.state == ReaderSlot.State.Card }
        reader.receiveTimeout = true
        readersUntil { it.single().state == ReaderSlot.State.Error }
    }

    @Test fun sessionsGoToTheNamedReaderAndPausePolling() {
        host.plug("r1")
        host.plug("r2")
        monitor.start()
        readersUntil { list -> list.size == 2 && list.all { it.state == ReaderSlot.State.Card } }

        val session = monitor.transportProvider.open("r2")
        assertEquals("miniLector EVO", session.readerName)
        assertEquals(ReaderState.Busy, stateUntil { it == ReaderState.Busy })
        assertArrayEquals("00A4000C9000".decodeHex(), session.transmit("00A4000C".decodeHex()))
        session.close()
        stateUntil { it is ReaderState.CardPresent }

        monitor.transportProvider.open(null).close()
        try { monitor.transportProvider.open("missing"); fail("unknown reader") } catch (_: CardError.NoReader) {}
    }

    @Test fun sessionWithoutAccessOrCardIsRefused() {
        host.plug("r1", permission = false)
        monitor.start()
        readersUntil { it.singleOrNull()?.state == ReaderSlot.State.PermissionRequired }
        try { monitor.transportProvider.open("r1"); fail("no USB access") } catch (error: CardError.NoReader) {
            assertTrue(error.message!!.contains("no USB access"))
        }
        try { monitor.transportProvider.open(null); fail("no reader with access") } catch (_: CardError.NoReader) {}

        val empty = UsbReaderMonitor(Host(), scope, 10)
        try { empty.transportProvider.open(null); fail("no reader") } catch (_: CardError.NoReader) {}
    }

    @Test fun failedSessionResumesPolling() {
        val reader = host.plug("r1")
        monitor.start()
        readersUntil { it.singleOrNull()?.state == ReaderSlot.State.Card }
        reader.failNext = Ccid.ERR_HW_ERROR
        try { monitor.transportProvider.open("r1"); fail("power-on failed") } catch (_: CardError.CardNotResponding) {}
        stateUntil { it is ReaderState.CardPresent }
    }

    @Test fun stopReleasesEveryReader() {
        val reader = host.plug("r1")
        monitor.start()
        readersUntil { it.singleOrNull()?.state == ReaderSlot.State.Card }
        monitor.stop()
        assertTrue(!host.listening)
        readersUntil { it.isEmpty() }
        runBlocking { withTimeout(5_000) { while (!reader.released) kotlinx.coroutines.delay(5) } }
    }
}
