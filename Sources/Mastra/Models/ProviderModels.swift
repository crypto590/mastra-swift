import Foundation

// MARK: - Tool Provider Types

/// Mirrors JS `ToolProviderInfo` from `types.ts`.
public struct ToolProviderInfo: Sendable, Codable, Hashable {
    public let id: String
    public let name: String
    public let description: String?

    public init(id: String, name: String, description: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
    }
}

/// Mirrors JS `ToolProviderToolkit` from `types.ts`.
public struct ToolProviderToolkit: Sendable, Codable, Hashable {
    public let slug: String
    public let name: String
    public let description: String?
    public let icon: String?

    public init(slug: String, name: String, description: String? = nil, icon: String? = nil) {
        self.slug = slug
        self.name = name
        self.description = description
        self.icon = icon
    }
}

/// Mirrors JS `ToolProviderToolInfo` from `types.ts`.
public struct ToolProviderToolInfo: Sendable, Codable, Hashable {
    public let slug: String
    public let name: String
    public let description: String?
    public let toolkit: String?

    public init(slug: String, name: String, description: String? = nil, toolkit: String? = nil) {
        self.slug = slug
        self.name = name
        self.description = description
        self.toolkit = toolkit
    }
}

/// Mirrors JS `ToolProviderPagination` from `types.ts`.
public struct ToolProviderPagination: Sendable, Codable, Hashable {
    public let total: Int?
    public let page: Int?
    public let perPage: Int?
    public let hasMore: Bool

    public init(total: Int? = nil, page: Int? = nil, perPage: Int? = nil, hasMore: Bool) {
        self.total = total
        self.page = page
        self.perPage = perPage
        self.hasMore = hasMore
    }
}

/// Mirrors JS `ListToolProvidersResponse`.
public struct ListToolProvidersResponse: Sendable, Codable {
    public let providers: [ToolProviderInfo]

    public init(providers: [ToolProviderInfo]) {
        self.providers = providers
    }
}

/// Mirrors JS `ListToolProviderToolkitsResponse`.
public struct ListToolProviderToolkitsResponse: Sendable, Codable {
    public let data: [ToolProviderToolkit]
    public let pagination: ToolProviderPagination?

    public init(data: [ToolProviderToolkit], pagination: ToolProviderPagination? = nil) {
        self.data = data
        self.pagination = pagination
    }
}

/// Mirrors JS `ListToolProviderToolsParams`.
public struct ListToolProviderToolsParams: Sendable {
    public var toolkit: String?
    public var search: String?
    public var page: Int?
    public var perPage: Int?

    public init(
        toolkit: String? = nil,
        search: String? = nil,
        page: Int? = nil,
        perPage: Int? = nil
    ) {
        self.toolkit = toolkit
        self.search = search
        self.page = page
        self.perPage = perPage
    }

    /// Query items matching the JS URLSearchParams assembly in `tool-provider.ts`.
    public var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let toolkit { items.append(URLQueryItem(name: "toolkit", value: toolkit)) }
        if let search { items.append(URLQueryItem(name: "search", value: search)) }
        if let page { items.append(URLQueryItem(name: "page", value: String(page))) }
        if let perPage { items.append(URLQueryItem(name: "perPage", value: String(perPage))) }
        return items
    }
}

/// Mirrors JS `ListToolProviderToolsResponse`.
public struct ListToolProviderToolsResponse: Sendable, Codable {
    public let data: [ToolProviderToolInfo]
    public let pagination: ToolProviderPagination?

    public init(data: [ToolProviderToolInfo], pagination: ToolProviderPagination? = nil) {
        self.data = data
        self.pagination = pagination
    }
}

/// Mirrors JS `GetToolProviderToolSchemaResponse = Record<string, unknown>`.
public typealias GetToolProviderToolSchemaResponse = JSONValue

// MARK: - Processor Provider Types

/// Mirrors JS `ProcessorProviderPhase` — prefixed-form phase names returned by
/// the provider endpoints (distinct from `ProcessorPhase`).
public enum ProcessorProviderPhase: String, Sendable, Codable, Hashable {
    case processInput
    case processInputStep
    case processOutputStream
    case processOutputResult
    case processOutputStep
}

/// Mirrors JS `ProcessorProviderInfo`.
public struct ProcessorProviderInfo: Sendable, Codable, Hashable {
    public let id: String
    public let name: String
    public let description: String?
    public let availablePhases: [ProcessorProviderPhase]

    public init(
        id: String,
        name: String,
        description: String? = nil,
        availablePhases: [ProcessorProviderPhase]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.availablePhases = availablePhases
    }
}

/// Mirrors JS `GetProcessorProvidersResponse`.
public struct GetProcessorProvidersResponse: Sendable, Codable {
    public let providers: [ProcessorProviderInfo]

    public init(providers: [ProcessorProviderInfo]) {
        self.providers = providers
    }
}

/// Mirrors JS `GetProcessorProviderResponse`.
public struct GetProcessorProviderResponse: Sendable, Codable {
    public let id: String
    public let name: String
    public let description: String?
    public let availablePhases: [ProcessorProviderPhase]
    public let configSchema: JSONValue

    public init(
        id: String,
        name: String,
        description: String? = nil,
        availablePhases: [ProcessorProviderPhase],
        configSchema: JSONValue
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.availablePhases = availablePhases
        self.configSchema = configSchema
    }
}

// MARK: - System Package Types

/// Mirrors JS `MastraPackage` from `types.ts`.
public struct MastraPackage: Sendable, Codable, Hashable {
    public let name: String
    public let version: String

    public init(name: String, version: String) {
        self.name = name
        self.version = version
    }
}

/// Mirrors JS `GetSystemPackagesResponse` from `types.ts`.
/// Alias retained as `SystemPackageInfo` for the repo's typed naming convention.
public struct SystemPackageInfo: Sendable, Codable {
    public let packages: [MastraPackage]
    public let isDev: Bool
    public let cmsEnabled: Bool
    public let storageType: String?
    public let observabilityStorageType: String?

    public init(
        packages: [MastraPackage],
        isDev: Bool,
        cmsEnabled: Bool,
        storageType: String? = nil,
        observabilityStorageType: String? = nil
    ) {
        self.packages = packages
        self.isDev = isDev
        self.cmsEnabled = cmsEnabled
        self.storageType = storageType
        self.observabilityStorageType = observabilityStorageType
    }
}

/// Alias matching the JS response name precisely.
public typealias GetSystemPackagesResponse = SystemPackageInfo
