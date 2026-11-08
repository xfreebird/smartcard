package md.moldsign.app.bridge

import android.Manifest
import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.launch
import md.moldsign.app.application.AppContainer
import md.moldsign.app.application.AppStatus
import md.moldsign.app.MainActivity
import md.moldsign.app.MoldSignApp
import md.moldsign.app.presentation.appString
import md.moldsign.app.R
import md.moldsign.app.presentation.errorText
import md.moldsign.app.presentation.trayText
import md.moldsign.app.ui.theme.notificationArgb
import md.moldsign.core.BridgeObserver
import md.moldsign.core.BridgeOriginPolicy
import md.moldsign.core.BridgeServer
import md.moldsign.core.BridgeTls
import md.moldsign.core.CardError
import md.moldsign.core.Consent
import md.moldsign.core.ConsentRequest
import md.moldsign.core.SigningBridgeRoutes
import kotlin.concurrent.thread

/**
 * Foreground service (`connectedDevice`) hosting the MoldSign Server bridge so Chrome on the same phone can sign
 * through msign.gov.md (AND-04): HTTPS on 18443 with the vendor `localhost.cts.md` identity (the origin the portal
 * calls) and plain HTTP on 127.0.0.1:18480 (curl, other clients). The origin allow-list (SEC-01) and the CORS /
 * Private-Network preflight live in core `BridgeServer`; the routes, sessions and PIN sessions in
 * `SigningBridgeRoutes`.
 *
 * Every request goes through the PIN sheet (SEC-02). Chrome is in front when a request arrives, so the service posts
 * a heads-up notification that opens the app on the sheet (R-04, AND-05).
 *
 * TODO(AND-04): start/stop automatically while the reader is attached.
 * TODO(AND-08): document Chrome's Local Network Access prompt.
 *
 * The ongoing notification is the Android tray (docs/10 §0.2b, UX-11): two states only. Green accent and
 * "Card conectat · {holder}" while a card is inserted (reading, ready or signing); gray and "Niciun card conectat"
 * (or the error's one-liner) otherwise. The richer five-state light stays in the app's top bar.
 * TODO(UX-01): optional Quick Settings tile with the same two states (strings `qs_tile_label`, `tray_*` are ready);
 *  today the tray state is only in this notification while the bridge runs.
 */
class BridgeService : Service() {
    private var servers: List<BridgeServer> = emptyList()
    private val lifecycleLock = Any()
    private var destroyed = false
    private var routes: SigningBridgeRoutes? = null
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var statusJob: Job? = null
    private val status get() = (application as MoldSignApp).container.status

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if ((application as MoldSignApp).container.isDemo || intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        startInForeground()
        if (servers.isEmpty()) {
            val container = (application as MoldSignApp).container
            val routes = SigningBridgeRoutes(
                service = container.signingService,
                cards = container::bridgeCards,
                consent = consentWithNotification(container),
                observer = observer(container),
                previewPdfEnabled = { container.stampBroker.enabled },
                previewPdf = { document, certificate, origin ->
                    if (container.stampBroker.enabled && !container.inForeground)
                        postConsentNotification(md.moldsign.core.ConsentRequest(origin, listOf(document.name), "PAdES-T", certificate))
                    try { container.stampBroker.obtain(document, certificate, origin) }
                    finally { cancelConsentNotification() }
                },
                log = { Log.i(TAG, it) },
            ).also { this.routes = it }
            val policy = BridgeOriginPolicy.bundled()
            val tls = runCatching { BridgeTls.vendorContext() }
                .onFailure { Log.w(TAG, "TLS identity not loaded: ${it.javaClass.simpleName}: ${it.message}") }
                .getOrNull()
            if (tls == null) {
                _startupFailed.value = true
                stopSelf()
                return START_NOT_STICKY
            }
            val http = BridgeServer(policy, routes, BridgeServer.DEFAULT_HTTP_PORT, log = { Log.i(TAG, it) })
            val https = BridgeServer(policy, routes, BridgeServer.DEFAULT_TLS_PORT, tls = tls, log = { Log.i(TAG, it) })
            servers = listOf(https, http)
            _startupFailed.value = false
            thread(name = "bridge-start", isDaemon = true) {
                // The portals require HTTPS; an HTTP-only listener must never appear usable.
                // Serializing start and destruction prevents a stopped service reopening a port.
                synchronized(lifecycleLock) {
                    if (destroyed) return@synchronized
                    try {
                        https.start()
                    } catch (e: Exception) {
                        Log.w(TAG, "secure bridge listener failed to start: ${e.message}")
                        _startupFailed.value = true
                        _running.value = false
                        stopSelf()
                        return@synchronized
                    }
                    try {
                        http.start()
                    } catch (e: Exception) {
                        Log.w(TAG, "optional HTTP bridge listener failed to start: ${e.message}")
                    }
                    _running.value = https.isRunning
                }
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        serviceScope.cancel()
        synchronized(lifecycleLock) {
            destroyed = true
            servers.forEach { it.close() }
            servers = emptyList()
            _running.value = false
        }
        routes?.close()
        routes = null
        cancelConsentNotification()
        _running.value = false
        super.onDestroy()
    }

    private fun startInForeground() {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, appString(R.string.bridge_channel_name), NotificationManager.IMPORTANCE_LOW),
        )
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE else 0
        ServiceCompat.startForeground(this, NOTIFICATION_ID, buildNotification(status.value), type)
        if (statusJob == null) {
            // Follow the status light while the bridge runs (the first value is already shown).
            statusJob = serviceScope.launch {
                status.drop(1).collect { s ->
                    val canPost = Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                    if (canPost) nm.notify(NOTIFICATION_ID, buildNotification(s))
                }
            }
        }
    }

