struct RainbowLexer {
    private var scanner: CharacterScanner
    private var diagnostics: [RainbowDiagnostic]

    init(source: String) {
        self.scanner = CharacterScanner(source: SourceText(source))
        self.diagnostics = []
    }

    mutating func scanTokens() throws(RainbowParseError) -> [RainbowToken] {
        var tokens: [RainbowToken] = []

        while !scanner.isAtEnd {
            skipWhitespace()
            guard !scanner.isAtEnd else { break }

            let start = scanner.location
            let character = scanner.advance()!

            switch character {
            case "(":
                tokens.append(makeToken(.leftParen, start: start))
            case ")":
                tokens.append(makeToken(.rightParen, start: start))
            case "{":
                tokens.append(makeToken(.leftBrace, start: start))
            case "}":
                tokens.append(makeToken(.rightBrace, start: start))
            case "[":
                tokens.append(makeToken(.leftBracket, start: start))
            case "]":
                tokens.append(makeToken(.rightBracket, start: start))
            case ":":
                tokens.append(makeToken(.colon, start: start))
            case ",":
                tokens.append(makeToken(.comma, start: start))
            case "/":
                if scanner.peek() == "/" {
                    scanner.advance()
                    var text = ""
                    while let next = scanner.peek(), next != "\n" {
                        text.append(scanner.advance()!)
                    }
                    if text.last == "\r" {
                        text.removeLast()
                    }
                    tokens.append(makeToken(.comment(text), start: start))
                } else {
                    appendUnexpectedCharacter("/", start: start)
                }
            case "@":
                if let token = tryScanTagged(start: start) {
                    tokens.append(token)
                } else {
                    tokens.append(makeToken(.at, start: start))
                }
            case "\"":
                if let token = scanString(start: start) {
                    tokens.append(token)
                }
            case "-":
                if let next = scanner.peek(), next.isRainbowDigit {
                    tokens.append(scanNumber(start: start, first: character))
                } else {
                    appendUnexpectedCharacter(character, start: start)
                }
            default:
                if character.isRainbowDigit {
                    tokens.append(scanNumber(start: start, first: character))
                } else if character.isRainbowIdentifierStart {
                    tokens.append(scanIdentifier(start: start, first: character))
                } else {
                    appendUnexpectedCharacter(character, start: start)
                }
            }
        }

        let eofLocation = scanner.location
        tokens.append(
            RainbowToken(
                kind: .eof,
                range: RainbowSourceRange(start: eofLocation, end: eofLocation)
            )
        )

        if diagnostics.isEmpty {
            return tokens
        }

        throw RainbowParseError(diagnostics: diagnostics)
    }

    private mutating func skipWhitespace() {
        while let character = scanner.peek(), character.isRainbowWhitespace {
            scanner.advance()
        }
    }

    private func makeToken(_ kind: RainbowTokenKind, start: RainbowSourceLocation) -> RainbowToken {
        RainbowToken(
            kind: kind,
            range: RainbowSourceRange(start: start, end: scanner.location)
        )
    }

    private mutating func scanString(start: RainbowSourceLocation) -> RainbowToken? {
        var value = ""

        while let character = scanner.peek() {
            if character == "\"" {
                scanner.advance()
                return makeToken(.string(value), start: start)
            }

            if character == "\n" {
                appendDiagnostic(
                    code: "rainbow.lexer.unterminatedString",
                    message: "Unterminated string literal.",
                    start: start,
                    end: scanner.location
                )
                return nil
            }

            if character == "\\" {
                scanner.advance()

                guard let escaped = scanner.advance() else {
                    appendDiagnostic(
                        code: "rainbow.lexer.unterminatedString",
                        message: "Unterminated string literal.",
                        start: start,
                        end: scanner.location
                    )
                    return nil
                }

                switch escaped {
                case "\"":
                    value.append("\"")
                case "\\":
                    value.append("\\")
                case "n":
                    value.append("\n")
                case "r":
                    value.append("\r")
                case "t":
                    value.append("\t")
                case "0":
                    value.append("\0")
                default:
                    appendDiagnostic(
                        code: "rainbow.lexer.invalidEscape",
                        message: "Invalid escape sequence \\\(escaped).",
                        start: start,
                        end: scanner.location
                    )
                }
            } else {
                value.append(character)
                scanner.advance()
            }
        }

        appendDiagnostic(
            code: "rainbow.lexer.unterminatedString",
            message: "Unterminated string literal.",
            start: start,
            end: scanner.location
        )
        return nil
    }

