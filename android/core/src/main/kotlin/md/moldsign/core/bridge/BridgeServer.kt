package md.moldsign.core

import java.io.ByteArrayOutputStream
import java.io.Closeable
import java.io.IOException
import java.io.InputStream
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketException
import java.util.Locale
import java.util.concurrent.ExecutorService
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import javax.net.ssl.SSLContext

/** One parsed HTTP/1.1 request. Header names are lower-cased. */
class BridgeRequest(
    val method: String,
    val path: String,
    val query: String?,
    val headers: Map<String, String>,
    val body: ByteArray,
) {
    fun header(name: String): String? = headers[name.lowercase(Locale.ROOT)]
}

class BridgeResponse(
    val status: Int,
    val body: ByteArray = ByteArray(0),
    val contentType: String = "application/json",
    val headers: List<Pair<String, String>> = emptyList(),
) {
    companion object {
        fun json(status: Int, json: String, headers: List<Pair<String, String>> = emptyList()) =
            BridgeResponse(status, json.toByteArray(Charsets.UTF_8), "application/json", headers)
    }
}

/** Route table behind the origin policy. */
fun interface BridgeRoutes {
    fun handle(request: BridgeRequest): BridgeResponse
}

/**
 * Placeholder routes: only `GET /certificates` answers, the signing routes say 501. The app uses
 * [SigningBridgeRoutes]; this one keeps the server testable without a card.
 */
class DefaultBridgeRoutes(
    /** JSON array of `CertificateModel` objects. */
    private val certificatesJson: () -> String = { "[]" },
) : BridgeRoutes {
    override fun handle(request: BridgeRequest): BridgeResponse {
        val path = request.path
        return when {
            request.method == "GET" && path == "/certificates" ->
                BridgeResponse.json(200, """{"certificateModel":${certificatesJson()}}""")
            VENDOR_ROUTE_PREFIXES.any { path == it || path.startsWith("$it/") } ->
                BridgeResponse.json(501, """{"error":"not implemented yet"}""")
            else -> BridgeResponse.json(404, """{"error":"not found"}""")
        }
    }

    companion object {
        val VENDOR_ROUTE_PREFIXES = listOf("/sign/data", "/sign/pdf", "/sign/file", "/verify/pdf")
    }
}

/**
 * Minimal loopback HTTP/1.1 server for the bridge (one request per connection, `Connection: close`,
 * `Content-Length` framing), applying [BridgeOriginPolicy] before any route runs.
 *
 * Pure JVM (java.net) so it is unit-testable; Android hosts it in `BridgeService` (AND-04). Pass [tls] (see
 * [BridgeTls]) for the HTTPS listener the portal talks to (`https://localhost.cts.md:18443`).
 *
 * A long-poll GET holds its worker thread until the signature exists (consent + PIN take as long as the user
 * does), so the pool is sized for several waiting polls instead of the few short requests of the old skeleton.
 */