    /** Busy light and activity list for browser signatures (the Apple `onSignResult`). */
    private fun observer(container: AppContainer) = object : BridgeObserver {
        override fun signStarted(origin: String?) = container.beginBusy()

        override fun signFinished(origin: String?, format: String, error: Throwable?) {
            container.endBusy()
            if (error is CardError.Cancelled) return
            val site = origin?.substringAfter("://") ?: appString(R.string.bridge_toggle)
            if (error == null) {
                container.activity.browser(site, ok = true, appString(R.string.activity_signed, format))
            } else {
                container.activity.browser(site, ok = false, appString(R.string.activity_failed, format, errorText(this@BridgeService, error)))
            }
        }
    }

    /**
     * The PIN sheet lives in the activity, but Chrome is in front: a heads-up notification (full-screen intent where
     * allowed) opens it. An unanswered request is cancelled after [CONSENT_TIMEOUT_MS] so the card is never held forever.
     */
    private fun consentWithNotification(container: AppContainer) = Consent { request ->
        if (!container.inForeground) postConsentNotification(request)
        try {
            container.consentBroker.obtain(request, CONSENT_TIMEOUT_MS)
        } finally {
            cancelConsentNotification()
        }
    }

    private fun postConsentNotification(request: ConsentRequest) {
        val canPost = Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        if (!canPost) return
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(CONSENT_CHANNEL_ID, appString(R.string.consent_channel_name), NotificationManager.IMPORTANCE_HIGH),
        )
        val open = PendingIntent.getActivity(
            this, 2,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val site = request.requester?.substringAfter("://") ?: appString(R.string.consent_you)
        val builder = NotificationCompat.Builder(this, CONSENT_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_moldsign)
            .setContentTitle(appString(R.string.consent_title, site))
            .setContentText(appString(R.string.consent_notification_text, request.documentNames.joinToString()))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .setTimeoutAfter(CONSENT_TIMEOUT_MS)
            .setContentIntent(open)
        val fullScreenAllowed = Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE || nm.canUseFullScreenIntent()
        if (fullScreenAllowed) builder.setFullScreenIntent(open, true)
        nm.notify(CONSENT_NOTIFICATION_ID, builder.build())
    }

    private fun cancelConsentNotification() {
        getSystemService(NotificationManager::class.java).cancel(CONSENT_NOTIFICATION_ID)
    }

    private fun buildNotification(s: AppStatus): Notification {
        val open = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE,
        )
        val stop = PendingIntent.getService(
            this, 1, Intent(this, BridgeService::class.java).setAction(ACTION_STOP), PendingIntent.FLAG_IMMUTABLE,
        )
        val line = trayText(this, s.wallet)
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_moldsign)
            .setColor(s.wallet.tray().notificationArgb())
            .setContentTitle(appString(R.string.bridge_notification_title))
            .setContentText(line)
            .setStyle(NotificationCompat.BigTextStyle().bigText(line + "\n" + appString(R.string.bridge_notification_text)))
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setOnlyAlertOnce(true)
            .setOngoing(true)
            .setContentIntent(open)
            .addAction(0, appString(R.string.bridge_stop), stop)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    companion object {
        private const val TAG = "MoldSignBridge"
        private const val CHANNEL_ID = "bridge"
        private const val NOTIFICATION_ID = 18480
        private const val CONSENT_CHANNEL_ID = "bridge_consent"
        private const val CONSENT_NOTIFICATION_ID = 18481
        private const val CONSENT_TIMEOUT_MS = 2 * 60_000L
        const val ACTION_STOP = "md.moldsign.app.bridge.STOP"

        private val _running = MutableStateFlow(false)
        val running: StateFlow<Boolean> = _running.asStateFlow()
        private val _startupFailed = MutableStateFlow(false)
        val startupFailed: StateFlow<Boolean> = _startupFailed.asStateFlow()

        fun start(context: Context) {
            _startupFailed.value = false
            ContextCompat.startForegroundService(context, Intent(context, BridgeService::class.java))
        }

        // Lint's ImplicitSamInstance fires here by mistake: stopService matches the component, not the instance.
        @SuppressLint("ImplicitSamInstance")
        fun stop(context: Context) {
            _startupFailed.value = false
            context.stopService(Intent(context, BridgeService::class.java))
        }
    }
}
