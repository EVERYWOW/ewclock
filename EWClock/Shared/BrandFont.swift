import CoreText
import Foundation

enum BrandFont {
    static let postScriptName = "EVERYWOWDisplay-Black"

    static func register() throws {
        let bundle = Bundle(for: BundleToken.self)
        guard let fontURL = bundle.url(
            forResource: "EVERYWOWDisplayVF",
            withExtension: "ttf"
        ) else {
            throw RegistrationError.resourceMissing
        }

        var unmanagedError: Unmanaged<CFError>?
        let registered = CTFontManagerRegisterFontsForURL(
            fontURL as CFURL,
            .process,
            &unmanagedError
        )

        if !registered {
            let registrationError = unmanagedError?.takeRetainedValue()
            guard isApprovedInstanceAvailable else {
                throw RegistrationError.coreTextFailure(
                    registrationError?.localizedDescription
                        ?? "Unknown CoreText error"
                )
            }
        }

        guard isApprovedInstanceAvailable else {
            throw RegistrationError.approvedInstanceUnavailable
        }
    }

    private static var isApprovedInstanceAvailable: Bool {
        let font = CTFontCreateWithName(postScriptName as CFString, 12, nil)
        return CTFontCopyPostScriptName(font) as String == postScriptName
    }

    private final class BundleToken: NSObject {}

    enum RegistrationError: Error, Equatable {
        case resourceMissing
        case coreTextFailure(String)
        case approvedInstanceUnavailable
    }
}
