package md.moldsign.transport.usb

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestCoroutineScheduler
import md.moldsign.core.CardError
import md.moldsign.core.ReaderSlot
import md.moldsign.core.ReaderState
import md.moldsign.core.decodeHex
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

/**
 * The monitor on virtual time: polling, opening and closing run on a test dispatcher, so every state is reached
 * by advancing the clock, never by waiting on threads.
 */
class UsbReaderMonitorTest {
    private class Host : UsbHost {
        val attached = mutableListOf<UsbHost.Reader>()
        val permitted = mutableSetOf<String>()
        val simulated = HashMap<String, SimulatedCcidReader>()
        val failOpen = mutableSetOf<String>()
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
        override fun requestPermission(reader: UsbHost.Reader) { requests += reader.id }
        override fun listen(events: UsbHost.Events) { this.events = events; listening = true }
        override fun stopListening() { listening = false }
    }

    private val host = Host()
    private val scheduler = TestCoroutineScheduler()
    private val dispatcher = StandardTestDispatcher(scheduler)
    private val scope = CoroutineScope(SupervisorJob() + dispatcher)
    private val monitor = UsbReaderMonitor(host, scope, pollIntervalMs = POLL, io = dispatcher)

    @After fun tearDown() {
        monitor.stop()
        scheduler.runCurrent()
        scope.cancel()
    }

    /** Runs whatever is due now (opening, the first poll). */
    private fun settle() = scheduler.runCurrent()

    /** One more poll period. */
    private fun nextPoll() { scheduler.advanceTimeBy(POLL); scheduler.runCurrent() }

    private val slot get() = monitor.readers.value.single()

    @Test fun readerWithCardIsPolledAndGetsAGeneration() {
        host.plug("/dev/bus/usb/001/002")
        monitor.start()
        monitor.start() // idempotent
        assertTrue(host.listening)
        // Attached readers are listed before the first poll, waiting for their transport.
        assertEquals(ReaderSlot.State.PermissionRequired, slot.state)
        settle()
        assertEquals(ReaderSlot.State.Card, slot.state)
        assertEquals("miniLector EVO", slot.name)
        assertTrue(slot.generation > 0)
        assertEquals(ReaderState.CardPresent("miniLector EVO"), monitor.state.value)
        // Unchanged presence keeps the same generation.
        val generation = slot.generation
        nextPoll()
        assertEquals(generation, slot.generation)
    }

    @Test fun removingAndReinsertingTheCardChangesTheGeneration() {
        val reader = host.plug("r1")
        monitor.start()
        settle()
        val first = slot.generation
        reader.cardPresent = false
        nextPoll()
        assertEquals(ReaderSlot.State.Empty, slot.state)
        assertEquals(ReaderState.Empty("miniLector EVO"), monitor.state.value)
        reader.cardPresent = true
        nextPoll()
        assertEquals(ReaderSlot.State.Card, slot.state)
        assertTrue(slot.generation != first)
    }

    @Test fun permissionIsRequestedAndGrantedThroughEvents() {
        host.plug("r1", permission = false)
        monitor.start()
        settle()
        assertEquals(ReaderSlot.State.PermissionRequired, slot.state)
        assertEquals(ReaderState.PermissionRequired("miniLector EVO"), monitor.state.value)
        monitor.requestPermission()
        monitor.requestPermission("r1")
        // An unknown id falls back to the first reader still waiting for access.
        monitor.requestPermission("unknown")
        assertEquals(listOf("r1", "r1", "r1"), host.requests)

        host.events!!.permission(host.attached.single(), granted = false)
        assertEquals(ReaderSlot.State.PermissionRequired, slot.state)
        host.permitted += "r1"
        host.events!!.permission(host.attached.single(), granted = true)
        settle()
        assertEquals(ReaderSlot.State.Card, slot.state)
        // Once granted nobody waits for access any more.
        monitor.requestPermission()
        assertEquals(3, host.requests.size)
    }

    @Test fun permissionForAReaderSeenOnlyThroughTheResult() {
        monitor.start()
        host.plug("late")
        host.events!!.permission(host.attached.single(), granted = true)
        settle()
        assertEquals(listOf("late"), monitor.readers.value.map { it.id })
        assertEquals(ReaderSlot.State.Card, slot.state)
    }

