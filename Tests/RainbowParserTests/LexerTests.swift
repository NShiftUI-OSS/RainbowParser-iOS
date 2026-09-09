import Testing
@testable import RainbowParser

@Test func lexerScansPunctuationAndEof() throws {
    let tokens = try scan("(){}[]:,@")

    #expect(tokens.map(\.kind) == [
        .leftParen,
        .rightParen,
        .leftBrace,
        .rightBrace,
        .leftBracket,
        .rightBracket,
        .colon,
        .comma,
        .at,
        .eof,
    ])
}

@Test func lexerScansSemVerAsVersionToken() throws {
    let tokens = try scan("1.0.0 1.25")

    #expect(tokens.map(\.kind) == [
        .version("1.0.0"),
        .double(1.25),
        .eof,
    ])
}

@Test func lexerScansWhitespaceOnlyInputAsEof() throws {
    let tokens = try scan(" \r\n\t")

    #expect(tokens.map(\.kind) == [.eof])
    #expect(tokens[0].range.start.line == 2)
    #expect(tokens[0].range.start.column == 2)
}

@Test func lexerScansLiteralsAndKeywords() throws {
    let tokens = try scan(#"Button title "hello\nworld" -12 3.5 true false null primary"#)

    #expect(tokens.map(\.kind) == [
        .identifier("Button"),
        .identifier("title"),
        .string("hello\nworld"),
        .int(-12),
        .double(3.5),
        .bool(true),
        .bool(false),
        .null,
        .identifier("primary"),
        .eof,
    ])
}

@Test func lexerScansSupportedStringEscapes() throws {
    let tokens = try scan(#""quote: \" slash: \\ tab: \t return: \r null: \0""#)

    #expect(tokens.map(\.kind) == [
        .string("quote: \" slash: \\ tab: \t return: \r null: \0"),
        .eof,
    ])
}

@Test func lexerTracksLineAndColumn() throws {
    let tokens = try scan("Screen\n  Button")

    #expect(tokens[0].range.start.line == 1)
    #expect(tokens[0].range.start.column == 1)
    #expect(tokens[1].range.start.line == 2)
    #expect(tokens[1].range.start.column == 3)
}

@Test func lexerReportsUnexpectedCharactersAndInvalidNumbers() throws {
    let error = try expectLexerError("# -")

    #expect(error.diagnostics.map(\.code) == [
        "rainbow.lexer.unexpectedCharacter",
        "rainbow.lexer.unexpectedCharacter",
    ])
    #expect(error.diagnostics[0].message == "Unexpected character '#'.")
    #expect(error.diagnostics[1].message == "Unexpected character '-'.")
}

@Test func lexerReportsIntegerOverflow() throws {
    let error = try expectLexerError("999999999999999999999999999999999999")

    #expect(error.diagnostics.map(\.code) == [
        "rainbow.lexer.invalidNumber",
    ])
    #expect(error.diagnostics[0].message == "Invalid number literal '999999999999999999999999999999999999'.")
}

@Test func lexerReportsUnterminatedStringAtEndOfFile() throws {
    let error = try expectLexerError(#""missing"#)

    #expect(error.diagnostics.map(\.code) == [
        "rainbow.lexer.unterminatedString",
    ])
    #expect(error.diagnostics[0].range.start.line == 1)
    #expect(error.diagnostics[0].range.start.column == 1)
}

@Test func lexerReportsUnterminatedStringAfterTrailingEscape() throws {
    let error = try expectLexerError(#""missing \"#)

    #expect(error.diagnostics.map(\.code) == [
        "rainbow.lexer.unterminatedString",
    ])
}

@Test func lexerReportsUnterminatedStringAtLineBreak() throws {
    let error = try expectLexerError("\"missing\nNext")

    #expect(error.diagnostics.map(\.code) == [
        "rainbow.lexer.unterminatedString",
    ])
}

@Test func lexerReportsInvalidEscape() throws {
    let error = try expectLexerError(#""bad \x escape""#)

    #expect(error.diagnostics.map(\.code) == [
        "rainbow.lexer.invalidEscape",
    ])
    #expect(error.diagnostics[0].message == #"Invalid escape sequence \x."#)
}

@Test func lexerReportsNonAsciiComposedCharacters() throws {
    let error = try expectLexerError("🇧🇷")

    #expect(error.diagnostics.map(\.code) == [
        "rainbow.lexer.unexpectedCharacter",
    ])
}

@Test func characterScannerSupportsPeekingAndAdvancing() {
    var scanner = CharacterScanner(source: SourceText("A\nB"))

    #expect(scanner.peek() == "A")
    #expect(scanner.peekNext() == "\n")
    #expect(scanner.advance() == "A")
    #expect(scanner.location.line == 1)
    #expect(scanner.location.column == 2)
    #expect(scanner.advance() == "\n")
    #expect(scanner.location.line == 2)
    #expect(scanner.location.column == 1)
    #expect(scanner.advance() == "B")
    #expect(scanner.peek() == nil)
    #expect(scanner.peekNext() == nil)
    #expect(scanner.advance() == nil)

    let singleCharacterScanner = CharacterScanner(source: SourceText("Z"))
    #expect(singleCharacterScanner.peekNext() == nil)
}

@Test func lexerScansTaggedJsonAndPlaceholderBlob() throws {
    let tokens = try scan(#"@JSON({"a":1}) @JSON(#{blob})"#)
    guard case let .tagged(language, body, _) = tokens[0].kind else {
        Issue.record("expected tagged token")
        return
    }
    #expect(language == .json)
    #expect(body == .text(#"{"a":1}"#))

    guard case let .tagged(_, blob, _) = tokens[1].kind else {
        Issue.record("expected tagged placeholder")
        return
    }
    #expect(blob == .placeholder("blob"))
}

@Test func lexerRejectsPartialPlaceholderInsideTagged() throws {
    let error = try expectLexerError(#"@JSON({"a": #{x}})"#)
    #expect(error.diagnostics[0].code == "rainbow.lexer.embeddedPartialPlaceholder")
}

@Test func lexerKeepsAtForUsePins() throws {
    let tokens = try scan("use Screen@1.0.0")
    #expect(tokens.contains { $0.kind == .at })
    #expect(!tokens.contains {
        if case .tagged = $0.kind { return true }
        return false
    })
}

private func scan(_ source: String) throws(RainbowParseError) -> [RainbowToken] {
    var lexer = RainbowLexer(source: source)
    return try lexer.scanTokens()
}

private func expectLexerError(_ source: String) throws -> RainbowParseError {
    do {
        _ = try scan(source)
    } catch {
        return error
    }

    throw ExpectedErrorNotThrown()
}
