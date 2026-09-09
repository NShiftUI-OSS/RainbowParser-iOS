public struct RainbowDiagnostic: Equatable, Sendable, CustomStringConvertible {
    public let code: String
    public let message: String
    public let severity: RainbowDiagnosticSeverity
    public let range: RainbowSourceRange

    public var description: String {
        "\(severity.rawValue.uppercased()) \(code) at \(range.start.line):\(range.start.column): \(message)"
    }

    public init(
        code: String,
        message: String,
        severity: RainbowDiagnosticSeverity = .error,
        range: RainbowSourceRange
    ) {
        self.code = code
        self.message = message
        self.severity = severity
        self.range = range
    }
}
