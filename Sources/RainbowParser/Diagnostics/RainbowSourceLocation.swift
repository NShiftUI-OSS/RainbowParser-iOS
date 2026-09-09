public struct RainbowSourceLocation: Equatable, Comparable, Sendable {
    public let offset: Int
    public let line: Int
    public let column: Int

    public init(offset: Int, line: Int, column: Int) {
        self.offset = offset
        self.line = line
        self.column = column
    }

    public static func < (lhs: RainbowSourceLocation, rhs: RainbowSourceLocation) -> Bool {
        lhs.offset < rhs.offset
    }
}
