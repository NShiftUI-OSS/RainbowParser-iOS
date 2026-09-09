struct SourceText: Equatable, Sendable {
    let contents: String

    init(_ contents: String) {
        self.contents = contents
    }
}
