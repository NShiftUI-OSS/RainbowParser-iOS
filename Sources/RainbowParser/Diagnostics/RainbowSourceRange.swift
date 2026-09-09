public struct RainbowSourceRange: Equatable, Sendable {
    public let start: RainbowSourceLocation
    public let end: RainbowSourceLocation

    public init(start: RainbowSourceLocation, end: RainbowSourceLocation) {
        self.start = start
        self.end = end
    }
}