    private mutating func scanNumber(
        start: RainbowSourceLocation,
        first: Character
    ) -> RainbowToken {
        var text = String(first)

        while let character = scanner.peek(), character.isRainbowDigit {
            text.append(character)
            scanner.advance()
        }

        var dotCount = 0
        while scanner.peek() == ".", let next = scanner.peekNext(), next.isRainbowDigit {
            dotCount += 1
            text.append(".")
            scanner.advance()

            while let character = scanner.peek(), character.isRainbowDigit {
                text.append(character)
                scanner.advance()
            }
        }

        if dotCount >= 2 {
            return makeToken(.version(text), start: start)
        }

        if dotCount == 1 {
            return makeToken(.double(Double(text)!), start: start)
        }

        guard let value = Int(text) else {
            appendDiagnostic(
                code: "rainbow.lexer.invalidNumber",
                message: "Invalid number literal '\(text)'.",
                start: start,
                end: scanner.location
            )
            return makeToken(.int(0), start: start)
        }

        return makeToken(.int(value), start: start)
    }

    private mutating func scanIdentifier(
        start: RainbowSourceLocation,
        first: Character
    ) -> RainbowToken {
        var text = String(first)

        while let character = scanner.peek(), character.isRainbowIdentifierContinuation {
            text.append(character)
            scanner.advance()
        }

        switch text {
        case "true":
            return makeToken(.bool(true), start: start)
        case "false":
            return makeToken(.bool(false), start: start)
        case "null":
            return makeToken(.null, start: start)
        default:
            return makeToken(.identifier(text), start: start)
        }
    }

    /// After `@` has been consumed: try `@LANG(...)`. Restores scanner on mismatch.
    private mutating func tryScanTagged(start: RainbowSourceLocation) -> RainbowToken? {
        let checkpoint = scanner.checkpoint()

        guard let first = scanner.peek(), first.isRainbowIdentifierStart else {
            return nil
        }
        scanner.advance()
        var languageName = String(first)
        while let character = scanner.peek(), character.isRainbowIdentifierContinuation {
            languageName.append(character)
            scanner.advance()
        }

        guard scanner.peek() == "(" else {
            scanner.restore(checkpoint)
            return nil
        }
        scanner.advance()

        guard let language = EmbeddedLanguage.parse(languageName) else {
            appendDiagnostic(
                code: "rainbow.lexer.unknownEmbeddedLanguage",
                message: "Unknown embedded language '@\(languageName)'. Expected JSON, YAML, XML, HTML, or MARKDOWN.",
                start: start,
                end: scanner.location
            )
            _ = scanTaggedRawBody(tagStart: start, language: .json)
            return nil
        }

        let bodyStart = scanner.location
        if scanner.peek() == "#", scanner.peekNext() == "{" {
            scanner.advance() // #
            guard let name = scanPlaceholderName(start: bodyStart) else {
                return nil
            }
            let bodyEnd = scanner.location
            guard scanner.peek() == ")" else {
                appendDiagnostic(
                    code: "rainbow.lexer.unterminatedTagged",
                    message: "Expected ')' after '@\(language.asString)(#{\(name)})'.",
                    start: start,
                    end: scanner.location
                )
                return nil
            }
            scanner.advance()
            return RainbowToken(
                kind: .tagged(
                    language: language,
                    body: .placeholder(name),
                    bodyRange: RainbowSourceRange(start: bodyStart, end: bodyEnd)
                ),
                range: RainbowSourceRange(start: start, end: scanner.location)
            )
        }

        guard let (text, bodyEnd) = scanTaggedRawBody(tagStart: start, language: language) else {
            return nil
        }

        return RainbowToken(
            kind: .tagged(
                language: language,
                body: .text(text),
                bodyRange: RainbowSourceRange(start: bodyStart, end: bodyEnd)
            ),
            range: RainbowSourceRange(start: start, end: scanner.location)
        )
    }

