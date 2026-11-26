package md.moldsign.transport.usb

import android.app.Application
import android.content.Intent
import android.hardware.usb.UsbConfiguration
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Looper
import android.os.Parcelable
import org.robolectric.RuntimeEnvironment
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.test.StandardTestDispatcher
import md.moldsign.core.CardError
import md.moldsign.core.ReaderSlot
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import java.lang.reflect.Proxy

/**
 * The Android side of the USB reader: device enumeration, permission, attach/detach/permission broadcasts and
 * claiming a CCID interface, on Robolectric's UsbManager. No reader hardware is involved.
 */
@RunWith(RobolectricTestRunner::class)
class AndroidUsbHostTest {
    private val context: Application = RuntimeEnvironment.getApplication()
    private val usbManager: UsbManager = context.getSystemService(UsbManager::class.java)
    private val host = AndroidUsbHost(context)

    // The USB descriptor classes have hidden constructors; Robolectric runs the real framework classes.
    private fun endpoint(address: Int, type: Int): UsbEndpoint =
        UsbEndpoint::class.java.getConstructor(Int::class.java, Int::class.java, Int::class.java, Int::class.java)
            .newInstance(address, type, 64, 0)

    private fun usbInterface(id: Int, interfaceClass: Int, vararg endpoints: UsbEndpoint): UsbInterface =
        UsbInterface::class.java.getConstructor(Int::class.java, Int::class.java, String::class.java, Int::class.java, Int::class.java, Int::class.java)
            .newInstance(id, 0, "interface", interfaceClass, 0, 0).also {
                UsbInterface::class.java.getMethod("setEndpoints", Array<Parcelable>::class.java).invoke(it, arrayOf<Parcelable>(*endpoints))
            }

    private fun device(name: String, productName: String?, vararg interfaces: UsbInterface): UsbDevice {
        val configuration = UsbConfiguration::class.java.getConstructor(Int::class.java, String::class.java, Int::class.java, Int::class.java)
            .newInstance(1, "configuration", 0, 100)
        UsbConfiguration::class.java.getMethod("setInterfaces", Array<Parcelable>::class.java).invoke(configuration, arrayOf<Parcelable>(*interfaces))
        val serialReader = Class.forName("android.hardware.usb.IUsbSerialReader")
        val reader = Proxy.newProxyInstance(serialReader.classLoader, arrayOf(serialReader)) { _, method, _ ->
            if (method.name == "getSerial") "SERIAL" else null
        }
        val b = Boolean::class.javaPrimitiveType!!
        val i = Int::class.javaPrimitiveType!!
        val constructor = UsbDevice::class.java.getDeclaredConstructor(String::class.java, i, i, i, i, i, String::class.java, String::class.java,
            String::class.java, Array<UsbConfiguration>::class.java, serialReader, b, b, b, b, b)
        constructor.isAccessible = true
        return constructor.newInstance(name, 0x25DD, 0x1101, 0, 0, 0, "bit4id", productName, "1.0", arrayOf(configuration), reader,
            false, false, false, false, false)
    }

    private val bulkIn get() = endpoint(0x81, 2)
    private val bulkOut get() = endpoint(0x02, 2)
    private val interruptIn get() = endpoint(0x83, 3)
    private fun ccidReader(name: String = "/dev/bus/usb/001/002", product: String? = "miniLector EVO") =
        device(name, product, usbInterface(0, 0x0B, bulkIn, bulkOut, interruptIn))

    @Test fun onlyCcidReadersAreListedWithTheirNames() {
        val ccid = ccidReader()
        val vendor = device("/dev/bus/usb/001/003", "  ", usbInterface(0, 0xFF, bulkIn, bulkOut))
        val keyboard = device("/dev/bus/usb/001/004", "Keyboard", usbInterface(0, 0x03, interruptIn))
        val vendorWithoutBulk = device("/dev/bus/usb/001/005", "Odd", usbInterface(0, 0xFF, interruptIn))
        listOf(ccid, vendor, keyboard, vendorWithoutBulk).forEach { shadowOf(usbManager).addOrUpdateUsbDevice(it, false) }

        val readers = host.readers().sortedBy { it.id }
        assertEquals(listOf("/dev/bus/usb/001/002", "/dev/bus/usb/001/003"), readers.map { it.id })
        assertEquals("miniLector EVO", readers[0].name)
        assertEquals("USB reader 25DD:1101", readers[1].name)
        assertFalse(host.hasPermission(readers[0]))
        assertTrue(CcidTransport.isCcidReader(vendor))
        assertFalse(CcidTransport.isCcidReader(keyboard))
        assertNull(CcidTransport.findCcidInterface(vendorWithoutBulk))
    }

