import Foundation

// MARK: - Capabilities / Safety

/// Mirrors JS `WorkspaceCapabilities`.
public struct WorkspaceCapabilities: Sendable, Codable {
    public let hasFilesystem: Bool
    public let hasSandbox: Bool
    public let canBM25: Bool
    public let canVector: Bool
    public let canHybrid: Bool
    public let hasSkills: Bool

    public init(
        hasFilesystem: Bool,
        hasSandbox: Bool,
        canBM25: Bool,
        canVector: Bool,
        canHybrid: Bool,
        hasSkills: Bool
    ) {
        self.hasFilesystem = hasFilesystem
        self.hasSandbox = hasSandbox
        self.canBM25 = canBM25
        self.canVector = canVector
        self.canHybrid = canHybrid
        self.hasSkills = hasSkills
    }
}

/// Mirrors JS `WorkspaceSafety`.
public struct WorkspaceSafety: Sendable, Codable {
    public let readOnly: Bool

    public init(readOnly: Bool) {
        self.readOnly = readOnly
    }
}

// MARK: - Workspace info / list

/// Mirrors JS `WorkspaceInfoResponse`.
public struct WorkspaceInfoResponse: Sendable, Codable {
    public let isWorkspaceConfigured: Bool
    public let id: String?
    public let name: String?
    public let status: String?
    public let capabilities: WorkspaceCapabilities?
    public let safety: WorkspaceSafety?
}

/// Mirrors JS `WorkspaceItem`.
public struct WorkspaceItem: Sendable, Codable {
    public let id: String
    public let name: String
    public let status: String
    /// Source is `"mastra" | "agent"` on the wire. Kept as `String` for
    /// forward compatibility; use `WorkspaceSource(rawValue:)` to match.
    public let source: String
    public let agentId: String?
    public let agentName: String?
    public let capabilities: WorkspaceCapabilities
    public let safety: WorkspaceSafety
}

/// Convenience enum mirroring the JS union `'mastra' | 'agent'`.
public enum WorkspaceSource: String, Sendable, Codable {
    case mastra
    case agent
}

/// Mirrors JS `ListWorkspacesResponse`.
public struct ListWorkspacesResponse: Sendable, Codable {
    public let workspaces: [WorkspaceItem]
}

// MARK: - File entries / fs responses

/// Mirrors JS `WorkspaceFileEntry`.
public struct WorkspaceFileEntry: Sendable, Codable {
    public let name: String
    public let type: WorkspaceFileType
    public let size: Int?
}

/// Mirrors JS union `'file' | 'directory'`.
public enum WorkspaceFileType: String, Sendable, Codable {
    case file
    case directory
}

/// Mirrors JS `WorkspaceFsReadResponse`.
public struct WorkspaceFsReadResponse: Sendable, Codable {
    public let path: String
    public let content: String
    public let type: WorkspaceFileType
    public let size: Int?
    public let mimeType: String?
}

/// Mirrors JS `WorkspaceFsWriteResponse`.
public struct WorkspaceFsWriteResponse: Sendable, Codable {
    public let success: Bool
    public let path: String
}

/// Mirrors JS `WorkspaceFsListResponse`.
public struct WorkspaceFsListResponse: Sendable, Codable {
    public let path: String
    public let entries: [WorkspaceFileEntry]
}

/// Mirrors JS `WorkspaceFsDeleteResponse`.
public struct WorkspaceFsDeleteResponse: Sendable, Codable {
    public let success: Bool
    public let path: String
}

/// Mirrors JS `WorkspaceFsMkdirResponse`.
public struct WorkspaceFsMkdirResponse: Sendable, Codable {
    public let success: Bool
    public let path: String
}

/// Mirrors JS `WorkspaceFsStatResponse`.
public struct WorkspaceFsStatResponse: Sendable, Codable {
    public let path: String
    public let type: WorkspaceFileType
    public let size: Int?
    public let createdAt: String?
    public let modifiedAt: String?
    public let mimeType: String?
}

// MARK: - Write options

/// Mirrors JS write options (second argument shape on `writeFile`).
public struct WorkspaceWriteOptions: Sendable {
    public var encoding: WorkspaceFileEncoding?
    public var recursive: Bool?

    public init(encoding: WorkspaceFileEncoding? = nil, recursive: Bool? = nil) {
        self.encoding = encoding
        self.recursive = recursive
    }
}

/// Mirrors JS union `'utf-8' | 'base64'`.
public enum WorkspaceFileEncoding: String, Sendable, Codable {
    case utf8 = "utf-8"
    case base64
}

/// Mirrors JS delete options.
public struct WorkspaceDeleteOptions: Sendable {
    public var recursive: Bool?
    public var force: Bool?

    public init(recursive: Bool? = nil, force: Bool? = nil) {
        self.recursive = recursive
        self.force = force
    }
}

// MARK: - Search

/// Mirrors JS `WorkspaceSearchMode`.
public enum WorkspaceSearchMode: String, Sendable, Codable {
    case bm25
    case vector
    case hybrid
}

/// Mirrors JS `WorkspaceSearchResult`.
public struct WorkspaceSearchResult: Sendable, Codable {
    public let id: String
    public let content: String
    public let score: Double
    public let lineRange: LineRange?
    public let scoreDetails: ScoreDetails?

    public struct LineRange: Sendable, Codable {
        public let start: Int
        public let end: Int
    }

    public struct ScoreDetails: Sendable, Codable {
        public let vector: Double?
        public let bm25: Double?
    }
}