    private mutating func scanPlaceholderName(start: RainbowSourceLocation) -> String? {
        guard scanner.peek() == "{" else {
            appendDiagnostic(
                code: "rainbow.lexer.invalidPlaceholder",
                message: "Expected placeholder name after '#{'.",
                start: start,
                end: scanner.location
            )
            return nil
        }
        scanner.advance()

        guard let first = scanner.peek(), first.isRainbowIdentifierStart else {
            appendDiagnostic(
                code: "rainbow.lexer.invalidPlaceholder",
                message: "Expected placeholder name after '#{'.",
                start: start,
                end: scanner.location
            )
            return nil
        }
        scanner.advance()
        var text = String(first)
        while let character = scanner.peek(), character.isRainbowIdentifierContinuation {
            text.append(character)
            scanner.advance()
        }

        guard scanner.peek() == "}" else {
            appendDiagnostic(
                code: "rainbow.lexer.unterminatedPlaceholder",
                message: "Unterminated placeholder; expected '}'.",
                start: start,
                end: scanner.location
            )
            return nil
        }
        scanner.advance()
        return text
    }

    private mutating func scanTaggedRawBody(
        tagStart: RainbowSourceLocation,
        language: EmbeddedLanguage
    ) -> (String, RainbowSourceLocation)? {
        var depth = 1
        var body = ""
        var inString: Character?
        var escape = false
        var inLineComment = false
        var inBlockComment = false
        var inCDATA = false
        var inMDFence = false

        let allowYAMLHashComments = language == .yaml
        let allowXMLMarkup = language == .xml || language == .html
        let allowSingleQuotes = language != .json
        let markdown = language == .markdown

        while !scanner.isAtEnd {
            guard let character = scanner.peek() else { break }

            if inString == nil,
               !inLineComment,
               !inBlockComment,
               !inCDATA,
               character == "#",
               scanner.peekNext() == "{"
            {
                appendDiagnostic(
                    code: "rainbow.lexer.embeddedPartialPlaceholder",
                    message: "Partial '#{...}' interpolation is not allowed inside @LANG(...); use '@LANG(#{Name})' for a whole-blob placeholder.",
                    start: scanner.location,
                    end: scanner.location
                )
                return nil
            }

            if markdown, inString == nil, !inMDFence, scanner.startsWith("```") {
                for _ in 0..<3 {
                    body.append(scanner.advance()!)
                }
                inMDFence = true
                continue
            }
            if markdown, inMDFence {
                if scanner.startsWith("```") {
                    for _ in 0..<3 {
                        body.append(scanner.advance()!)
                    }
                    inMDFence = false
                    continue
                }
                // Still honor Rainbow paren balance so `@MARKDOWN(```…)` can close.
                if character == "(" {
                    depth += 1
                    body.append(character)
                    scanner.advance()
                    continue
                }
                if character == ")" {
                    depth -= 1
                    if depth == 0 {
                        let bodyEnd = scanner.location
                        scanner.advance()
                        return (Self.dedentEmbeddedBody(body), bodyEnd)
                    }
                    body.append(character)
                    scanner.advance()
                    continue
                }
                body.append(character)
                scanner.advance()
                continue
            }

            if inLineComment {
                body.append(character)
                scanner.advance()
                if character == "\n" {
                    inLineComment = false
                }
                continue
            }

            if inBlockComment {
                body.append(character)
                scanner.advance()
                if character == "-",
                   scanner.peek() == "-",
                   scanner.peekNext() == ">"
                {
                    body.append(scanner.advance()!)
                    body.append(scanner.advance()!)
                    inBlockComment = false
                }
                continue
            }

            if inCDATA {
                body.append(character)
                scanner.advance()
                if character == "]",
                   scanner.peek() == "]",
                   scanner.peekNext() == ">"
                {
                    body.append(scanner.advance()!)
                    body.append(scanner.advance()!)
                    inCDATA = false
                }
                continue
            }

            if let quote = inString {
                body.append(character)
                scanner.advance()
                if escape {
                    escape = false
                    continue
                }
                if character == "\\", quote == "\"" {
                    escape = true
                    continue
                }
                if character == quote {
                    inString = nil
                }
                continue
            }

            if allowXMLMarkup,
               character == "<",
               scanner.peekNext() == "!",
               scanner.peekOffset(2) == "-",
               scanner.peekOffset(3) == "-"
            {
                for _ in 0..<4 {
                    body.append(scanner.advance()!)
                }
                inBlockComment = true
                continue
            }

            if allowXMLMarkup, scanner.startsWith("<![CDATA[") {
                for _ in 0..<"<![CDATA[".count {
                    body.append(scanner.advance()!)
                }
                inCDATA = true
                continue
            }

            if allowYAMLHashComments, character == "#" {
                inLineComment = true
                body.append(character)
                scanner.advance()
                continue
            }

            if character == "\"" || (allowSingleQuotes && character == "'") {
                inString = character
                body.append(character)
                scanner.advance()
                continue
            }

            if character == "(" {
                depth += 1
                body.append(character)
                scanner.advance()
                continue
            }

            if character == ")" {
                depth -= 1
                if depth == 0 {
                    let bodyEnd = scanner.location
                    scanner.advance()
                    return (Self.dedentEmbeddedBody(body), bodyEnd)
                }
                body.append(character)
                scanner.advance()
                continue
            }

            body.append(character)
            scanner.advance()
        }

        appendDiagnostic(
            code: "rainbow.lexer.unterminatedTagged",
            message: "Unterminated @LANG(...); expected closing ')'.",
            start: tagStart,
            end: scanner.location
        )
        return nil
    }

