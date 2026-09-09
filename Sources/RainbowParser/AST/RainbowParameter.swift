public struct RainbowParameter: Equatable, Sendable {
    public let name: String
    public let value: RainbowValue
    public let leading: RainbowLeadingTrivia

    public init(
        name: String,
        value: RainbowValue,
        leading: RainbowLeadingTrivia = RainbowLeadingTrivia()
    ) {
        self.name = name
        self.value = value
        self.leading = leading
    }
}
