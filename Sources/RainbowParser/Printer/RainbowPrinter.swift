struct RainbowPrinter: Sendable {
    private let style: RainbowFormatStyle

    init(style: RainbowFormatStyle = .default) {
        self.style = style
    }

    func print(_ document: RainbowDocument) -> String {
        var sections: [String] = []

        if !document.uses.isEmpty {
            let uses = document.uses.map(printUse).joined(separator: style.newline)
            sections.append(uses)
        }

        for node in document.nodes {
            sections.append(printNode(node, level: 0))
        }

        return sections.joined(separator: style.newline + style.newline)
    }

    private func printUse(_ declaration: RainbowUseDeclaration) -> String {
        var parts: [String] = []
        pushLeading(&parts, declaration.leading, level: 0)
        parts.append("use \(declaration.name)@\(declaration.version)")
        return parts.joined(separator: style.newline)
    }

    private func printNode(_ node: RainbowNode, level: Int) -> String {
        let indent = indentation(level)
        var parts: [String] = []
        pushLeading(&parts, node.leading, level: level)

        var header = indent + node.name
        let emitConstructor = !isTriggerNodeName(node.name)

        if !node.parameters.isEmpty || emitConstructor {
            if shouldBreakParameters(node) {
                header += "("
                parts.append(header)
                let inner = indentation(level + 1)
                for (index, parameter) in node.parameters.enumerated() {
                    var parameterLines = printParameterLines(parameter, indent: inner)
                    if index != node.parameters.count - 1, var last = parameterLines.popLast() {
                        last += ","
                        parameterLines.append(last)
                    }
                    parts.append(contentsOf: parameterLines)
                }
                parts.append(indent + ")")
            } else {
                header += "("
                if !node.parameters.isEmpty {
                    header += node.parameters
                        .map { printParameterInline($0, continuationIndent: indentation(level + 1)) }
                        .joined(separator: ", ")
                }
                header += ")"
                parts.append(header)
            }
        } else {
            parts.append(header)
        }

        if let block = node.block {
            if var last = parts.popLast() {
                last += " {"
                parts.append(last)
            }

            if block.children.isEmpty {
                parts.append(indent + "}")
            } else {
                let children = block.children
                    .map { printNode($0, level: level + 1) }
                    .joined(separator: style.newline + style.newline)
                parts.append(children)
                parts.append(indent + "}")
            }
        }

        pushModifiers(&parts, node, level: level)
        return parts.joined(separator: style.newline)
    }

    private func pushModifiers(_ parts: inout [String], _ node: RainbowNode, level: Int) {
        let indent = indentation(level)
        if let id = node.id {
            parts.append("\(indent).id(\"\(escape(id))\")")
        }
        if !node.style.isEmpty {
            parts.append(printStyleModifier(node.style, level: level))
        }
        if !node.events.isEmpty {
            parts.append("\(indent).events {")
            let triggerIndent = indentation(level + 1)
            for trigger in node.events {
                pushLeading(&parts, trigger.leading, level: level + 1)
                parts.append("\(triggerIndent)\(trigger.name) {")
                for event in trigger.events {
                    parts.append(printNode(event, level: level + 2))
                }
                parts.append("\(triggerIndent)}")
            }
            parts.append("\(indent)}")
        }
        if !node.slots.isEmpty {
            parts.append("\(indent).slots {")
            let slotIndent = indentation(level + 1)
            for slot in node.slots {
                pushLeading(&parts, slot.leading, level: level + 1)
                parts.append("\(slotIndent)\(slot.name) {")
                for plugin in slot.plugins {
                    parts.append(printNode(plugin, level: level + 2))
                }
                parts.append("\(slotIndent)}")
            }
            parts.append("\(indent)}")
        }
    }

    private func printStyleModifier(_ parameters: [RainbowParameter], level: Int) -> String {
        let indent = indentation(level)
        let complex = parameters.count >= 2 || parameters.contains { valueNeedsBreak($0.value) }
        if !complex {
            let inline = parameters
                .map { printParameterInline($0, continuationIndent: indentation(level + 1)) }
                .joined(separator: ", ")
            return "\(indent).style(\(inline))"
        }
        var lines = ["\(indent).style("]
        let inner = indentation(level + 1)
        for (index, parameter) in parameters.enumerated() {
            var entry = printParameterLines(parameter, indent: inner)
            if index != parameters.count - 1, var last = entry.popLast() {
                last += ","
                entry.append(last)
            }
            lines.append(contentsOf: entry)
        }
        lines.append("\(indent))")
        return lines.joined(separator: style.newline)
    }

    private func printParameterLines(_ parameter: RainbowParameter, indent: String) -> [String] {
        var lines: [String] = []
        pushLeadingRaw(&lines, parameter.leading, indent: indent)
        let value = printValue(parameter.value, continuationIndent: indent)
        let valueLines = value.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        if valueLines.count <= 1 {
            lines.append("\(indent)\(parameter.name): \(value)")
        } else {
            lines.append("\(indent)\(parameter.name): \(valueLines[0])")
            lines.append(contentsOf: valueLines.dropFirst())
        }
        return lines
    }

    private func printParameterInline(
        _ parameter: RainbowParameter,
        continuationIndent: String
    ) -> String {
        "\(parameter.name): \(printValue(parameter.value, continuationIndent: continuationIndent))"
    }

    private func pushLeading(_ parts: inout [String], _ trivia: RainbowLeadingTrivia, level: Int) {
        pushLeadingRaw(&parts, trivia, indent: indentation(level))
    }

    private func pushLeadingRaw(
        _ parts: inout [String],
        _ trivia: RainbowLeadingTrivia,
        indent: String
    ) {
        for comment in trivia.comments {
            parts.append("\(indent)//\(comment)")
        }
    }

    private func printValue(_ value: RainbowValue, continuationIndent: String) -> String {
        switch value {
        case let .string(value):
            return "\"\(escape(value))\""
        case let .int(value):
            return String(value)
        case let .double(value):
            return String(value)
        case let .bool(value):
            return value ? "true" : "false"
        case let .identifier(value):
            return ".\(value)"
        case let .tagged(language, body, _):
            switch body {
            case let .text(text):
                return printTaggedText(language.asString, text, continuationIndent: continuationIndent)
            case let .placeholder(name):
                return "@\(language.asString)(#{\(name)})"
            }
        case let .array(values):
            return "["
                + values.map { printValue($0, continuationIndent: continuationIndent) }
                .joined(separator: ", ") + "]"
        case let .object(entries):
            return printObject(entries, continuationIndent: continuationIndent)
        case let .plugins(plugins):
            return printPluginList(plugins, continuationIndent: continuationIndent)
        case .null:
            return "null"
        }
    }

    private func printTaggedText(
        _ language: String,
        _ text: String,
        continuationIndent: String
    ) -> String {
        let text = text.hasSuffix("\n") ? String(text.dropLast()) : text
        guard text.contains("\n") else {
            return "@\(language)(\(text))"
        }

        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let first = lines.isEmpty ? "" : lines.removeFirst()
        var output = "@\(language)(\(first)"
        for line in lines {
            output += style.newline + continuationIndent + line
        }
        output += ")"
        return output
    }

    private func printObject(
        _ entries: [RainbowObjectEntry],
        continuationIndent: String
    ) -> String {
        if !objectNeedsBreak(entries) {
            let printedEntries = entries
                .map {
                    "\(printObjectKey($0.key)): \(printValue($0.value, continuationIndent: continuationIndent))"
                }
                .joined(separator: ", ")
            return "(\(printedEntries))"
        }

        let inner = continuationIndent + style.indentation
        var lines = ["("]
        for (index, entry) in entries.enumerated() {
            var entryLines = printObjectEntryLines(entry, indent: inner)
            if index != entries.count - 1, var last = entryLines.popLast() {
                last += ","
                entryLines.append(last)
            }
            lines.append(contentsOf: entryLines)
        }
        lines.append(continuationIndent + ")")
        return lines.joined(separator: style.newline)
    }

    private func printObjectEntryLines(_ entry: RainbowObjectEntry, indent: String) -> [String] {
        let value = printValue(entry.value, continuationIndent: indent)
        let valueLines = value.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let key = printObjectKey(entry.key)
        if valueLines.count <= 1 {
            return ["\(indent)\(key): \(value)"]
        }
        var lines = ["\(indent)\(key): \(valueLines[0])"]
        lines.append(contentsOf: valueLines.dropFirst())
        return lines
    }

    private func printObjectKey(_ key: String) -> String {
        key.isRainbowPrintableIdentifier ? key : "\"\(escape(key))\""
    }

    private func indentation(_ level: Int) -> String {
        String(repeating: style.indentation, count: level)
    }

    private func escape(_ value: String) -> String {
        var output = ""

        for character in value {
            switch character {
            case "\"":
                output += "\\\""
            case "\\":
                output += "\\\\"
            case "\n":
                output += "\\n"
            case "\r":
                output += "\\r"
            case "\t":
                output += "\\t"
            case "\0":
                output += "\\0"
            default:
                output.append(character)
            }
        }

        return output
    }

    private func printPluginList(_ plugins: [RainbowNode], continuationIndent: String) -> String {
        if plugins.isEmpty {
            return "{}"
        }
        let unit = style.indentation.isEmpty ? 1 : style.indentation.count
        let level = continuationIndent.count / unit + 1
        var lines = ["{"]
        lines.append(contentsOf: plugins.map { printNode($0, level: level) })
        lines.append(continuationIndent + "}")
        return lines.joined(separator: style.newline)
    }
}

