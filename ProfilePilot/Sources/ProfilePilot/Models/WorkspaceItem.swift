import Foundation

/// A single step of a workspace. Tagged union stored as Codable via `type` field.
enum WorkspaceItem: Identifiable, Hashable, Codable {
    case browserProfile(id: UUID, profileKey: String, delayMs: Int = 0)
    case app(id: UUID, appPath: String, delayMs: Int = 0)
    case url(id: UUID, url: String, browserProfileKey: String?, delayMs: Int = 0)
    case shell(id: UUID, command: String, workingDirectory: String?, delayMs: Int = 500)

    var id: UUID {
        switch self {
        case .browserProfile(let id, _, _),
             .app(let id, _, _),
             .url(let id, _, _, _),
             .shell(let id, _, _, _):
            return id
        }
    }

    var displayLabel: String {
        switch self {
        case .browserProfile(_, let key, _): return "Browser Profile · \(key)"
        case .app(_, let path, _): return URL(fileURLWithPath: path).lastPathComponent
        case .url(_, let url, _, _): return url
        case .shell(_, let cmd, _, _): return "$ \(cmd)"
        }
    }

    var sfSymbol: String {
        switch self {
        case .browserProfile: return "person.crop.circle.fill"
        case .app:            return "app.fill"
        case .url:            return "link"
        case .shell:          return "terminal.fill"
        }
    }

    // MARK: - Codable via type discriminator
    private enum CodingKeys: String, CodingKey {
        case type, id, profileKey, appPath, url, browserProfileKey, command, workingDirectory, delayMs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        let id = try c.decode(UUID.self, forKey: .id)
        let delayMs = (try? c.decode(Int.self, forKey: .delayMs)) ?? 0
        switch type {
        case "browserProfile":
            self = .browserProfile(id: id,
                                   profileKey: try c.decode(String.self, forKey: .profileKey),
                                   delayMs: delayMs)
        case "app":
            self = .app(id: id,
                        appPath: try c.decode(String.self, forKey: .appPath),
                        delayMs: delayMs)
        case "url":
            self = .url(id: id,
                        url: try c.decode(String.self, forKey: .url),
                        browserProfileKey: try? c.decode(String.self, forKey: .browserProfileKey),
                        delayMs: delayMs)
        case "shell":
            self = .shell(id: id,
                          command: try c.decode(String.self, forKey: .command),
                          workingDirectory: try? c.decode(String.self, forKey: .workingDirectory),
                          delayMs: delayMs)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: c,
                                                    debugDescription: "Unknown item type: \(type)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        switch self {
        case .browserProfile(_, let key, let delay):
            try c.encode("browserProfile", forKey: .type)
            try c.encode(key, forKey: .profileKey)
            try c.encode(delay, forKey: .delayMs)
        case .app(_, let path, let delay):
            try c.encode("app", forKey: .type)
            try c.encode(path, forKey: .appPath)
            try c.encode(delay, forKey: .delayMs)
        case .url(_, let url, let key, let delay):
            try c.encode("url", forKey: .type)
            try c.encode(url, forKey: .url)
            try c.encodeIfPresent(key, forKey: .browserProfileKey)
            try c.encode(delay, forKey: .delayMs)
        case .shell(_, let cmd, let wd, let delay):
            try c.encode("shell", forKey: .type)
            try c.encode(cmd, forKey: .command)
            try c.encodeIfPresent(wd, forKey: .workingDirectory)
            try c.encode(delay, forKey: .delayMs)
        }
    }
}
