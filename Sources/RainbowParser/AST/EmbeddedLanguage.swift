public enum EmbeddedLanguage: String, Equatable, Sendable {
    case json = "JSON"
    case yaml = "YAML"
    case xml = "XML"
    case html = "HTML"
    case markdown = "MARKDOWN"

    public static func parse(_ name: String) -> EmbeddedLanguage? {
        EmbeddedLanguage(rawValue: name)
    }

    public var asString: String { rawValue }
}

public enum RainbowTaggedBody: Equatable, Sendable {
    case text(String)
    case placeholder(String)

    public var hasPlaceholder: Bool {
        if case .placeholder = self { return true }
        return false
    }
}
