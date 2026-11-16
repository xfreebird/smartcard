package md.moldsign.app.application

import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import md.moldsign.app.infrastructure.demo.DemoFixtures
import md.moldsign.core.ConsentRequest
import md.moldsign.core.ConsentResult
import org.junit.Assert.*
import org.junit.Test
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class ConsentBrokerTest {
    private val request = ConsentRequest(null, listOf("fixture.pdf"), "PAdES-T", DemoFixtures.certificates.first())

    @Test fun unknownNfcPinIsSavedOnlyAfterAnIdentifiedSuccess() {
        val broker = ConsentBroker()
        val executor = Executors.newSingleThreadExecutor()
        try {
            val result = executor.submit<ConsentResult> { broker.obtainPin(PinRequest(null, request.documentNames, request.format, null)) }
            val prompt = runBlocking { withTimeout(2_000) { broker.pending.filterNotNull().first() } }
            assertNull(prompt.request.certificate)
            val entered = "123456".toCharArray()
            prompt.answer(ConsentResult.Pin(entered), rememberPin = true)
            (result.get(2, TimeUnit.SECONDS) as ConsentResult.Pin).pin.fill('\u0000')
            val saved = checkNotNull(broker.afterSuccess(request.certificate))
            assertEquals(request.certificate.sha1Hex, saved.certificate.sha1Hex)
            assertArrayEquals("123456".toCharArray(), saved.pin)
            saved.pin.fill('\u0000')
            assertNull(broker.afterSuccess(request.certificate))
        } finally { broker.cancelPending(); broker.discardRemembered(); executor.shutdownNow() }
    }

    @Test fun rememberedPinCannotBeSavedForAnotherCard() {
        val broker = ConsentBroker()
        val executor = Executors.newSingleThreadExecutor()
        try {
            val result = executor.submit<ConsentResult> { broker.obtain(request) }
            val prompt = runBlocking { withTimeout(2_000) { broker.pending.filterNotNull().first() } }
            prompt.answer(ConsentResult.Pin("123456".toCharArray()), rememberPin = true)
            (result.get(2, TimeUnit.SECONDS) as ConsentResult.Pin).pin.fill('\u0000')
            assertNull(broker.afterSuccess(request.certificate.copy(sha1Hex = "different")))
            assertNull(broker.afterSuccess(request.certificate))
        } finally { broker.cancelPending(); broker.discardRemembered(); executor.shutdownNow() }
    }

    @Test fun overlappingRequestCannotReplaceFirstAndCancellationReleasesWorker() {
        val broker = ConsentBroker()
        val executor = Executors.newSingleThreadExecutor()
        try {
            val first = executor.submit<ConsentResult> { broker.obtain(request) }
            val prompt = runBlocking { withTimeout(2_000) { broker.pending.filterNotNull().first() } }
            assertSame(ConsentResult.Cancelled, broker.obtain(request))
            assertSame(prompt, broker.pending.value)
            broker.cancelPending()
            assertSame(ConsentResult.Cancelled, first.get(2, TimeUnit.SECONDS))
            assertNull(broker.pending.value)
            val late = CharArray(4) { '7' }
            prompt.answer(ConsentResult.Pin(late))
            assertTrue(late.all { it == '\u0000' })
        } finally { broker.cancelPending(); executor.shutdownNow() }
    }

    @Test fun consumedPinSurvivesWhileDuplicateAnswerIsCleared() {
        val broker = ConsentBroker()
        val executor = Executors.newSingleThreadExecutor()
        try {
            val result = executor.submit<ConsentResult> { broker.obtain(request) }
            val prompt = runBlocking { withTimeout(2_000) { broker.pending.filterNotNull().first() } }
            val accepted = CharArray(4) { '7' }
            prompt.answer(ConsentResult.Pin(accepted))
            assertSame(accepted, (result.get(2, TimeUnit.SECONDS) as ConsentResult.Pin).pin)
            val duplicate = CharArray(4) { '8' }
            prompt.answer(ConsentResult.Pin(duplicate))
            prompt.answer(ConsentResult.Pin(accepted)) // Repeated UI callback must not erase the consumed array.
            assertTrue(duplicate.all { it == '\u0000' })
            assertTrue(accepted.all { it == '7' })
            accepted.fill('\u0000')
        } finally { broker.cancelPending(); executor.shutdownNow() }
    }

    @Test fun unansweredPromptTimesOutAndDoesNotBlockNextRequest() {
        val broker = ConsentBroker()
        assertSame(ConsentResult.Cancelled, broker.obtain(request, timeoutMs = 1))
        assertNull(broker.pending.value)
        assertSame(ConsentResult.Cancelled, broker.obtain(request, timeoutMs = 1))
    }
}