class BridgeServer(
    private val policy: BridgeOriginPolicy,
    private val routes: BridgeRoutes = DefaultBridgeRoutes(),
    private val port: Int = DEFAULT_HTTP_PORT,
    private val bindAddress: InetAddress = InetAddress.getByName("127.0.0.1"),
    private val maxBodyBytes: Int = MAX_BODY_BYTES,
    private val tls: SSLContext? = null,
    private val log: (String) -> Unit = {},
) : Closeable {
    @Volatile private var serverSocket: ServerSocket? = null
    @Volatile private var workers: ExecutorService? = null

    val isRunning: Boolean get() = serverSocket?.isClosed == false

    /** Bound port (useful with port 0 in tests), or -1 when stopped. */
    val localPort: Int get() = serverSocket?.localPort ?: -1

    @Synchronized
    fun start(): Int {
        serverSocket?.let { if (!it.isClosed) return it.localPort }
        val ss = tls?.serverSocketFactory?.createServerSocket() ?: ServerSocket()
        ss.reuseAddress = true
        ss.bind(InetSocketAddress(bindAddress, port), 16)
        val pool = ThreadPoolExecutor(
            WORKER_THREADS, WORKER_THREADS, 30, TimeUnit.SECONDS, LinkedBlockingQueue(),
        ) { r -> Thread(r, "bridge-http").apply { isDaemon = true } }
        pool.allowCoreThreadTimeOut(true)
        serverSocket = ss
        workers = pool
        Thread({ acceptLoop(ss, pool) }, "bridge-accept").apply { isDaemon = true }.start()
        log("bridge listening on ${bindAddress.hostAddress}:${ss.localPort}${if (tls != null) " (TLS)" else ""}")
        return ss.localPort
    }

    @Synchronized
    override fun close() {
        serverSocket?.close()
        serverSocket = null
        workers?.shutdownNow()
        workers?.awaitTermination(1, TimeUnit.SECONDS)
        workers = null
    }

    private fun acceptLoop(ss: ServerSocket, pool: ExecutorService) {
        while (!ss.isClosed) {
            val socket = try {
                ss.accept()
            } catch (e: SocketException) {
                break // closed
            } catch (e: IOException) {
                log("accept failed: ${e.message}")
                continue
            }
            pool.execute { serve(socket) }
        }
    }

    private fun serve(socket: Socket) {
        socket.use { s ->
            try {
                s.soTimeout = SOCKET_TIMEOUT_MS
                // SEC-03: loopback peers only, even if someone binds us to another interface.
                val response = if (!s.inetAddress.isLoopbackAddress) {
                    BridgeResponse.json(403, """{"error":"loopback only"}""")
                } else {
                    when (val parsed = readRequest(s.getInputStream()) { s.getOutputStream().write(CONTINUE) }) {
                        is ParseResult.Ok -> respond(parsed.request)
                        is ParseResult.Error -> BridgeResponse.json(parsed.status, """{"error":"${parsed.message}"}""")
                    }
                }
                s.getOutputStream().apply { write(serialize(response)); flush() }
            } catch (e: IOException) {
                log("connection error: ${e.message}")
            }
        }
    }

    /** Origin policy + CORS + routing. Exposed for unit tests (no sockets needed). */
    fun respond(request: BridgeRequest): BridgeResponse {
        val origin = request.header("origin")
        if (!policy.isAllowed(origin, request.header(BridgeOriginPolicy.DESKTOP_CLIENT_HEADER))) {
            log("403 ${request.method} ${request.path} origin=${origin ?: "-"}")
            return BridgeResponse.json(403, """{"error":"origin not allowed"}""")
        }
        val cors = if (origin != null) corsHeaders(origin) else emptyList()
        if (request.method == "OPTIONS") {
            return BridgeResponse(
                200, ByteArray(0), "text/plain",
                cors + listOf(
                    "Access-Control-Allow-Methods" to "GET, POST, OPTIONS",
                    "Access-Control-Allow-Private-Network" to "true", // Chrome PNA / LNA preflight (R-05, AND-08)
                    "Access-Control-Max-Age" to "600",
                ),
            )
        }
        val routed = try {
            routes.handle(request)
        } catch (e: Exception) {
            log("route failed: ${e.javaClass.simpleName}")
            BridgeResponse.json(500, """{"error":"internal error"}""")
        }
        return BridgeResponse(routed.status, routed.body, routed.contentType, cors + routed.headers)
    }

    private fun corsHeaders(origin: String) = listOf(
        "Access-Control-Allow-Origin" to origin,
        "Vary" to "Origin",
        "Access-Control-Allow-Headers" to CORS_HEADER_LIST,
        "Access-Control-Expose-Headers" to CORS_HEADER_LIST,
    )

    private sealed class ParseResult {
        class Ok(val request: BridgeRequest) : ParseResult()
        class Error(val status: Int, val message: String) : ParseResult()
    }

    private fun readRequest(input: InputStream, sendContinue: () -> Unit): ParseResult {
        val head = readHead(input) ?: return ParseResult.Error(400, "bad request")
        val lines = head.split("\r\n")
        val requestLine = lines.first().split(' ')
        if (requestLine.size != 3 || !requestLine[2].startsWith("HTTP/1.")) return ParseResult.Error(400, "bad request line")
        val headers = LinkedHashMap<String, String>()
        for (line in lines.drop(1)) {
            if (line.isEmpty()) continue
            val colon = line.indexOf(':')
            if (colon <= 0) return ParseResult.Error(400, "bad header")
            val name = line.substring(0, colon).trim().lowercase(Locale.ROOT)
            headers.putIfAbsent(name, line.substring(colon + 1).trim()) // first value wins, like Jersey getFirst
        }
        if (headers["transfer-encoding"] != null) return ParseResult.Error(501, "chunked bodies not supported")
        val length = headers["content-length"]?.toLongOrNull() ?: 0L
        if (length < 0) return ParseResult.Error(400, "bad content-length")
        if (length > maxBodyBytes) return ParseResult.Error(413, "body too large")
        if (length > 0 && headers["expect"].equals("100-continue", ignoreCase = true)) sendContinue()
        val body = ByteArray(length.toInt())
        var read = 0
        while (read < body.size) {
            val n = input.read(body, read, body.size - read)
            if (n < 0) return ParseResult.Error(400, "truncated body")
            read += n
        }
        val target = requestLine[1]
        val q = target.indexOf('?')
        val path = if (q >= 0) target.substring(0, q) else target
        val query = if (q >= 0) target.substring(q + 1) else null
        return ParseResult.Ok(BridgeRequest(requestLine[0].uppercase(Locale.ROOT), path, query, headers, body))
    }

    /** Reads up to the blank line ending the head (max 16 KiB). */
    private fun readHead(input: InputStream): String? {
        val buf = ByteArrayOutputStream()
        var matched = 0
        while (buf.size() < MAX_HEAD_BYTES) {
            val b = input.read()
            if (b < 0) return null
            buf.write(b)
            matched = when {
                b == '\r'.code && (matched == 0 || matched == 2) -> matched + 1
                b == '\n'.code && (matched == 1 || matched == 3) -> matched + 1
                b == '\r'.code -> 1
                else -> 0
            }
            if (matched == 4) {
                val bytes = buf.toByteArray()
                return String(bytes, 0, bytes.size - 4, Charsets.ISO_8859_1)
            }
        }
        return null
    }

    private fun serialize(r: BridgeResponse): ByteArray {
        val sb = StringBuilder()
        sb.append("HTTP/1.1 ").append(r.status).append(' ').append(reason(r.status)).append("\r\n")
        sb.append("Content-Type: ").append(r.contentType).append("\r\n")
        sb.append("Content-Length: ").append(r.body.size).append("\r\n")
        for ((k, v) in r.headers) sb.append(k).append(": ").append(v).append("\r\n")
        sb.append("Connection: close\r\n\r\n")
        return sb.toString().toByteArray(Charsets.ISO_8859_1) + r.body
    }

    companion object {
        const val DEFAULT_HTTP_PORT = 18480
        const val DEFAULT_TLS_PORT = 18443
        const val MAX_BODY_BYTES = 64 * 1024 * 1024
        const val CORS_HEADER_LIST = "Origin, x-requested-with, content-type, accept, error, Location"
        private const val MAX_HEAD_BYTES = 16 * 1024
        private const val SOCKET_TIMEOUT_MS = 30_000
        private const val WORKER_THREADS = 32
        private val CONTINUE = "HTTP/1.1 100 Continue\r\n\r\n".toByteArray(Charsets.ISO_8859_1)

        fun reason(status: Int) = when (status) {
            200 -> "OK"; 201 -> "Created"; 303 -> "See Other"; 400 -> "Bad Request"; 403 -> "Forbidden"
            404 -> "Not Found"; 413 -> "Payload Too Large"; 500 -> "Internal Server Error"; 501 -> "Not Implemented"
            else -> "Status"
        }
    }
}
