public struct RainbowFormatStyle: Equatable, Sendable {
    public static let `default` = RainbowFormatStyle()

    public let indentation: String
    public let newline: String

    public init(indentation: String = "  ", newline: String = "\n") {
        self.indentation = indentation
        self.newline = newline
    }
}
