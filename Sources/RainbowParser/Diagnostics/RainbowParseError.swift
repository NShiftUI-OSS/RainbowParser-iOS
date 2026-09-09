public struct RainbowParseError: Error, Equatable, Sendable, CustomStringConvertible {
    public let diagnostics: [RainbowDiagnostic]

    public var description: String {
        diagnostics.map(\.description).joined(separator: "\n")
    }

    public init(diagnostics: [RainbowDiagnostic]) {
        self.diagnostics = diagnostics
    }

    public init(_ diagnostic: RainbowDiagnostic) {
        self.diagnostics = [diagnostic]
    }
}
