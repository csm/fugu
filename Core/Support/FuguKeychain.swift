import Foundation

/// Forwards to `keychain.c`. That file still owns the `SecItem` calls.
@objc(FuguKeychain)
final class FuguKeychain: NSObject {
    /// Copies the malloc'd C buffer into a String and frees it.
    /// `status` receives the `OSStatus` from `getpwdfromkeychain`, including `errSecItemNotFound`.
    @objc(passwordForService:account:error:)
    static func password(forService service: String, account: String, error status: UnsafeMutablePointer<OSStatus>) -> String? {
        service.withCString { servicePointer in
            account.withCString { accountPointer in
                guard let raw = getpwdfromkeychain(servicePointer, accountPointer, status) else {
                    return nil
                }
                let value = String(cString: raw)
                free(raw)
                return value
            }
        }
    }

    @objc(addPassword:service:account:)
    static func addPassword(_ password: String, service: String, account: String) {
        password.withCString { passwordPointer in
            service.withCString { servicePointer in
                account.withCString { accountPointer in
                    addpwdtokeychain(servicePointer, accountPointer, passwordPointer)
                }
            }
        }
    }
}
