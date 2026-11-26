package md.moldsign.app.presentation

import android.net.Uri
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.runBlocking
import md.moldsign.app.AppShortcuts
import md.moldsign.app.MoldSignApp
import md.moldsign.app.R
import md.moldsign.app.application.AppContainer
import md.moldsign.app.testing.FakeDocumentAccess
import md.moldsign.app.testing.FakeMediaStore
import md.moldsign.app.testing.FakeReaderGateway
import md.moldsign.app.testing.FakeSigningService
import md.moldsign.app.testing.awaitMain
import md.moldsign.app.testing.resetStaticAndroidState
import md.moldsign.core.CardError
import md.moldsign.core.ConsentResult
import md.moldsign.core.PdfStampPlacement
import md.moldsign.core.ReaderSlot
import md.moldsign.core.SignFormat
import md.moldsign.core.ValidationReport
import md.moldsign.core.Verdict
import md.moldsign.core.protection.PasswordFileProtection
import md.moldsign.core.protection.ProtectionHeader
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/** The screen state machine against fake card, reader and document adapters: no USB, NFC or PIN. */
@RunWith(RobolectricTestRunner::class)
class MainViewModelTest {
    private val app = ApplicationProvider.getApplicationContext<MoldSignApp>()
    private val signing = FakeSigningService()
    private val readers = FakeReaderGateway()
    private val documents = FakeDocumentAccess()
    private lateinit var container: AppContainer
    private lateinit var vm: MainViewModel

    @Before fun setUp() {
        resetStaticAndroidState()
        FakeMediaStore.install()
        container = AppContainer(app, signingFactory = { signing }, readerFactory = { _, _ -> readers })
        container.start()
        awaitMain { container.wallet.value.readyCards.isNotEmpty() }
        vm = MainViewModel(app, documents = documents, container = container)
        vm.selectSigningMethod(MainViewModel.SigningMethod.Reader)
    }

    @After fun tearDown() = container.stop()

    private fun queue(vararg names: String): List<Uri> {
        val uris = names.map { documents.add(it, if (it.endsWith(".pdf")) "%PDF-1.7\n%%EOF\n".toByteArray() else it.toByteArray()) }
        vm.addForSigning(uris)
        awaitMain { vm.signItems.value.size >= names.size }
        return uris
    }

    @Test fun documentQueueEditing() {
        val (pdf, text) = queue("a.pdf", "b.txt")
        vm.addForSigning(listOf(pdf))
        awaitMain { true }
        assertEquals(2, vm.signItems.value.size)
        assertEquals(listOf(SignFormat.PadesT, SignFormat.XadesT), vm.signItems.value.map { it.format })
        assertTrue(documents.kept.containsAll(listOf(pdf, text)))

        val first = vm.signItems.value.first()
        vm.setFormat(first, SignFormat.XadesC)
        assertEquals(SignFormat.XadesC, vm.signItems.value.first().format)
        vm.setFormat(vm.signItems.value.first(), SignFormat.PadesT)
        val stamp = PdfStampPlacement(page = 1)
        vm.setStamp(vm.signItems.value.first(), stamp)
        assertEquals(1, vm.signItems.value.first().stamp?.page)
        vm.setBatchStamp(vm.signItems.value.first(), stamp.copy(page = 2))
        assertEquals(2, vm.signItems.value.first().stamp?.page)
        vm.remove(vm.signItems.value.last())
        assertEquals(listOf("a.pdf"), vm.signItems.value.map { it.doc.name })
        vm.removeGroup()
        assertTrue(vm.signItems.value.isEmpty())
        vm.addForSigning(emptyList())
    }

    @Test fun sharedFilesOpenTheSigningTab() {
        val shared = documents.add("shared.pdf")
        vm.receiveShared(listOf(shared))
        awaitMain { vm.signItems.value.isNotEmpty() }
        vm.receiveShared(listOf(Uri.parse("test://documents/missing.pdf")))
        awaitMain { vm.message.value != null }
        assertEquals(UiMessage.Text(R.string.share_unreadable), vm.message.value)
        vm.consumeMessage()
        var released = false
        vm.receiveDroppedForSigning(listOf(documents.add("dropped.pdf"))) { released = true }
        awaitMain { vm.signItems.value.size == 2 && released }
    }

    @Test fun readerSigningRecordsEachDocumentAndClearsTheQueue() {
        queue("a.pdf", "b.txt")
        vm.sign()
        awaitMain(20_000) { !vm.working.value && vm.signedResults.value.size == 2 }
        assertTrue(vm.signItems.value.isEmpty())
        assertEquals(listOf("a.pdf", "b.txt"), signing.signed)
        assertEquals(2, vm.savedDocuments.value.count { it.signedOutput })
        assertTrue(vm.message.value is UiMessage.Saved)
        vm.clearSignedResults()
        assertTrue(vm.signedResults.value.isEmpty())
    }