    @Test fun openingNeedsPermissionAndClaimsTheInterface() {
        val ccid = ccidReader()
        shadowOf(usbManager).addOrUpdateUsbDevice(ccid, false)
        val reader = host.readers().single()
        try { host.open(reader); fail("no permission") } catch (error: CardError.NoReader) {
            assertTrue(error.message!!.contains("permission"))
        }

        shadowOf(usbManager).addOrUpdateUsbDevice(ccid, true)
        assertTrue(host.hasPermission(reader))
        val transport = host.open(reader)
        assertEquals("miniLector EVO", transport.readerName)
        assertEquals(0x83, transport.interruptIn?.address)
        assertNull(transport.descriptor)

        // Robolectric's connection only records outgoing bulk data, so no CCID exchange is attempted here:
        // the claimed connection belongs to the transport (bulk transfers are covered by CcidTransportTest).
        assertTrue(connectionOf(transport) is UsbDeviceConnection)
    }

    @Test fun readersWithoutUsableInterfacesAreRefused() {
        val keyboard = device("/dev/bus/usb/001/004", "Keyboard", usbInterface(0, 0x03, interruptIn))
        shadowOf(usbManager).addOrUpdateUsbDevice(keyboard, true)
        try { CcidTransport.open(usbManager, keyboard); fail("not a reader") } catch (error: CardError.NoReader) {
            assertTrue(error.message!!.contains("not a CCID reader"))
        }
        val noBulk = device("/dev/bus/usb/001/006", "Broken", usbInterface(0, 0x0B, interruptIn))
        shadowOf(usbManager).addOrUpdateUsbDevice(noBulk, true)
        try { CcidTransport.open(usbManager, noBulk); fail("no bulk endpoints") } catch (error: CardError.NoReader) {
            assertTrue(error.message!!.contains("bulk"))
        }
    }

    @Test fun broadcastsBecomeReaderEvents() {
        val events = mutableListOf<String>()
        host.listen(object : UsbHost.Events {
            override fun attached(reader: UsbHost.Reader) { events += "attached:${reader.id}" }
            override fun detached(id: String) { events += "detached:$id" }
            override fun permission(reader: UsbHost.Reader, granted: Boolean) { events += "permission:${reader.id}:$granted" }
        })
        val ccid = ccidReader()
        val keyboard = device("/dev/bus/usb/001/004", "Keyboard", usbInterface(0, 0x03, interruptIn))
        fun send(intent: Intent) { context.sendBroadcast(intent); shadowOf(Looper.getMainLooper()).idle() }
        send(Intent(UsbManager.ACTION_USB_DEVICE_ATTACHED).putExtra(UsbManager.EXTRA_DEVICE, ccid))
        send(Intent(UsbManager.ACTION_USB_DEVICE_ATTACHED).putExtra(UsbManager.EXTRA_DEVICE, keyboard))
        send(Intent(UsbManager.ACTION_USB_DEVICE_ATTACHED))
        send(Intent(UsbManager.ACTION_USB_DEVICE_DETACHED).putExtra(UsbManager.EXTRA_DEVICE, ccid))
        send(Intent(UsbReaderMonitor.ACTION_USB_PERMISSION).setPackage(context.packageName)
            .putExtra(UsbManager.EXTRA_DEVICE, ccid).putExtra(UsbManager.EXTRA_PERMISSION_GRANTED, true))
        send(Intent(UsbReaderMonitor.ACTION_USB_PERMISSION).setPackage(context.packageName).putExtra(UsbManager.EXTRA_DEVICE, ccid))
        send(Intent(UsbReaderMonitor.ACTION_USB_PERMISSION).setPackage(context.packageName))
        assertEquals(listOf("attached:${ccid.deviceName}", "detached:${ccid.deviceName}",
            "permission:${ccid.deviceName}:true", "permission:${ccid.deviceName}:false"), events)

        host.stopListening()
        host.stopListening()
        send(Intent(UsbManager.ACTION_USB_DEVICE_DETACHED).putExtra(UsbManager.EXTRA_DEVICE, ccid))
        assertEquals(4, events.size)
    }

    @Test fun permissionRequestTargetsTheReader() {
        val ccid = ccidReader()
        shadowOf(usbManager).addOrUpdateUsbDevice(ccid, false)
        // The system dialog is out of reach here; the request must at least not grant anything by itself.
        runCatching { host.requestPermission(host.readers().single()) }
        assertFalse(host.hasPermission(host.readers().single()))
    }

    @Test fun monitorOnTheAndroidHostWaitsForPermission() {
        shadowOf(usbManager).addOrUpdateUsbDevice(ccidReader(), false)
        val scope = CoroutineScope(SupervisorJob() + StandardTestDispatcher())
        val monitor = UsbReaderMonitor(context, scope)
        monitor.start()
        assertEquals(ReaderSlot.State.PermissionRequired, monitor.readers.value.single().state)
        monitor.stop()
        assertTrue(monitor.readers.value.isEmpty())
        scope.cancel()
    }

    private fun connectionOf(transport: CcidTransport): UsbDeviceConnection {
        val link = CcidTransport::class.java.getDeclaredField("link").apply { isAccessible = true }.get(transport)
        return link.javaClass.getDeclaredField("connection").apply { isAccessible = true }.get(link) as UsbDeviceConnection
    }
}
