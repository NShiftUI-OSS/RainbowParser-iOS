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

        if !node.parameters.isEmpty {
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
                header += node.parameters
                    .map { printParameterInline($0, continuationIndent: indentation(level + 1)) }
                    .joined(separator: ", ")
                header += ")"
                parts.append(header)
            }
        } else {
            parts.append(header)
        }

        guard let block = node.block else {
            return parts.joined(separator: style.newline)
        }

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

        return parts.joined(separator: style.newline)
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
            return value
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
            let printedEntries = entries
                .map {
                    "\(printObjectKey($0.key)): \(printValue($0.value, continuationIndent: continuationIndent))"
                }
                .joined(separator: ", ")
            return "(" + printedEntries + ")"
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
}

private func shouldBreakParameters(_ node: RainbowNode) -> Bool {
    if isTriggerNodeName(node.name) {
        return false
    }
    if node.parameters.count >= 2 {
        return true
    }
    return node.parameters.contains { parameter in
        if case let .tagged(_, .text(text), _) = parameter.value {
            return text.contains("\n")
        }
        return false
    }
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
