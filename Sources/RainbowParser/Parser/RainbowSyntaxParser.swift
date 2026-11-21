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
                    leading: leading,
                    id: node.id,
                    style: node.style,
                    events: node.events,
                    slots: node.slots
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

        let hadParentheses = match(.leftParen)
        let parameters: [RainbowParameter]
        if hadParentheses {
            parameters = parseArguments()
        } else {
            parameters = []
        }

        var anchor = previous.range.end.line
        let block: RainbowBlock?
        if check(.leftBrace) {
            if peek.range.start.line != anchor {
                diagnostics.append(
                    RainbowDiagnostic(
                        code: "rainbow.parser.childrenBrace",
                        message: hadParentheses
                            ? "The children block must open on the same line as ')'."
                            : "The children block must open on the same line as the name.",
                        range: peek.range
                    )
                )
            }
            advance()
            block = parseBlock()
            anchor = previous.range.end.line
        } else {
            block = nil
        }

        let modifiers = parseModifiers(anchor: anchor)
        return RainbowNode(
            name: name,
            parameters: parameters,
            block: block,
            id: modifiers.id,
            style: modifiers.style,
            events: modifiers.events,
            slots: modifiers.slots
        )
    }

    private struct ParsedModifiers {
        var id: String?
        var style: [RainbowParameter] = []
        var events: [RainbowTrigger] = []
        var slots: [RainbowSlot] = []
    }

    private mutating func parseModifiers(anchor initialAnchor: Int) -> ParsedModifiers {
        var anchor = initialAnchor
        var parsed = ParsedModifiers()
        var seen: [String] = []

        while true {
            if case .comment = peek.kind {
                if commentIntroducesModifier() {
                    diagnostics.append(
                        RainbowDiagnostic(
                            code: "rainbow.parser.modifierSpacing",
                            message: "A comment cannot sit between a plugin and its view modifier.",
                            range: peek.range
                        )
                    )
                    advance()
                    continue
                }
                break
            }

            guard case let .dotIdentifier(modifier) = peek.kind else {
                break
            }
            let known = modifier == "id" || modifier == "style" || modifier == "events" || modifier == "slots"
            let line = peek.range.start.line
            if !known {
                if line <= anchor + 1 {
                    diagnostics.append(
                        RainbowDiagnostic(
                            code: "rainbow.parser.unknownModifier",
                            message: "Unknown view modifier '.\(modifier)'.",
                            range: peek.range
                        )
                    )
                    advance()
                    continue
                }
                break
            }

            if line == anchor {
                diagnostics.append(
                    RainbowDiagnostic(
                        code: "rainbow.parser.modifierSpacing",
                        message: "'.\(modifier)' must start on the line below the plugin.",
                        range: peek.range
                    )
                )
            } else if line > anchor + 1 {
                diagnostics.append(
                    RainbowDiagnostic(
                        code: "rainbow.parser.modifierSpacing",
                        message: "'.\(modifier)' must be on the next line, with no blank line above it.",
                        range: peek.range
                    )
                )
            }
            if seen.contains(modifier) {
                diagnostics.append(
                    RainbowDiagnostic(
                        code: "rainbow.parser.duplicateModifier",
                        message: "'.\(modifier)' can be written only once on a plugin.",
                        range: peek.range
                    )
                )
            }
            seen.append(modifier)
            advance()

            switch modifier {
            case "id":
                parsed.id = parseIdModifier()
            case "style":
                parsed.style = parseStyleModifier()
            case "events":
                parsed.events = parseEventsModifier()
            case "slots":
                parsed.slots = parseSlotsModifier()
            default:
                break
            }
            anchor = previous.range.end.line
        }

        return parsed
    }

    private mutating func parseIdModifier() -> String? {
        consume(.leftParen, message: "Expected '(' after '.id'.")
        let id: String?
        if case let .string(value) = peek.kind {
            id = value
            advance()
        } else {
            appendUnexpectedToken(message: "Expected a string inside '.id(\"...\")'.")
            id = nil
        }
        consume(.rightParen, message: "Expected ')' after '.id'.")
        return id
    }

    private mutating func parseStyleModifier() -> [RainbowParameter] {
        guard match(.leftParen) else {
            appendUnexpectedToken(message: "Expected '(' after '.style'.")
            return []
        }
        return parseArguments()
    }

    private mutating func parseEventsModifier() -> [RainbowTrigger] {
        guard braceOnSameLine("'.events'") else {
            return []
        }
        advance()
        var triggers: [RainbowTrigger] = []
        while !significantIsRightBrace && !isAtEnd {
            let leading = takeLeadingTrivia()
            if var trigger = parseTrigger() {
                trigger = RainbowTrigger(name: trigger.name, events: trigger.events, leading: leading)
                triggers.append(trigger)
            } else {
                synchronizeNode()
            }
        }
        _ = takeLeadingTrivia()
        consume(.rightBrace, message: "Expected '}' after '.events'.")
        return triggers
    }

    private mutating func parseTrigger() -> RainbowTrigger? {
        guard case let .identifier(name) = peek.kind else {
            appendUnexpectedToken(message: "Expected a trigger name inside '.events'.")
            return nil
        }
        advance()
        if check(.leftParen) {
            advance()
            _ = parseArguments()
        }
        guard braceOnSameLine("a trigger") else {
            return nil
        }
        advance()
        let events = parseEventCalls()
        return RainbowTrigger(name: name, events: events)
    }

    private mutating func parseEventCalls() -> [RainbowNode] {
        var events: [RainbowNode] = []
        while !significantIsRightBrace && !isAtEnd {
            let leading = takeLeadingTrivia()
            if let event = parseNode() {
                if event.block != nil || !event.style.isEmpty || !event.events.isEmpty || !event.slots.isEmpty {
                    diagnostics.append(
                        RainbowDiagnostic(
                            code: "rainbow.parser.eventShape",
                            message: "An event only accepts metadata in parentheses and an optional '.id'.",
                            range: previous.range
                        )
                    )
                }
                events.append(
                    RainbowNode(
                        name: event.name,
                        parameters: event.parameters,
                        block: event.block,
                        leading: leading,
                        id: event.id,
                        style: event.style,
                        events: event.events,
                        slots: event.slots
                    )
                )
            } else {
                synchronizeNode()
            }
        }
        _ = takeLeadingTrivia()
        consume(.rightBrace, message: "Expected '}' after trigger.")
        return events
    }

    private mutating func parseSlotsModifier() -> [RainbowSlot] {
        guard braceOnSameLine("'.slots'") else {
            return []
        }
        advance()
        var slots: [RainbowSlot] = []
        while !significantIsRightBrace && !isAtEnd {
            let leading = takeLeadingTrivia()
            if let slot = parseSlot() {
                slots.append(RainbowSlot(name: slot.name, plugins: slot.plugins, leading: leading))
            } else {
                synchronizeNode()
            }
        }
        _ = takeLeadingTrivia()
        consume(.rightBrace, message: "Expected '}' after '.slots'.")
        return slots
    }

    private mutating func parseSlot() -> RainbowSlot? {
        guard case let .identifier(name) = peek.kind else {
            appendUnexpectedToken(message: "Expected a slot name inside '.slots'.")
            return nil
        }
        advance()
        guard braceOnSameLine("a slot") else {
            return nil
        }
        advance()
        return RainbowSlot(name: name, plugins: parsePluginList())
    }

    private mutating func parsePluginList() -> [RainbowNode] {
        var plugins: [RainbowNode] = []
        while !significantIsRightBrace && !isAtEnd {
            let leading = takeLeadingTrivia()
            if let plugin = parseNode() {
                plugins.append(
                    RainbowNode(
                        name: plugin.name,
                        parameters: plugin.parameters,
                        block: plugin.block,
                        leading: leading,
                        id: plugin.id,
                        style: plugin.style,
                        events: plugin.events,
                        slots: plugin.slots
                    )
                )
            } else {
                synchronizeNode()
            }
        }
        _ = takeLeadingTrivia()
        consume(.rightBrace, message: "Expected '}' after plugins.")
        return plugins
    }

    private mutating func braceOnSameLine(_ what: String) -> Bool {
        guard check(.leftBrace) else {
            appendUnexpectedToken(message: "Expected '{' on the same line as \(what).")
            return false
        }
        if peek.range.start.line != previous.range.end.line {
            diagnostics.append(
                RainbowDiagnostic(
                    code: "rainbow.parser.braceLine",
                    message: "The '{' of \(what) must stay on the same line as its name.",
                    range: peek.range
                )
            )
        }
        return true
    }

    private func commentIntroducesModifier() -> Bool {
        var index = current
        while index < tokens.count {
            switch tokens[index].kind {
            case .comment:
                index += 1
            case let .dotIdentifier(name) where name == "id" || name == "style" || name == "events" || name == "slots":
                return true
            default:
                return false
            }
        }
        return false
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
                    leading: leading,
                    id: child.id,
                    style: child.style,
                    events: child.events,
                    slots: child.slots
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
        case let .dotIdentifier(value):
            advance()
            return .identifier(value)
        case let .identifier(value):
            appendUnexpectedToken(
                message: "Enum identifier values must start with '.'; did you mean '.\(value)'?"
            )
            advance()
            return nil
        case let .tagged(language, body, bodyRange):
            advance()
            return .tagged(language: language, body: body, bodyRange: bodyRange)
        case .leftBracket:
            advance()
            return parseArray()
        case .leftParen:
            advance()
            return parseObject()
        case .leftBrace:
            advance()
            return .plugins(parsePluginList())
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
