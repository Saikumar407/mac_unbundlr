import Foundation

/// Calls the ProfilePilot companion API to turn a natural-language prompt
/// like `"laravel"` into a `Workspace` plan. The endpoint is user-configurable
/// (default: none — feature is off unless the user opts in in Settings).
final class AIWorkspaceService {

    struct Endpoint: Codable {
        var url: URL
        var authHeader: String?     // e.g. "Bearer sk-…"
    }

    var endpoint: Endpoint? {
        get {
            guard let data = UserDefaults.standard.data(forKey: "aiEndpoint") else { return nil }
            return try? JSONDecoder().decode(Endpoint.self, from: data)
        }
        set {
            if let newValue,
               let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "aiEndpoint")
            } else {
                UserDefaults.standard.removeObject(forKey: "aiEndpoint")
            }
        }
    }

    var isConfigured: Bool { endpoint != nil }

    func plan(prompt: String, hint: String? = nil) async throws -> AIPlanResponse {
        guard let endpoint else {
            throw NSError(domain: "AIWorkspace", code: 1,
                          userInfo: [NSLocalizedDescriptionKey:
                            "AI Workspace endpoint not configured. Enable it in Settings."])
        }
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let auth = endpoint.authHeader {
            request.setValue(auth, forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(AIPlanRequest(prompt: prompt, hint: hint))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "AIWorkspace", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "AI request failed: \(body)"])
        }
        return try JSONDecoder().decode(AIPlanResponse.self, from: data)
    }

    /// Convert an `AIPlanResponse` into a `Workspace` we can save.
    func materialise(_ plan: AIPlanResponse) -> Workspace {
        var items: [WorkspaceItem] = []
        for it in plan.items {
            let id = UUID()
            let delay = it.delayMs ?? 300
            switch it.kind {
            case "browserProfile":
                items.append(.browserProfile(id: id, profileKey: it.value, delayMs: delay))
            case "app":
                items.append(.app(id: id, appPath: it.value, delayMs: delay))
            case "url":
                items.append(.url(id: id, url: it.value, browserProfileKey: nil, delayMs: delay))
            case "shell":
                items.append(.shell(id: id, command: it.value, workingDirectory: nil, delayMs: delay))
            default: break
            }
        }
        return Workspace(name: plan.name.isEmpty ? "Untitled" : plan.name,
                         symbol: plan.symbol.isEmpty ? "sparkles" : plan.symbol,
                         items: items)
    }
}
