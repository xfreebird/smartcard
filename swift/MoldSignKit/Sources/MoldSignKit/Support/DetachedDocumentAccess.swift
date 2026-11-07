import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

/// Reads XML file references only beneath the directory explicitly selected by the caller.
/// Each component is opened relative to a held directory descriptor: a symlink swap cannot
/// redirect verification into another directory between checking a path and reading it.
public enum DetachedDocumentAccess {
    public enum AccessError: Error { case unsafeReference, unavailable }

    /// Resolve only expected basenames. Explicit selections override neighbours and grant no
    /// access to other files in the selected file's directory. Callers own security scopes.
    public static func companions(named names: Set<String>, near signature: URL, selected: [URL]) -> [String: Data] {
        var files: [String: Data] = [:]
        for name in names {
            guard URL(fileURLWithPath: name).lastPathComponent == name else { continue }
            let chosen = selected.last { $0.isFileURL && $0.lastPathComponent == name }
            let directory = chosen?.deletingLastPathComponent() ?? signature.deletingLastPathComponent()
            files[name] = try? read(name, beneath: directory)
        }
        return files
    }

    public static func read(_ name: String, beneath directory: URL) throws -> Data {
        let parts = name.split(separator: "/", omittingEmptySubsequences: false)
        guard !name.isEmpty, !name.contains("\0"), !name.contains("\\"),
              !name.contains(":"),
              parts.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
            throw AccessError.unsafeReference
        }
        // The chosen root may itself be a user-selected alias; references below it may not.
        let root = directory.resolvingSymlinksInPath().standardizedFileURL
        var descriptor = open(root.path, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
        guard descriptor >= 0 else { throw AccessError.unavailable }
        defer { close(descriptor) }
        for (index, part) in parts.enumerated() {
            let last = index == parts.count - 1
            let flags = O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK | (last ? 0 : O_DIRECTORY)
            let next = openat(descriptor, String(part), flags)
            guard next >= 0 else { throw AccessError.unavailable }
            close(descriptor)
            descriptor = next
        }
        var info = stat()
        guard fstat(descriptor, &info) == 0, (info.st_mode & mode_t(S_IFMT)) == mode_t(S_IFREG) else {
            throw AccessError.unsafeReference
        }
        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 64 * 1024)
        while true {
            let count = buffer.withUnsafeMutableBytes { bytes in
                #if canImport(Darwin)
                Darwin.read(descriptor, bytes.baseAddress!, bytes.count)
                #else
                Glibc.read(descriptor, bytes.baseAddress!, bytes.count)
                #endif
            }
            if count == 0 { return result }
            if count < 0 {
                if errno == EINTR { continue }
                throw AccessError.unavailable
            }
            result.append(contentsOf: buffer.prefix(count))
        }
    }
}
