import Darwin
import Foundation

/// Creates `/private/tmp/Fugu` and a unique `tmp.XXXXXX` child.
/// Callers still read `errno` after a nil return.
@objc(FuguTemporaryDirectory)
final class FuguTemporaryDirectory: NSObject {
    private static let parentPath = "/private/tmp/Fugu"

    @objc(makeWithMode:)
    static func make(withMode mode: mode_t) -> String? {
        let fileManager = FileManager.default
        var isDirectory = ObjCBool(false)
        if fileManager.fileExists(atPath: parentPath, isDirectory: &isDirectory) {
            if !isDirectory.boolValue {
                errno = ENOTDIR
                return nil
            }
        } else {
            do {
                try fileManager.createDirectory(
                    atPath: parentPath,
                    withIntermediateDirectories: true,
                    attributes: [.posixPermissions: NSNumber(value: UInt16(mode))]
                )
            } catch {
                assignErrno(error)
                return nil
            }
        }

        let template = parentPath + "/tmp.XXXXXX"
        return template.withCString { source in
            let length = strlen(source) + 1
            let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: length)
            defer { buffer.deallocate() }
            memcpy(buffer, source, length)
            guard mkdtemp(buffer) != nil else {
                return nil
            }
            return String(cString: buffer)
        }
    }

    private static func assignErrno(_ error: Error) {
        let nsError = error as NSError
        if nsError.domain == NSPOSIXErrorDomain {
            errno = Int32(nsError.code)
            return
        }
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError,
           underlying.domain == NSPOSIXErrorDomain {
            errno = Int32(underlying.code)
            return
        }
        errno = EIO
    }
}
