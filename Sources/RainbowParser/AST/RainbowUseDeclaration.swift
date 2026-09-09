public struct RainbowUseDeclaration: Equatable, Sendable {
    public let name: String
    public let version: String
    public let leading: RainbowLeadingTrivia

    public init(
        name: String,
        version: String,
        leading: RainbowLeadingTrivia = RainbowLeadingTrivia()
    ) {
        self.name = name
        self.version = version
        self.leading = leading
    }
}
