package md.moldsign.app.bridge

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import md.moldsign.app.MainActivity
import md.moldsign.app.R
import md.moldsign.core.BridgeOriginPolicy
import md.moldsign.core.BridgeServer
import md.moldsign.core.DefaultBridgeRoutes
import kotlin.concurrent.thread

/**
 * Foreground service (`connectedDevice`) hosting the MoldSign Server bridge on 127.0.0.1:18480 so
 * Chrome on the same phone can sign through msign.gov.md (AND-04). The origin allow-list
 * (SEC-01) and the CORS / Private-Network preflight live in core `BridgeServer`.
 *
 * TODO(AND-04): TLS listener on 18443 with the localhost.cts.md PKCS12 identity (SSLServerSocket +
 *  KeyManagerFactory), signing routes backed by SigningService (201 + absolute Location, 303 polling),
 *  start/stop automatically while the reader is attached.
 * TODO(AND-05): per-request consent via a heads-up notification (background activity-start limits, R-04).
 * TODO(AND-08): document Chrome's Local Network Access prompt.
 */
class BridgeService : Service() {
    private var server: BridgeServer? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        startInForeground()
        if (server == null) {
            val s = BridgeServer(
                policy = BridgeOriginPolicy.bundled(),
                routes = DefaultBridgeRoutes(), // TODO(AND-04): certificates from SigningService.certificate()
                port = BridgeServer.DEFAULT_HTTP_PORT,
                log = { Log.i(TAG, it) },
            )
            server = s
            thread(name = "bridge-start", isDaemon = true) {
                try {
                    s.start()
                    _running.value = true
                } catch (e: Exception) {
                    // Port taken (another bridge running?) or bind refused.
                    Log.w(TAG, "bridge failed to start: ${e.message}")
                    _running.value = false
                    stopSelf()
                }
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        server?.close()
        server = null
        _running.value = false
        super.onDestroy()
    }

    private fun startInForeground() {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, getString(R.string.bridge_channel_name), NotificationManager.IMPORTANCE_LOW),
        )
        val open = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE,
        )
        val stop = PendingIntent.getService(
            this, 1, Intent(this, BridgeService::class.java).setAction(ACTION_STOP), PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_moldsign)
            .setContentTitle(getString(R.string.bridge_notification_title))
            .setContentText(getString(R.string.bridge_notification_text))
            .setOngoing(true)
            .setContentIntent(open)
            .addAction(0, getString(R.string.bridge_stop), stop)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE else 0
        ServiceCompat.startForeground(this, NOTIFICATION_ID, notification, type)
    }

    companion object {
        private const val TAG = "MoldSignBridge"
        private const val CHANNEL_ID = "bridge"
        private const val NOTIFICATION_ID = 18480
        const val ACTION_STOP = "md.moldsign.app.bridge.STOP"

        private val _running = MutableStateFlow(false)
        val running: StateFlow<Boolean> = _running.asStateFlow()

        fun start(context: Context) {
            ContextCompat.startForegroundService(context, Intent(context, BridgeService::class.java))
        }

        // Lint's ImplicitSamInstance fires here by mistake: stopService matches the component, not the instance.
        @SuppressLint("ImplicitSamInstance")
        fun stop(context: Context) {
            context.stopService(Intent(context, BridgeService::class.java))
        }
    }
}
