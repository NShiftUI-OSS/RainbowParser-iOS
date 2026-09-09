enum RainbowTokenKind: Equatable, Sendable {
    case identifier(String)
    case string(String)
    case int(Int)
    case double(Double)
    case version(String)
    case bool(Bool)
    case null
    case leftParen
    case rightParen
    case leftBrace
    case rightBrace
    case leftBracket
    case rightBracket
    case colon
    case comma
    case at
    case tagged(language: EmbeddedLanguage, body: RainbowTaggedBody, bodyRange: RainbowSourceRange)
    /// Line comment `//…` — payload is the text after `//`.
    case comment(String)
    case eof
}
