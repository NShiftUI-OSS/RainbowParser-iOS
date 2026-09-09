struct CharacterScanner {
    private let source: SourceText
    private var index: String.Index
    private(set) var location: RainbowSourceLocation

    struct Checkpoint {
        let index: String.Index
        let location: RainbowSourceLocation
    }

    var isAtEnd: Bool {
        index == source.contents.endIndex
    }

    init(source: SourceText) {
        self.source = source
        self.index = source.contents.startIndex
        self.location = RainbowSourceLocation(offset: 0, line: 1, column: 1)
    }

    func checkpoint() -> Checkpoint {
        Checkpoint(index: index, location: location)
    }

    mutating func restore(_ checkpoint: Checkpoint) {
        index = checkpoint.index
        location = checkpoint.location
    }

    func peek() -> Character? {
        guard !isAtEnd else { return nil }
        return source.contents[index]
    }

    func peekNext() -> Character? {
        guard !isAtEnd else { return nil }
        let nextIndex = source.contents.index(after: index)
        guard nextIndex != source.contents.endIndex else { return nil }
        return source.contents[nextIndex]
    }

    func peekOffset(_ offset: Int) -> Character? {
        var current = index
        for _ in 0..<offset {
            guard current != source.contents.endIndex else { return nil }
            current = source.contents.index(after: current)
        }
        guard current != source.contents.endIndex else { return nil }
        return source.contents[current]
    }

    func startsWith(_ text: String) -> Bool {
        var current = index
        for expected in text {
            guard current != source.contents.endIndex else { return false }
            if source.contents[current] != expected {
                return false
            }
            current = source.contents.index(after: current)
        }
        return true
    }

    @discardableResult
    mutating func advance() -> Character? {
        guard !isAtEnd else { return nil }

        let character = source.contents[index]
        index = source.contents.index(after: index)

        if character.isRainbowLineBreak {
            location = RainbowSourceLocation(
                offset: location.offset + 1,
                line: location.line + 1,
                column: 1
            )
        } else {
            location = RainbowSourceLocation(
                offset: location.offset + 1,
                line: location.line,
                column: location.column + 1
            )
        }

        return character
    }
}

private extension Character {
    var isRainbowLineBreak: Bool {
        self == "\n" || self == "\r" || self == "\r\n"
    }
}