    @Test fun identicalReadersAreNumberedAndDetachedOnes() {
        monitor.start()
        host.plug("r1")
        host.events!!.attached(host.attached[0])
        host.plug("r2")
        host.events!!.attached(host.attached[1])
        settle()
        assertEquals(listOf("miniLector EVO", "miniLector EVO #2"), monitor.readers.value.map { it.name })
        assertTrue(monitor.readers.value.all { it.state == ReaderSlot.State.Card })
        // A repeated attach for a reader that is already open is ignored.
        host.events!!.attached(host.attached[0])
        settle()
        assertEquals(2, monitor.readers.value.size)
        host.events!!.detached("r1")
        assertEquals(listOf("r2"), monitor.readers.value.map { it.id })
        host.events!!.detached("unknown")
        host.attached.clear()
        monitor.rescan()
        settle()
        assertTrue(monitor.readers.value.isEmpty())
        assertEquals(ReaderState.NoReader, monitor.state.value)
        assertTrue(host.simulated.values.all { it.released })
    }

    @Test fun openFailureShowsAnError() {
        host.plug("r1")
        host.failOpen += "r1"
        monitor.start()
        settle()
        assertEquals(ReaderSlot.State.Error, slot.state)
        assertEquals(ReaderState.Error("miniLector EVO"), monitor.state.value)
    }

    @Test fun slotStatusFailureShowsAnErrorAndRecovers() {
        val reader = host.plug("r1")
        monitor.start()
        settle()
        reader.receiveTimeout = true
        nextPoll()
        assertEquals(ReaderSlot.State.Error, slot.state)
        reader.receiveTimeout = false
        nextPoll()
        assertEquals(ReaderSlot.State.Card, slot.state)
    }

    @Test fun sessionsGoToTheNamedReaderAndPausePolling() {
        host.plug("r1")
        val second = host.plug("r2")
        monitor.start()
        settle()

        val session = monitor.transportProvider.open("r2")
        assertEquals("miniLector EVO", session.readerName)
        assertArrayEquals(second.atr, session.answerToReset())
        assertEquals(ReaderState.Busy, monitor.state.value)
        // Polling pauses for the reader in session: a removed card is not noticed meanwhile.
        second.cardPresent = false
        nextPoll()
        assertEquals(ReaderState.Busy, monitor.state.value)
        second.cardPresent = true
        assertArrayEquals("00A4000C9000".decodeHex(), session.transmit("00A4000C".decodeHex()))
        session.close()
        settle()
        assertTrue(monitor.state.value is ReaderState.CardPresent)

        monitor.transportProvider.open(null).close()
        settle()
        try { monitor.transportProvider.open("missing"); fail("unknown reader") } catch (_: CardError.NoReader) {}
    }

    @Test fun sessionWithoutAccessOrCardIsRefused() {
        host.plug("r1", permission = false)
        monitor.start()
        settle()
        try { monitor.transportProvider.open("r1"); fail("no USB access") } catch (error: CardError.NoReader) {
            assertTrue(error.message!!.contains("no USB access"))
        }
        try { monitor.transportProvider.open(null); fail("no reader with access") } catch (_: CardError.NoReader) {}

        val empty = UsbReaderMonitor(Host(), scope, POLL, dispatcher)
        try { empty.transportProvider.open(null); fail("no reader") } catch (_: CardError.NoReader) {}
    }

    @Test fun firstReaderWithAccessIsUsedWhenNoCardIsPresent() {
        val reader = host.plug("r1")
        reader.cardPresent = false
        monitor.start()
        settle()
        assertEquals(ReaderSlot.State.Empty, slot.state)
        reader.cardPresent = true
        monitor.transportProvider.open(null).use { assertEquals("miniLector EVO", it.readerName) }
    }

    @Test fun failedSessionResumesPolling() {
        val reader = host.plug("r1")
        monitor.start()
        settle()
        reader.failNext = Ccid.ERR_HW_ERROR
        try { monitor.transportProvider.open("r1"); fail("power-on failed") } catch (_: CardError.CardNotResponding) {}
        settle()
        assertEquals(ReaderState.CardPresent("miniLector EVO"), monitor.state.value)
        reader.cardPresent = false
        nextPoll()
        assertEquals(ReaderSlot.State.Empty, slot.state)
    }

    @Test fun stopReleasesEveryReader() {
        val reader = host.plug("r1")
        monitor.start()
        settle()
        monitor.stop()
        assertFalse(host.listening)
        settle()
        assertTrue(monitor.readers.value.isEmpty())
        assertTrue(reader.released)
        monitor.stop() // idempotent
    }

    private companion object { const val POLL = 1_000L }
}
