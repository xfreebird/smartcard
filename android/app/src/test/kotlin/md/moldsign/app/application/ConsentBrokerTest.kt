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