    @Test fun failedDocumentKeepsItsErrorAndCanBeRetried() {
        queue("a.pdf")
        signing.failure = CardError.Network("TSA")
        vm.sign()
        awaitMain(20_000) { !vm.working.value && vm.signItems.value.single().error != null }
        assertTrue(vm.signItems.value.single().error is CardError.Network)
        assertFalse(vm.activity.value.single().ok)
        signing.failure = null
        vm.retry(vm.signItems.value.single())
        awaitMain(20_000) { !vm.working.value && vm.signItems.value.isEmpty() }
        assertEquals(1, vm.signedResults.value.size)
    }

    @Test fun cardErrorsBecomeMessages() {
        queue("a.pdf")
        signing.failure = CardError.CardChanged("A", "B")
        vm.sign()
        awaitMain(20_000) { !vm.working.value }
        signing.failure = CardError.Cancelled()
        vm.sign()
        awaitMain(20_000) { !vm.working.value }
        signing.failure = IllegalStateException("unexpected")
        vm.sign()
        awaitMain(20_000) { !vm.working.value }
        assertEquals(0, vm.signedResults.value.size)
    }

    @Test fun pinConsentIsCollectedOnceForTheBatch() {
        signing.askConsent = true
        queue("a.pdf", "b.pdf")
        vm.sign()
        awaitMain(20_000) { vm.pendingConsent.value != null }
        val prompt = vm.pendingConsent.value!!
        assertEquals(listOf("a.pdf", "b.pdf"), prompt.request.documentNames)
        prompt.answer(ConsentResult.Pin("1234".toCharArray()), rememberPin = true)
        awaitMain(20_000) { !vm.working.value && vm.signedResults.value.size == 2 }
        // The remembered PIN waits for a biometric confirmation; forgetting the card discards it.
        assertNotNull(vm.pendingPinSave.value)
        vm.forgetCard(signing.certificate.sha1Hex)
        awaitMain { vm.pendingPinSave.value == null && !vm.working.value }
        assertEquals(UiMessage.Text(R.string.card_forgotten), vm.message.value)
    }

    @Test fun wrongPinForgetsTheIdentity() {
        queue("a.pdf")
        signing.failure = CardError.WrongPin(2)
        vm.sign()
        awaitMain(20_000) { !vm.working.value }
        assertTrue(vm.knownCards.value.none { it.sha1Hex == signing.certificate.sha1Hex })
    }

    @Test fun signingNeedsAReadyCard() {
        readers.readers.value = emptyList()
        awaitMain { container.wallet.value.readyCards.isEmpty() }
        queue("a.pdf")
        vm.sign()
        awaitMain { vm.message.value != null }
        assertTrue(vm.message.value is UiMessage.Status)
        assertTrue(signing.signed.isEmpty())
    }

    @Test fun verificationVerdictsAndDetachedDocuments() {
        val signed = documents.add("signed.pdf")
        vm.pickForVerify(signed)
        awaitMain { vm.verifyOutcome.value != null }
        assertEquals(Verdict.Valid, vm.verifyOutcome.value!!.verdict)
        assertEquals(string(R.string.activity_verified), vm.activity.value.first().subtitle)

        signing.verification = listOf(ValidationReport("X", null, null, "XAdES-T", true, true, true, missingDocuments = listOf("doc.txt")))
        val xml = documents.add("sig.xml")
        vm.pickForVerify(xml)
        awaitMain { vm.verifyOutcome.value?.missingDocuments == listOf("doc.txt") }
        signing.verification = listOf(ValidationReport("X", null, null, "XAdES-T", true, true, null))
        vm.addVerifyDocuments(listOf(documents.add("doc.txt")))
        awaitMain { vm.verifyDetached.value.size == 1 && vm.verifyOutcome.value?.missingDocuments?.isEmpty() == true }
        assertEquals(Verdict.Unconfirmed, vm.verifyOutcome.value!!.verdict)
        assertEquals(2, vm.verifiedDocuments.value.size)
        vm.removeVerifiedDocument(signed)
        assertEquals(1, vm.verifiedDocuments.value.size)
        vm.clearVerifyDoc()
        assertNull(vm.verifyDoc.value)

        signing.verification = listOf(ValidationReport("X", null, null, "PAdES", false, true, true))
        vm.pickMultipleForVerify(listOf(documents.add("one.pdf"), documents.add("two.pdf")))
        awaitMain { vm.verifiedDocuments.value.size == 2 }
        assertTrue(vm.verifiedDocuments.value.all { it.second.verdict == Verdict.Invalid })
        signing.verification = emptyList()
        vm.receiveDroppedForVerify(documents.add("plain.pdf"))
        awaitMain { vm.verifiedDocuments.value.any { it.second.verdict == Verdict.NoSignature } }
        vm.clearVerifyResults()
        assertTrue(vm.verifiedDocuments.value.isEmpty())
        runBlocking { assertEquals(Verdict.NoSignature, vm.inspectSavedDocument(signed).verdict) }
    }

