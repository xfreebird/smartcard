package md.moldsign.app.nfc

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

/** Reader-mode ownership decisions, independent of Android: who may disable reader mode, and when. */
class NfcReaderModeGateTest {
    private class Radio : NfcReaderModeGate.Radio<String, String> {
        val calls = mutableListOf<String>()
        var onTag: ((String) -> Unit)? = null
        var failEnable = false
        var present = true
        override fun enable(host: String, onTag: (String) -> Unit) {
            if (failEnable) throw IllegalStateException("not resumed")
            calls += "enable:$host"
            this.onTag = onTag
        }
        override fun disable(host: String) { calls += "disable:$host" }
        override fun ignore(tag: String): Boolean { calls += "ignore:$tag"; return present }
    }

    private class Waiting : NfcReaderModeGate.Route<String> {
        val received = mutableListOf<String>()
        override fun deliver(tag: String) { received += tag }
    }

    private val radio = Radio()
    private val gate = NfcReaderModeGate(radio)

    @Test fun cardStillInTheFieldKeepsReaderModeAfterEveryOutcome() {
        val session = Waiting()
        gate.open("activity", session)
        radio.onTag!!("card")
        assertEquals(listOf("card"), session.received)

        // Signature received, failure, cancel or close: the eID may still be on the phone.
        assertTrue(gate.finished(session))
        assertTrue(gate.active)
        assertTrue(gate.holdingTag)
        assertEquals(listOf("enable:activity"), radio.calls)

        // Later discoveries are absorbed: nothing is routed and nothing reaches the system dispatcher.
        radio.onTag!!("card-again")
        assertEquals(listOf("card"), session.received)
        assertEquals(listOf("enable:activity"), radio.calls)
    }

    @Test fun pauseIgnoresTheHeldCardBeforeReleasingReaderMode() {
        val session = Waiting()
        gate.open("activity", session)
        radio.onTag!!("card")
        gate.finished(session)

        gate.paused("activity")
        assertEquals(listOf("enable:activity", "ignore:card", "disable:activity"), radio.calls)
        assertFalse(gate.active)
        assertFalse(gate.holdingTag)

        // A released gate ignores late callbacks and repeated pauses.
        radio.onTag!!("late")
        gate.paused("activity")
        assertFalse(gate.holdingTag)
        assertEquals(3, radio.calls.size)
    }

    @Test fun sessionWithoutCardReleasesReaderModeImmediately() {
        val session = Waiting()
        gate.open("activity", session)
        // Timeout or cancel while waiting: nothing is in the field.
        assertFalse(gate.finished(session))
        assertEquals(listOf("enable:activity", "disable:activity"), radio.calls)
        assertFalse(gate.active)
    }

    @Test fun nextSessionReceivesTheHeldCardAgainWithoutReenablingReaderMode() {
        val first = Waiting()
        gate.open("activity", first)
        radio.onTag!!("card")
        gate.finished(first)

        val second = Waiting()
        gate.open("activity", second)
        // The platform is asked to present the card again; reader mode never went off in between.
        assertEquals(listOf("enable:activity", "ignore:card"), radio.calls)
        assertFalse(gate.holdingTag)
        radio.onTag!!("card-rediscovered")
        assertEquals(listOf("card-rediscovered"), second.received)
        assertTrue(first.received == listOf("card"))
    }

    @Test fun nextSessionAfterRemovalWaitsAndReleasesOnTimeout() {
        val first = Waiting()
        gate.open("activity", first)
        radio.onTag!!("card")
        gate.finished(first)
        radio.present = false

        val second = Waiting()
        gate.open("activity", second)
        assertFalse(gate.finished(second))
        assertEquals(listOf("enable:activity", "ignore:card", "disable:activity"), radio.calls)
    }

    @Test fun staleSessionCleanupNeverReleasesANewerScan() {
        val first = Waiting()
        gate.open("activity", first)
        val second = Waiting()
        gate.open("activity", second)
        // The first session's queued cleanup runs after the next scan opened.
        assertFalse(gate.finished(first))
        assertTrue(gate.active)
        assertEquals(listOf("enable:activity"), radio.calls)
        radio.onTag!!("card")
        assertEquals(listOf("card"), second.received)
        assertTrue(first.received.isEmpty())
    }

    @Test fun newHostReleasesTheOldOneFirst() {
        val first = Waiting()
        gate.open("old", first)
        radio.onTag!!("card")
        gate.finished(first)

        gate.open("new", Waiting())
        assertEquals(listOf("enable:old", "ignore:card", "disable:old", "enable:new"), radio.calls)
        gate.paused("old")
        assertTrue(gate.active)
    }

    @Test fun enableFailureLeavesNothingOwned() {
        radio.failEnable = true
        val session = Waiting()
        try {
            gate.open("activity", session)
            fail("enable must fail")
        } catch (_: IllegalStateException) {}
        assertFalse(gate.active)
        assertFalse(gate.finished(session))
        assertTrue(radio.calls.isEmpty())
    }

    @Test fun platformErrorsDuringReleaseAreContained() {
        val failing = object : NfcReaderModeGate.Radio<String, String> {
            var onTag: ((String) -> Unit)? = null
            override fun enable(host: String, onTag: (String) -> Unit) { this.onTag = onTag }
            override fun disable(host: String) = throw IllegalStateException("paused")
            override fun ignore(tag: String): Boolean = throw SecurityException("gone")
        }
        val gate = NfcReaderModeGate(failing)
        val session = Waiting()
        gate.open("activity", session)
        failing.onTag!!("card")
        gate.finished(session)
        gate.paused("activity")
        assertFalse(gate.active)
    }
}
