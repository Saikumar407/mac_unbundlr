import XCTest
@testable import ProfilePilot

final class BundleFactoryTests: XCTestCase {

    func test_wrapper_name_and_bundle_id_are_stable() {
        let factory = BundleFactory()
        let profile = BrowserProfile(
            id: UUID(),
            browserBundleID: "com.google.Chrome",
            browserKind: .chrome,
            directory: "Profile 1",
            displayName: "FG Designs",
            avatarSlug: nil, userEmail: nil, lastActiveISO: nil
        )
        XCTAssertEqual(factory.wrapperName(for: profile), "Chrome — FG Designs")
        let a = factory.wrapperBundleID(for: profile)
        let b = factory.wrapperBundleID(for: profile)
        XCTAssertEqual(a, b, "Bundle ID must be deterministic")
        XCTAssertTrue(a.hasPrefix("com.profilepilot.wrapper.chrome."))
    }
}
