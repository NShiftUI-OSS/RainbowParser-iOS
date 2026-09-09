struct RainbowSyntaxParser {
    private let tokens: [RainbowToken]
    private var current: Int
    private var diagnostics: [RainbowDiagnostic]

    init(tokens: [RainbowToken]) {
        self.tokens = tokens
        self.current = 0
        self.diagnostics = []
    }

    mutating func parse() throws(RainbowParseError) -> RainbowDocument {
        var uses: [RainbowUseDeclaration] = []
        var nodes: [RainbowNode] = []

        while !isAtEnd {
            let leading = takeLeadingTrivia()
            if case .identifier("use") = peek.kind {
                if var use = parseUseDeclaration() {
                    use = RainbowUseDeclaration(
                        name: use.name,
                        version: use.version,
                        leading: leading
                    )
                    uses.append(use)
                } else {
                    synchronizeNode()
                }
            } else if var node = parseNode() {
                node = RainbowNode(
                    name: node.name,
                    parameters: node.parameters,
                    block: node.block,
                    leading: leading
                )
                nodes.append(node)
            } else {
                synchronizeNode()
            }
        }

        if diagnostics.isEmpty {
            return RainbowDocument(uses: uses, nodes: nodes)
        }

        throw RainbowParseError(diagnostics: diagnostics)
    }

    private mutating func takeLeadingTrivia() -> RainbowLeadingTrivia {
        var comments: [String] = []
        while case let .comment(text) = peek.kind {
            comments.append(text)
            advance()
        }
        return RainbowLeadingTrivia(comments: comments)
    }

    private mutating func parseUseDeclaration() -> RainbowUseDeclaration? {
        guard case .identifier("use") = peek.kind else {
            return nil
        }
        advance()

        guard case let .identifier(name) = peek.kind else {
            appendUnexpectedToken(message: "Expected plugin or event name after 'use'.")
            return nil
        }
        advance()

        guard match(.at) else {
            appendUnexpectedToken(message: "Expected '@' before version in use declaration.")
            return nil
        }

        guard case let .version(version) = peek.kind else {
            appendUnexpectedToken(message: "Expected SemVer MAJOR.MINOR.PATCH after '@'.")
            return nil
        }
        advance()

        return RainbowUseDeclaration(name: name, version: version)
    }

    private mutating func parseNode() -> RainbowNode? {
        guard case let .identifier(name) = peek.kind else {
            appendUnexpectedToken(message: "Expected node name.")
            advance()
            return nil
        }

        advance()

        let parameters: [RainbowParameter]
        if match(.leftParen) {
            parameters = parseArguments()
        } else {
            parameters = []
        }

        let block: RainbowBlock?
        if match(.leftBrace) {
            block = parseBlock()
        } else {
            block = nil
        }

        return RainbowNode(name: name, parameters: parameters, block: block)
    }

    private mutating func parseArguments() -> [RainbowParameter] {
        var parameters: [RainbowParameter] = []

        if significantIsRightParen {
            _ = takeLeadingTrivia()
            advance()
            return parameters
        }

        while true {
            if significantIsRightParen || isAtEnd {
                break
            }

            if let parameter = parseParameter() {
                parameters.append(parameter)
            } else {
                synchronizeParameter()
            }

            guard match(.comma) else {
                break
            }

            if significantIsRightParen {
                diagnostics.append(
                    RainbowDiagnostic(
                        code: "rainbow.parser.unexpectedToken",
                        message: "Trailing comma is not allowed after the last parameter.",
                        range: previous.range
                    )
                )
                break
            }
        }

        _ = takeLeadingTrivia()
        consume(.rightParen, message: "Expected ')' after parameter list.")
        return parameters
    }

    private mutating func parseParameter() -> RainbowParameter? {
        let leading = takeLeadingTrivia()
        guard case let .identifier(name) = peek.kind else {
            appendUnexpectedToken(message: "Expected parameter name.")
            return nil
        }

        advance()
        consume(.colon, message: "Expected ':' after parameter name.")

        guard let value = parseValue() else {
            synchronizeParameter()
            return nil
        }

        return RainbowParameter(name: name, value: value, leading: leading)
    }

    private mutating func parseBlock() -> RainbowBlock {
        var children: [RainbowNode] = []

        while !significantIsRightBrace && !isAtEnd {
            let leading = takeLeadingTrivia()
            if var child = parseNode() {
                child = RainbowNode(
                    name: child.name,
                    parameters: child.parameters,
                    block: child.block,
                    leading: leading
                )
                children.append(child)
            } else {
                synchronizeNode()
            }
        }

        _ = takeLeadingTrivia()
        consume(.rightBrace, message: "Expected '}' after block.")
        return RainbowBlock(children: children)
    }

    private mutating func parseValue() -> RainbowValue? {
        switch peek.kind {
        case let .string(value):
            advance()
            return .string(value)
        case let .int(value):
            advance()
            return .int(value)
        case let .double(value):
            advance()
            return .double(value)
        case let .bool(value):
            advance()
            return .bool(value)
        case .null:
            advance()
            return .null
        case let .identifier(value):
            advance()
            return .identifier(value)
        case let .tagged(language, body, bodyRange):
            advance()
            return .tagged(language: language, body: body, bodyRange: bodyRange)
        case .leftBracket:
            advance()
            return parseArray()
        case .leftParen:
            advance()
            return parseObject()
        default:
            appendUnexpectedToken(message: "Expected value.")
            return nil
        }
    }

    private mutating func parseArray() -> RainbowValue {
        var values: [RainbowValue] = []

        if match(.rightBracket) {
            return .array(values)
        }

        repeat {
            if check(.rightBracket) || check(.eof) {
                break
            }

            if let value = parseValue() {
                values.append(value)
            } else {
                synchronizeValue()
            }
        } while match(.comma)

        consume(.rightBracket, message: "Expected ']' after array.")
        return .array(values)
    }

    private mutating func parseObject() -> RainbowValue {
        var entries: [RainbowObjectEntry] = []

        if match(.rightParen) {
            return .object(entries)
        }

        while true {
            if check(.rightParen) || check(.eof) {
                break
            }

            guard let key = parseObjectKey() else {
                synchronizeValue()
                if !match(.comma) {
                    break
                }
                continue
            }

            consume(.colon, message: "Expected ':' after object key.")

            guard let value = parseValue() else {
                synchronizeValue()
                if !match(.comma) {
                    break
                }
                continue
            }

            entries.append(RainbowObjectEntry(key: key, value: value))

            guard match(.comma) else {
                break
            }

            if check(.rightParen) {
                diagnostics.append(
                    RainbowDiagnostic(
                        code: "rainbow.parser.unexpectedToken",
                        message: "Trailing comma is not allowed after the last object entry.",
                        range: previous.range
                    )
                )
                break
            }
        }

        consume(.rightParen, message: "Expected ')' after object.")
        return .object(entries)
    }

    private mutating func parseObjectKey() -> String? {
        switch peek.kind {
        case let .identifier(key), let .string(key):
            advance()
            return key
        default:
            appendUnexpectedToken(message: "Expected object key.")
            return nil
        }
    }

    @discardableResult
    private mutating func consume(_ kind: RainbowTokenKind, message: String) -> RainbowToken? {
        if check(kind) {
            return advance()
        }

        appendUnexpectedToken(message: message)
        return nil
    }

    @discardableResult
    private mutating func match(_ kind: RainbowTokenKind) -> Bool {
        guard check(kind) else { return false }
        advance()
        return true
    }

    private func check(_ kind: RainbowTokenKind) -> Bool {
        peek.kind == kind
    }

    private var significantIsRightParen: Bool {
        significantKindMatches { $0 == .rightParen }
    }

    private var significantIsRightBrace: Bool {
        significantKindMatches { $0 == .rightBrace }
    }

    private func significantKindMatches(_ predicate: (RainbowTokenKind) -> Bool) -> Bool {
        var index = current
        while index < tokens.count {
            switch tokens[index].kind {
            case .comment:
                index += 1
            default:
                return predicate(tokens[index].kind)
            }
        }
        return false
    }

    @discardableResult
    private mutating func advance() -> RainbowToken {
        if !isAtEnd {
            current += 1
        }
        return previous
    }

    private var isAtEnd: Bool {
        peek.kind == .eof
    }

    private var peek: RainbowToken {
        tokens[current]
    }

    private var previous: RainbowToken {
        tokens[current - 1]
    }

    private mutating func synchronizeNode() {
        while !isAtEnd {
            if check(.rightBrace) || isNodeStart(peek) {
                return
            }

            advance()
        }
    }

    private mutating func synchronizeParameter() {
        while !isAtEnd {
            if check(.comma) || check(.rightParen) {
                return
            }

            advance()
        }
    }

    private mutating func synchronizeValue() {
        while !isAtEnd {
            if check(.comma) || check(.rightBracket) || check(.rightBrace) || check(.rightParen) {
                return
            }

            advance()
        }
    }

    private func isNodeStart(_ token: RainbowToken) -> Bool {
        if case .identifier = token.kind {
            return true
        }

        return false
    }

    private mutating func appendUnexpectedToken(message: String) {
        diagnostics.append(
            RainbowDiagnostic(
                code: "rainbow.parser.unexpectedToken",
                message: message,
                range: peek.range
            )
        )
    }
}
