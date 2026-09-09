public struct RainbowEncoder: Sendable {
    private let style: RainbowFormatStyle

    public init(style: RainbowFormatStyle = .default) {
        self.style = style
    }

    public func encode(_ document: RainbowDocument) -> String {
        RainbowPrinter(style: style).print(document)
    }
}
