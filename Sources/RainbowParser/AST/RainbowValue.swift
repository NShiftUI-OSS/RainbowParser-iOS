public enum RainbowValue: Equatable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case identifier(String)
    case array([RainbowValue])
    case object([RainbowObjectEntry])
    case null
    /// `@LANG(...)` parameter payload (raw language text or whole-blob `#{Name}`).
    case tagged(language: EmbeddedLanguage, body: RainbowTaggedBody, bodyRange: RainbowSourceRange)
}