    private static func dedentEmbeddedBody(_ body: String) -> String {
        guard body.contains("\n") else { return body }

        let lines = body.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let indents = lines.dropFirst().compactMap { (line: String) -> Int? in
            guard !line.allSatisfy({ $0 == " " || $0 == "\t" }) else { return nil }
            return line.prefix(while: { $0 == " " || $0 == "\t" }).count
        }
        guard let indent = indents.min(), indent > 0 else { return body }

        var output = ""
        for (index, line) in lines.enumerated() {
            if index > 0 { output.append("\n") }
            if index == 0 || line.allSatisfy({ $0 == " " || $0 == "\t" }) {
                output.append(line)
            } else {
                output.append(String(line.dropFirst(indent)))
            }
        }
        if body.hasSuffix("\n") {
            output.append("\n")
        }
        return output
    }

    private mutating func appendUnexpectedCharacter(
        _ character: Character,
        start: RainbowSourceLocation
    ) {
        appendDiagnostic(
            code: "rainbow.lexer.unexpectedCharacter",
            message: "Unexpected character '\(character)'.",
            start: start,
            end: scanner.location
        )
    }

    private mutating func appendDiagnostic(
        code: String,
        message: String,
        start: RainbowSourceLocation,
        end: RainbowSourceLocation
    ) {
        diagnostics.append(
            RainbowDiagnostic(
                code: code,
                message: message,
                range: RainbowSourceRange(start: start, end: end)
            )
        )
    }
}

private extension Character {
    var isRainbowWhitespace: Bool {
        self == " " || self == "\n" || self == "\r" || self == "\r\n" || self == "\t"
    }

    var isRainbowDigit: Bool {
        guard let scalar = unicodeScalars.only else { return false }
        return scalar.value >= 48 && scalar.value <= 57
    }

    var isRainbowIdentifierStart: Bool {
        guard let scalar = unicodeScalars.only else { return false }
        return scalar.value == 95
            || (scalar.value >= 65 && scalar.value <= 90)
            || (scalar.value >= 97 && scalar.value <= 122)
    }

    var isRainbowIdentifierContinuation: Bool {
        isRainbowIdentifierStart || isRainbowDigit
    }
}

private extension Character.UnicodeScalarView {
    var only: Unicode.Scalar? {
        count == 1 ? first : nil
    }
}
