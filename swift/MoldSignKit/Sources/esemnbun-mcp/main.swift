import Foundation
import MoldSignKit
import MoldSignMCP
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

MSLog.sink = nil
setbuf(stdout, nil)

func failStartup() -> Never {
    FileHandle.standardError.write(Data("error: invalid or inaccessible trusted MCP configuration.\n".utf8))
    exit(1)
}
var arguments = Array(CommandLine.arguments.dropFirst())
var roots: [String: TrustedRoot] = [:]
var broker: MCPApprovalTransport?
let unattended: MCPUnattendedTransport?
do {
    unattended = try configuredUnattended(arguments: &arguments, roots: &roots)
    while !arguments.isEmpty {
        let option = arguments.removeFirst()
        guard !arguments.isEmpty else { failStartup() }
        let value = arguments.removeFirst()
        if option == "--root" {
            let pair = value.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard pair.count == 2, MCPServer.validIdentifier(String(pair[0])), pair[0] != "broker-output", pair[0] != "unattended-output",
                  roots[String(pair[0])] == nil, roots.count < 32 else { failStartup() }
            roots[String(pair[0])] = try TrustedRoot(path: String(pair[1]))
        } else if option == "--broker-directory", broker == nil {
            broker = try SpoolApprovalTransport(directory: value)
            roots["broker-output"] = try TrustedRoot(path: value + "/outputs", privateDirectory: true)
        } else { failStartup() }
    }
} catch { failStartup() }
guard roots.count <= 32 else { failStartup() }
let server = MCPStdioAdapter(server: MCPServer(roots: roots, broker: broker, unattended: unattended))

// Keep the reader independent from validation so cancellation and EOF remain responsive.
// All application operations execute serially. The process watchdog bounds parser/crypto CPU time.
let queue = DispatchQueue(label: "md.esemnbun.mcp.requests")
let lock = NSLock()
var pending = Set<String>()
var cancelled = Set<String>()
var closing = false
func requestKey(_ object: [String: Any]) -> String? {
    guard let id = object["id"], let data = try? JSONSerialization.data(withJSONObject: [id], options: [.sortedKeys]) else { return nil }
    return data.base64EncodedString()
}
func emit(_ data: Data) { FileHandle.standardOutput.write(data); FileHandle.standardOutput.write(Data([10])) }
func consume(_ data: Data) {
    let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    lock.lock()
    if object?["method"] as? String == "notifications/cancelled", object?["id"] == nil,
       let params = object?["params"] as? [String: Any], let id = params["requestId"],
       let key = requestKey(["id": id]), pending.contains(key) {
        cancelled.insert(key); lock.unlock(); return
    }
    let key = object.flatMap(requestKey) ?? UUID().uuidString
    guard pending.count < 8, !pending.contains(key) else {
        lock.unlock()
        // Closing rather than buffering unbounded work prevents caller-driven memory growth.
        FileHandle.standardError.write(Data("error: MCP request queue limit reached.\n".utf8))
        exit(1)
    }
    pending.insert(key); lock.unlock()
    queue.async {
        lock.lock(); let skip = closing || cancelled.contains(key); lock.unlock()
        if !skip {
            // SIGALRM default action terminates runaway verification; no document data is logged.
            alarm((object?["params"] as? [String: Any])?["name"] as? String == "sign_document" ? 120 : 30)
            let response = server.handle(data)
            alarm(0)
            lock.lock()
            if !closing && !cancelled.contains(key), let response { emit(response) }
            lock.unlock()
        }
        lock.lock(); pending.remove(key); cancelled.remove(key); lock.unlock()
    }
}
var frame = Data()
while true {
    var buffer = [UInt8](repeating: 0, count: 4096)
    let count = buffer.withUnsafeMutableBytes { bytes in
        #if canImport(Darwin)
        Darwin.read(STDIN_FILENO, bytes.baseAddress!, bytes.count)
        #else
        Glibc.read(STDIN_FILENO, bytes.baseAddress!, bytes.count)
        #endif
    }
    if count < 0 && errno == EINTR { continue }
    if count <= 0 { break }
    for byte in buffer.prefix(count) {
        if byte == 10 { consume(frame); frame.removeAll(keepingCapacity: true) }
        else {
            guard frame.count < MCPServer.maximumFrameBytes else {
                FileHandle.standardError.write(Data("error: MCP frame limit reached.\n".utf8)); exit(1)
            }
            frame.append(byte)
        }
    }
}
lock.lock(); closing = true; lock.unlock()
queue.sync { server.disconnect() }
