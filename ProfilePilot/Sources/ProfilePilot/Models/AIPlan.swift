import Foundation

// MARK: - AI Workspace API

struct AIPlanRequest: Codable {
    let prompt: String
    let hint: String?
}

struct AIPlanResponse: Codable {
    let name: String
    let symbol: String
    let items: [AIPlanItem]
}

struct AIPlanItem: Codable {
    let kind: String        // "browserProfile" | "app" | "url" | "shell"
    let value: String       // browser::profileKey | /Applications/x.app | https://… | shell command
    let delayMs: Int?
    let note: String?
}
