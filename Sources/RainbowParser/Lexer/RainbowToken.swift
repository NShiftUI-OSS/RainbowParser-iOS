struct RainbowToken: Equatable, Sendable {
    let kind: RainbowTokenKind
    let range: RainbowSourceRange

    init(kind: RainbowTokenKind, range: RainbowSourceRange) {
        self.kind = kind
        self.range = range
    }
}