/// Mirrors JS `WorkspaceSearchParams`.
public struct WorkspaceSearchParams: Sendable {
    public var query: String
    public var topK: Int?
    public var mode: WorkspaceSearchMode?
    public var minScore: Double?

    public init(
        query: String,
        topK: Int? = nil,
        mode: WorkspaceSearchMode? = nil,
        minScore: Double? = nil
    ) {
        self.query = query
        self.topK = topK
        self.mode = mode
        self.minScore = minScore
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = [.init(name: "query", value: query)]
        if let topK { items.append(.init(name: "topK", value: String(topK))) }
        if let mode { items.append(.init(name: "mode", value: mode.rawValue)) }
        if let minScore { items.append(.init(name: "minScore", value: String(minScore))) }
        return items
    }
}

/// Mirrors JS `WorkspaceSearchResponse`.
public struct WorkspaceSearchResponse: Sendable, Codable {
    public let results: [WorkspaceSearchResult]
    public let query: String
    public let mode: WorkspaceSearchMode
}

// MARK: - Index

/// Mirrors JS `WorkspaceIndexParams`.
public struct WorkspaceIndexParams: Sendable {
    public var path: String
    public var content: String
    public var metadata: [String: JSONValue]?

    public init(
        path: String,
        content: String,
        metadata: [String: JSONValue]? = nil
    ) {
        self.path = path
        self.content = content
        self.metadata = metadata
    }

    func body() -> JSONValue {
        var obj: JSONObject = [
            "path": .string(path),
            "content": .string(content),
        ]
        if let metadata {
            obj["metadata"] = .object(metadata)
        }
        return .object(obj)
    }
}

/// Mirrors JS `WorkspaceIndexResponse`.
public struct WorkspaceIndexResponse: Sendable, Codable {
    public let success: Bool
    public let path: String
}

// MARK: - Skills

/// Mirrors JS `SkillSource` discriminated union.
public enum SkillSource: Sendable, Codable, Hashable {
    case external(packagePath: String)
    case local(projectPath: String)
    case managed(mastraPath: String)

    private enum CodingKeys: String, CodingKey {
        case type
        case packagePath
        case projectPath
        case mastraPath
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "external":
            self = .external(packagePath: try c.decode(String.self, forKey: .packagePath))
        case "local":
            self = .local(projectPath: try c.decode(String.self, forKey: .projectPath))
        case "managed":
            self = .managed(mastraPath: try c.decode(String.self, forKey: .mastraPath))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: c,
                debugDescription: "Unknown SkillSource type \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .external(let p):
            try c.encode("external", forKey: .type)
            try c.encode(p, forKey: .packagePath)
        case .local(let p):
            try c.encode("local", forKey: .type)
            try c.encode(p, forKey: .projectPath)
        case .managed(let p):
            try c.encode("managed", forKey: .type)
            try c.encode(p, forKey: .mastraPath)
        }
    }
}

/// Mirrors JS `SkillMetadata`.
public struct SkillMetadata: Sendable, Codable {
    public let name: String
    public let description: String
    public let license: String?
    public let compatibility: String?
    public let metadata: [String: String]?
    public let path: String
}

/// Mirrors JS `Skill` (extends `SkillMetadata` with instructions, source,
/// references, scripts, assets).
public struct Skill: Sendable, Codable {
    public let name: String
    public let description: String
    public let license: String?
    public let compatibility: String?
    public let metadata: [String: String]?
    public let path: String
    public let instructions: String
    public let source: SkillSource
    public let references: [String]
    public let scripts: [String]
    public let assets: [String]
}

/// Mirrors JS `ListSkillsResponse`.
public struct ListSkillsResponse: Sendable, Codable {
    public let skills: [SkillMetadata]
    public let isSkillsConfigured: Bool
}

/// Mirrors JS `SkillSearchResult`.
public struct SkillSearchResult: Sendable, Codable {
    public let skillName: String
    public let source: String
    public let content: String
    public let score: Double
    public let lineRange: WorkspaceSearchResult.LineRange?
    public let scoreDetails: WorkspaceSearchResult.ScoreDetails?
}

/// Mirrors JS `SearchSkillsParams`.
public struct SearchSkillsParams: Sendable {
    public var query: String
    public var topK: Int?
    public var minScore: Double?
    public var skillNames: [String]?
    public var includeReferences: Bool?

    public init(
        query: String,
        topK: Int? = nil,
        minScore: Double? = nil,
        skillNames: [String]? = nil,
        includeReferences: Bool? = nil
    ) {
        self.query = query
        self.topK = topK
        self.minScore = minScore
        self.skillNames = skillNames
        self.includeReferences = includeReferences
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = [.init(name: "query", value: query)]
        if let topK { items.append(.init(name: "topK", value: String(topK))) }
        if let minScore { items.append(.init(name: "minScore", value: String(minScore))) }
        if let skillNames, !skillNames.isEmpty {
            items.append(.init(name: "skillNames", value: skillNames.joined(separator: ",")))
        }
        if let includeReferences {
            items.append(.init(name: "includeReferences", value: String(includeReferences)))
        }
        return items
    }
}

/// Mirrors JS `SearchSkillsResponse`.
public struct SearchSkillsResponse: Sendable, Codable {
    public let results: [SkillSearchResult]
    public let query: String
}

/// Mirrors JS `ListSkillReferencesResponse`.
public struct ListSkillReferencesResponse: Sendable, Codable {
    public let skillName: String
    public let references: [String]
}

/// Mirrors JS `GetSkillReferenceResponse`.
public struct GetSkillReferenceResponse: Sendable, Codable {
    public let skillName: String
    public let referencePath: String
    public let content: String
}
