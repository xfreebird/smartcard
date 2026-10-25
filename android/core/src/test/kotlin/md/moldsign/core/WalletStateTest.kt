package md.moldsign.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

/** Card wallet bookkeeping (docs/09 §3.1b, docs/10 §0.1–0.2): generations, re-reads, selection, status light. */
class WalletStateTest {
    private val certA = CertificateSummary.parse(TestCertificates.mdQSign)
    private val certB = CertificateSummary.parse(TestCertificates.mdTrustCa)

    private fun card(id: String, gen: Long) = ReaderSlot(id, "Reader $id", ReaderSlot.State.Card, gen)
    private fun empty(id: String) = ReaderSlot(id, "Reader $id", ReaderSlot.State.Empty)

    @Test
    fun generationsBumpOnlyWhenACardArrives() {
        val g = CardGenerations()
        val first = g.observe("a", cardPresent = true)
        assertEquals(first, g.observe("a", cardPresent = true))
        assertEquals(0, g.observe("a", cardPresent = false))
        val second = g.observe("a", cardPresent = true)
        assertNotEquals(first, second)
        g.forget("a")
        assertTrue(g.observe("a", cardPresent = true) > second)
        assertNotEquals(g.observe("b", cardPresent = true), g.observe("a", cardPresent = true))
    }

    @Test
    fun newCardsAreReadOnceAndKeptWhileTheGenerationHolds() {
        val (s1, read1) = WalletState().reconcile(listOf(card("a", 1), empty("b")))
        assertEquals(listOf("a"), read1.map { it.readerId })
        assertEquals("a", s1.selectedReaderId)

        val s2 = s1.withCertificate(read1[0], certA)
        val (s3, read3) = s2.reconcile(listOf(card("a", 1), card("b", 2)))
        assertEquals("same generation: no second read (6985 trap)", listOf("b"), read3.map { it.readerId })
        assertSame(certA, s3.cards.first { it.readerId == "a" }.certificate)
        assertEquals("selection stays", "a", s3.selectedCard?.readerId)
    }

    @Test
    fun newGenerationDropsTheOldCertificateAndIgnoresALateRead() {
        val (s1, read1) = WalletState().reconcile(listOf(card("a", 1)))
        val s2 = s1.withCertificate(read1[0], certA)
        val (s3, read3) = s2.reconcile(listOf(card("a", 5))) // removed + another card inserted
        assertEquals(1, read3.size)
        assertNull(s3.cards.single().certificate)
        // the read started for generation 1 finishes late: it must not paint card A's holder on the new card
        val s4 = s3.withCertificate(read1[0], certA)
        assertNull(s4.cards.single().certificate)
        assertEquals(certB, s4.withCertificate(read3[0], certB).cards.single().certificate)
    }

    @Test
    fun selectionFallsBackWhenTheSelectedReaderGoesAway() {
        val (s1, _) = WalletState().reconcile(listOf(card("a", 1), card("b", 2)))
        val s2 = s1.select("b")
        assertEquals("b", s2.selectedCard?.readerId)
        assertSame("unknown reader: unchanged", s2, s2.select("zzz"))
        val (s3, _) = s2.reconcile(listOf(card("a", 1), empty("b")))
        assertEquals("a", s3.selectedCard?.readerId)
    }

    @Test
    fun rereadForgetsEveryCertificate() {
        val (s1, read) = WalletState().reconcile(listOf(card("a", 1), card("b", 2)))
        val s2 = s1.withCertificate(read[0], certA).withProblem(read[1], CardError.CardStateStuck())
        val (s3, toRead) = s2.forgetCertificates()
        assertEquals(2, toRead.size)
        assertTrue(s3.cards.all { it.isReading })
    }

    @Test
    fun statusLight() {
        assertEquals(StatusLight.Idle, WalletState().light(busy = false))
        val (reading, read) = WalletState().reconcile(listOf(card("a", 1)))
        assertEquals("card being read", StatusLight.Reader, reading.light(busy = false))
        assertEquals(StatusLight.Reader, WalletState().reconcile(listOf(empty("a"))).state.light(busy = false))
        val ready = reading.withCertificate(read[0], certA)
        assertEquals(StatusLight.Ready, ready.light(busy = false))
        assertEquals(StatusLight.Busy, ready.light(busy = true))
        assertEquals(StatusLight.Error, reading.withProblem(read[0], CardError.CardStateStuck()).light(busy = false))
        val broken = WalletState().reconcile(listOf(ReaderSlot("a", "Reader", ReaderSlot.State.Error))).state
        assertEquals(StatusLight.Error, broken.light(busy = false))
    }

    @Test
    fun trayIsGreenWhileAnyUsableCardIsInserted() {
        assertEquals(TrayStatus(connected = false), WalletState().tray())
        assertEquals(TrayStatus(connected = false), WalletState().reconcile(listOf(empty("a"))).state.tray())

        val (reading, read) = WalletState().reconcile(listOf(card("a", 1), card("b", 2)))
        assertTrue("reading counts as connected", reading.tray().connected)
        assertEquals("a", reading.tray().card?.readerId)

        // selected card in error, the other one fine: green, named after the usable card
        val mixed = reading.withProblem(read[0], CardError.CardStateStuck()).withCertificate(read[1], certB)
        assertEquals(TrayStatus(connected = true, card = mixed.cards[1]), mixed.tray())

        // only cards in error: gray with the error's one-liner
        val stuck = CardError.CardStateStuck()
        val broken = WalletState().reconcile(listOf(card("a", 1))).let { (s, r) -> s.withProblem(r[0], stuck) }
        assertEquals(TrayStatus(connected = false, problem = stuck), broken.tray())

        val readerDown = WalletState().reconcile(listOf(ReaderSlot("a", "Reader", ReaderSlot.State.Error))).state
        assertEquals(TrayStatus(connected = false, readerError = true), readerDown.tray())
    }

    @Test
    fun namePartsPreferSnGnAndFallBackToTheFirstSpace() {
        val base = certA.copy(commonName = "MÎNDRU ION ALEXANDRU", surname = null, givenNames = null)
        assertEquals("MÎNDRU" to "ION ALEXANDRU", base.nameParts)
        assertEquals("CEBAN" to "ANA", base.copy(surname = "CEBAN", givenNames = "ANA").nameParts)
        assertEquals("MDQSign" to "", base.copy(commonName = "MDQSign").nameParts)
        assertEquals("SN/GN round-trip through RFC 2253", "MÎNDRU",
            CertificateSummary.rdnValue("SURNAME=MÎNDRU,GIVENNAME=ION,CN=MÎNDRU ION,C=MD", "SURNAME"))
    }
}