private func shouldBreakParameters(_ node: RainbowNode) -> Bool {
    guard !node.parameters.isEmpty else { return false }
    let complex = node.parameters.contains { valueNeedsBreak($0.value) }
    if isTriggerNodeName(node.name) {
        return complex
    }
    return node.parameters.count >= 2 || complex
}

private func valueNeedsBreak(_ value: RainbowValue) -> Bool {
    switch value {
    case let .tagged(_, .text(text), _):
        return text.contains("\n")
    case let .object(entries):
        return objectNeedsBreak(entries)
    case let .array(values):
        return values.contains { valueNeedsBreak($0) }
    case .plugins:
        return true
    default:
        return false
    }
}

private func objectNeedsBreak(_ entries: [RainbowObjectEntry]) -> Bool {
    entries.count >= 2 || entries.contains { valueNeedsBreak($0.value) }
}

private func isTriggerNodeName(_ name: String) -> Bool {
    guard name.count >= 3, name.hasPrefix("On") else { return false }
    let third = name[name.index(name.startIndex, offsetBy: 2)]
    return third.isASCII && third.isUppercase
        && name.dropFirst(3).allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber) }
}

private extension String {
    var isRainbowPrintableIdentifier: Bool {
        guard let first else { return false }

        guard first.isRainbowPrintableIdentifierStart else {
            return false
        }

        return dropFirst().allSatisfy(\.isRainbowPrintableIdentifierContinuation)
    }
}

private extension Character {
    var isRainbowPrintableIdentifierStart: Bool {
        guard let scalar = unicodeScalars.only else { return false }
        return scalar.value == 95
            || (scalar.value >= 65 && scalar.value <= 90)
            || (scalar.value >= 97 && scalar.value <= 122)
    }

    var isRainbowPrintableIdentifierContinuation: Bool {
        isRainbowPrintableIdentifierStart || isRainbowDigit
    }

    var isRainbowDigit: Bool {
        guard let scalar = unicodeScalars.only else { return false }
        return scalar.value >= 48 && scalar.value <= 57
    }
}

private extension Character.UnicodeScalarView {
    var only: Unicode.Scalar? {
        count == 1 ? first : nil
    }
}