    @Test fun unreadableVerificationIsReported() {
        vm.receiveDroppedForVerify(listOf(Uri.parse("test://documents/gone.pdf")))
        awaitMain { vm.message.value == UiMessage.Text(R.string.share_unreadable) }
    }

    @Test fun savedDocumentsCopyDeleteAndHistory() {
        queue("a.pdf")
        vm.sign()
        awaitMain(20_000) { vm.savedDocuments.value.size == 1 && !vm.working.value }
        val entry = vm.savedDocuments.value.single()
        vm.saveCopy(Uri.parse(entry.documentUri), Uri.parse("test://target/a.pdf"))
        awaitMain { vm.message.value == UiMessage.Text(R.string.copy_saved) }
        documents.copyResult = false
        vm.saveCopy(Uri.parse(entry.documentUri), Uri.parse("test://target/b.pdf"))
        awaitMain { vm.message.value == UiMessage.Text(R.string.copy_failed) }
        vm.saveCopy(null, null)
        // A file that cannot be deleted stays listed and is reported.
        vm.deleteSavedDocuments(listOf(entry))
        awaitMain { vm.message.value == UiMessage.Text(R.string.saved_delete_failed) }
        assertEquals(1, vm.savedDocuments.value.size)
        documents.deletable += Uri.parse(entry.documentUri)
        vm.deleteSavedDocuments(listOf(entry))
        awaitMain { vm.savedDocuments.value.isEmpty() }
        vm.pruneActivity()
        vm.clearActivity()
        awaitMain { vm.activity.value.isEmpty() }
    }

    @Test fun shortcutsWidgetAndWalletSelection() {
        vm.receiveShortcut(AppShortcuts.Destination.Verify)
        val request = vm.shortcutRequest.value!!
        vm.consumeShortcut("other")
        assertNotNull(vm.shortcutRequest.value)
        vm.consumeShortcut(request.id)
        assertNull(vm.shortcutRequest.value)
        vm.selectWidgetDocument("missing")
        assertNull(vm.widgetDocument.value)
        vm.consumeWidgetDocument()

        readers.readers.value = listOf(ReaderSlot("usb-1", "Test reader", ReaderSlot.State.Card, 1), ReaderSlot("usb-2", "Second", ReaderSlot.State.Card, 2))
        awaitMain { container.wallet.value.readyCards.size == 2 }
        vm.selectCard("usb-2")
        assertEquals("usb-2", container.wallet.value.selectedCard?.readerId)
        vm.rereadCards()
        vm.requestUsbPermission("usb-1")
        assertEquals(listOf<String?>("usb-1"), readers.permissionRequests)
        vm.setBridge(false)
        assertFalse(vm.pinVaultAvailable && vm.demoMode)
    }

    @Test fun nfcChoicesWithoutAnAdapterStayOnTheReader() {
        vm.selectSigningMethod(MainViewModel.SigningMethod.NFC)
        if (!vm.nfcAvailable) assertEquals(MainViewModel.SigningMethod.Reader, vm.signingMethod.value)
        vm.selectNfcCard(null)
        vm.selectBrowserCard(signing.certificate)
        vm.useReaderCardForNfc("unknown")
        vm.cancelNfc()
        vm.identifyBrowserCard()
        awaitMain { !container.busy.value }
    }

    @Test fun passwordProtectionRoundTrip() = runBlocking {
        val source = documents.add("secret.txt", "classified".toByteArray())
        val encrypted = vm.protectDocument(source, "correct horse".toCharArray(), decrypt = false, keySize = 256)
        val bytes = app.contentResolver.openInputStream(encrypted)!!.use { it.readBytes() }
        val protectedUri = documents.add("secret.txt" + PasswordFileProtection.SUFFIX, bytes)
        assertEquals(false, vm.protectionHeader(protectedUri)?.certificate)
        assertEquals("secret.txt" + PasswordFileProtection.SUFFIX, vm.protectionDocumentName(protectedUri))
        val decrypted = vm.protectDocument(protectedUri, "correct horse".toCharArray(), decrypt = true, keySize = 256)
        assertArrayEquals("classified".toByteArray(), app.contentResolver.openInputStream(decrypted)!!.use { it.readBytes() })
        assertEquals(listOf("decrypt", "encrypt"), vm.activity.value.mapNotNull { it.protectionOperation })
        assertNull(vm.protectionPreviewState("protect-encrypt"))
        assertNull(ProtectionHeader.detect(ByteArray(4)))
    }

    private fun string(id: Int, vararg args: Any) = app.getString(id, *args)
}
