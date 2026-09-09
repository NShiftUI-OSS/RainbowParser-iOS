/// Leading `//` line comments attached to the following `use` / node / parameter.
public struct RainbowLeadingTrivia: Equatable, Sendable {
    /// Text after `//` (including a leading space when the source had one).
    public let comments: [String]

    public init(comments: [String] = []) {
        self.comments = comments
    }

    public var isEmpty: Bool {
        comments.isEmpty
    }
}
