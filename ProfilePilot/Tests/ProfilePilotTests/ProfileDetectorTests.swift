import XCTest
@testable import ProfilePilot

final class ProfileDetectorTests: XCTestCase {

    func test_deterministic_uuid_is_stable() {
        let detector = ProfileDetector()
        // Uses the private helper via a re-implementation to check invariants
        // — we do not import the private method, we assert the observable
        // behaviour: parsing the same fixture twice produces identical UUIDs.
        let tempDir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fixture = tempDir.appending(path: "Local State")
        let json: [String: Any] = [
            "profile": [
                "info_cache": [
                    "Default":    ["name": "Personal"],
                    "Profile 1":  ["name": "Work"]
                ]
            ]
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        try! data.write(to: fixture)

        let browser = Browser(
            id: "com.google.Chrome",
            kind: .chrome,
            displayName: "Google Chrome",
            executableURL: URL(fileURLWithPath: "/Applications/Google Chrome.app"),
            userDataDirectory: tempDir
        )

        let a = detector.profiles(for: browser).map { $0.id }.sorted()
        let b = detector.profiles(for: browser).map { $0.id }.sorted()
        XCTAssertEqual(a, b, "Profile IDs must be deterministic across passes")
        XCTAssertEqual(a.count, 2)
    }

    func test_bad_local_state_returns_empty_list() {
        let detector = ProfileDetector()
        let browser = Browser(
            id: "com.google.Chrome",
            kind: .chrome,
            displayName: "Google Chrome",
            executableURL: URL(fileURLWithPath: "/Applications/Google Chrome.app"),
            userDataDirectory: URL(fileURLWithPath: "/nonexistent/path")
        )
        XCTAssertTrue(detector.profiles(for: browser).isEmpty)
    }
}
