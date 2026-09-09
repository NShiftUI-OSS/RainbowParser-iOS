public struct RainbowDecoder: Sendable {
    public init() {}

    public func decode(_ source: String) throws(RainbowParseError) -> RainbowDocument {
        var lexer = RainbowLexer(source: source)
        let tokens = try lexer.scanTokens()
        var parser = RainbowSyntaxParser(tokens: tokens)
        return try parser.parse()
    }
}
