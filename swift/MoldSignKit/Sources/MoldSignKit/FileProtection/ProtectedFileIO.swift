import Foundation
import CPCSC
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

public enum ProtectedFileIO {
    /// Chooses the credential form from the envelope, including bare MoldSign BER files.
    /// The decryptors still validate the complete algorithm and recipient before using a key.
    public static func usesRecipientCertificate(_ url: URL) throws -> Bool {
        #if !os(Linux)
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        #endif
        let bytes = try read(url)
        if PasswordFileProtection.algorithm(in: bytes) != nil { return false }
        let fields = try ProtectionASN1.parse(bytes).require(0x30)
        if fields.first?.tag == 2 {
            if fields.count == 3 && fields[1].tag == 0x31 { return true }
            if fields.count == 2 && fields[1].tag == 0x30 { return false }
        } else if fields.count == 2, fields[0].tag == 6, fields[1].tag == 0xa0 {
            switch fields[0].content {
            case Data(hex: "2a864886f70d010703"): return true
            case Data(hex: "2a864886f70d010706"): return false
            default: break
            }
        }
        throw FileProtectionError.invalidFormat
    }

    public static func read(_ url: URL) throws -> Data {
        let fd = open(url.path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK)
        guard fd >= 0 else { throw FileProtectionError.invalidFormat }
        defer { close(fd) }
        var info = stat()
        guard fstat(fd, &info) == 0, info.st_mode & S_IFMT == S_IFREG,
              info.st_size >= 0, info.st_size <= PasswordFileProtection.maximumSize + 8192 else { throw FileProtectionError.tooLarge }
        var result = Data(), buffer = [UInt8](repeating: 0, count: 65536)
        while true {
            let count = buffer.withUnsafeMutableBytes { raw in
                #if canImport(Darwin)
                Darwin.read(fd, raw.baseAddress, raw.count)
                #else
                Glibc.read(fd, raw.baseAddress, raw.count)
                #endif
            }
            if count == 0 { break }
            if count < 0 { if errno == EINTR { continue }; throw FileProtectionError.invalidFormat }
            guard result.count + count <= PasswordFileProtection.maximumSize + 8192 else { throw FileProtectionError.tooLarge }
            result.append(contentsOf: buffer.prefix(count))
        }
        return result
    }
    /// Exclusive creation: never replace the input or an existing destination.
    public static func saveNew(_ data: Data, to url: URL) throws {
        let fd = open(url.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard fd >= 0 else { throw FileProtectionError.outputExists }
        var created = stat()
        guard fstat(fd, &created) == 0 else { close(fd); throw CocoaError(.fileWriteUnknown) }
        var succeeded = false
        defer {
            if !succeeded {
                var current = stat()
                if lstat(url.path, &current) == 0, current.st_dev == created.st_dev,
                   current.st_ino == created.st_ino { _ = unlink(url.path) }
            }
            close(fd)
        }
        try data.withUnsafeBytes { raw in
            var offset = 0
            while offset < data.count {
                let count = write(fd, raw.baseAddress!.advanced(by: offset), data.count - offset)
                if count < 0 && errno == EINTR { continue }
                guard count > 0 else { throw CocoaError(.fileWriteUnknown) }
                offset += count
            }
        }
        guard fsync(fd) == 0 else { throw CocoaError(.fileWriteUnknown) }
        succeeded = true
    }

    /// Best-effort overwrite of one local regular file, then unlink. Not physical
    /// erasure: flash translation, CoW, snapshots, backups and other copies remain.
    /// Caller MUST obtain explicit confirmation for this exact file immediately before use.
    public static func overwriteAndRemove(_ url: URL) throws {
        #if os(iOS)
        throw CocoaError(.featureUnsupported)
        #else
        let fd = open(url.path, O_WRONLY | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK)
        guard fd >= 0 else { throw CocoaError(.fileWriteNoPermission) }
        defer { close(fd) }
        guard c_file_local_volume(fd) == 1 else { throw CocoaError(.featureUnsupported) }
        #if canImport(Darwin)
        guard try url.resourceValues(forKeys: [.isUbiquitousItemKey]).isUbiquitousItem != true else { throw CocoaError(.featureUnsupported) }
        #endif
        var before = stat()
        guard fstat(fd, &before) == 0, before.st_mode & S_IFMT == S_IFREG, before.st_nlink == 1,
              before.st_size >= 0 else { throw CocoaError(.featureUnsupported) }
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else { throw CocoaError(.fileLocking) }
        defer { flock(fd, LOCK_UN) }
        var remaining = before.st_size
        while remaining > 0 {
            let bytes = PasswordFileProtection.random(Int(min(remaining, 65536)))
            try bytes.withUnsafeBytes { raw in
                var offset = 0
                while offset < bytes.count {
                    let count = write(fd, raw.baseAddress!.advanced(by: offset), bytes.count - offset)
                    if count < 0 && errno == EINTR { continue }
                    guard count > 0 else { throw CocoaError(.fileWriteUnknown) }
                    offset += count
                }
            }
            remaining -= numericCast(bytes.count)
        }
        guard fsync(fd) == 0 else { throw CocoaError(.fileWriteUnknown) }
        var current = stat()
        guard lstat(url.path, &current) == 0, current.st_dev == before.st_dev,
              current.st_ino == before.st_ino, current.st_nlink == 1, current.st_size == before.st_size else {
            throw CocoaError(.fileWriteUnknown)
        }
        guard unlink(url.path) == 0 else { throw CocoaError(.fileWriteUnknown) }
        #endif
    }
}
