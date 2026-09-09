public struct RainbowParser: Sendable {
    public init() {}

    public func decode(_ source: String) throws(RainbowParseError) -> RainbowDocument {
        try RainbowDecoder().decode(source)
    }

    public func encode(
        _ document: RainbowDocument,
        style: RainbowFormatStyle = .default
    ) -> String {
        RainbowEncoder(style: style).encode(document)
    }
}
