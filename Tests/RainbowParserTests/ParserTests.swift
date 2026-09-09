import Testing
@testable import RainbowParser

@Test func parserDecodesUseDeclarationsAndNodes() throws {
    let document = try RainbowDecoder().decode(
        """
        use Screen@1.0.0
        use Button@2.1.0
        use ShowToast@1.3.0

        Screen(name: "Home") {
          Button(title: "Hi") {
            OnTap {
              ShowToast(message: "ok")
            }
          }
        }
        """
    )

    #expect(document.uses == [
        RainbowUseDeclaration(name: "Screen", version: "1.0.0"),
        RainbowUseDeclaration(name: "Button", version: "2.1.0"),
        RainbowUseDeclaration(name: "ShowToast", version: "1.3.0"),
    ])
    #expect(document.nodes.map(\.name) == ["Screen"])
}

@Test func parserDecodesNestedRainbowDocument() throws {
    let document = try RainbowDecoder().decode(
        """
        Screen(name: "Home") {
          Button(title: "Entrar", variant: primary) {
            OnTap {
              Navigate(to: "Dashboard")
            }
          }
        }
        """
    )

    #expect(document.uses.isEmpty)
    #expect(document.nodes == [
        RainbowNode(
            name: "Screen",
            parameters: [
                RainbowParameter(name: "name", value: .string("Home")),
            ],
            children: [
                RainbowNode(
                    name: "Button",
                    parameters: [
                        RainbowParameter(name: "title", value: .string("Entrar")),
                        RainbowParameter(name: "variant", value: .identifier("primary")),
                    ],
                    children: [
                        RainbowNode(
                            name: "OnTap",
                            children: [
                                RainbowNode(
                                    name: "Navigate",
                                    parameters: [
                                        RainbowParameter(name: "to", value: .string("Dashboard")),
                                    ]
                                ),
                            ]
                        ),
                    ]
                ),
            ]
        ),
    ])
}

@Test func parserDecodesAllSupportedValueShapes() throws {
    let document = try RainbowDecoder().decode(
        """
        Node(
          text: "value",
          int: -1,
          double: 1.25,
          enabled: true,
          disabled: false,
          variant: primary,
          items: ["a", 1, null],
          meta: (id: "home", "dash-key": false),
          emptyArray: [],
          emptyObject: ()
        )
        """
    )

    #expect(document.nodes.first?.parameters == [
        RainbowParameter(name: "text", value: .string("value")),
        RainbowParameter(name: "int", value: .int(-1)),
        RainbowParameter(name: "double", value: .double(1.25)),
        RainbowParameter(name: "enabled", value: .bool(true)),
        RainbowParameter(name: "disabled", value: .bool(false)),
        RainbowParameter(name: "variant", value: .identifier("primary")),
        RainbowParameter(name: "items", value: .array([.string("a"), .int(1), .null])),
        RainbowParameter(
            name: "meta",
            value: .object([
                RainbowObjectEntry(key: "id", value: .string("home")),
                RainbowObjectEntry(key: "dash-key", value: .bool(false)),
            ])
        ),
        RainbowParameter(name: "emptyArray", value: .array([])),
        RainbowParameter(name: "emptyObject", value: .object([])),
    ])
}

@Test func parserPreservesEmptyArgumentsAndBlocks() throws {
    let document = try RainbowDecoder().decode(
        """
        Root() {
          EmptyBlock {}
          Leaf
        }
        """
    )

    let root = try #require(document.nodes.first)
    #expect(root.parameters == [])
    #expect(root.hasBlock == true)
    #expect(root.children[0].name == "EmptyBlock")
    #expect(root.children[0].hasBlock == true)
    #expect(root.children[1].name == "Leaf")
    #expect(root.children[1].hasBlock == false)
}

@Test func parserAllowsTrailingCommasInArrays() throws {
    let document = try RainbowDecoder().decode(
        """
        Node(
          values: [one, two,],
          object: (first: 1, second: 2)
        )
        """
    )

    #expect(document.nodes.first?.parameters == [
        RainbowParameter(name: "values", value: .array([.identifier("one"), .identifier("two")])),
        RainbowParameter(
            name: "object",
            value: .object([
                RainbowObjectEntry(key: "first", value: .int(1)),
                RainbowObjectEntry(key: "second", value: .int(2)),
            ])
        ),
    ])
}

@Test func parserRejectsTrailingCommaAfterLastObjectEntry() throws {
    let error = try expectDecodeError(#"Node(object: (first: 1, second: 2,))"#)

    #expect(error.diagnostics.first?.code == "rainbow.parser.unexpectedToken")
    #expect(
        error.diagnostics.first?.message
            == "Trailing comma is not allowed after the last object entry."
    )
}

@Test func parserRejectsTrailingCommaAfterLastParameter() throws {
    let error = try expectDecodeError(#"Button(title: "Entrar",)"#)

    #expect(error.diagnostics.first?.code == "rainbow.parser.unexpectedToken")
    #expect(
        error.diagnostics.first?.message
            == "Trailing comma is not allowed after the last parameter."
    )
}

@Test func parserReportsMissingParameterName() throws {
    let error = try expectDecodeError("Button(: \"Entrar\")")

    #expect(error.diagnostics.first?.message == "Expected parameter name.")
}

@Test func parserReportsMissingColon() throws {
    let error = try expectDecodeError("Button(title \"Entrar\")")

    #expect(error.diagnostics.first?.message == "Expected ':' after parameter name.")
}

@Test func parserReportsMissingValue() throws {
    let error = try expectDecodeError("Button(title: )")

    #expect(error.diagnostics.first?.message == "Expected value.")
}

@Test func parserReportsMissingClosingParen() throws {
    let error = try expectDecodeError("Button(title: \"Entrar\"")

    #expect(error.diagnostics.first?.message == "Expected ')' after parameter list.")
}

@Test func parserReportsMissingClosingBlockBrace() throws {
    let error = try expectDecodeError("Screen { Button")

    #expect(error.diagnostics.first?.message == "Expected '}' after block.")
}

@Test func parserReportsMissingClosingArrayBracket() throws {
    let error = try expectDecodeError("Node(values: [one, two)")

    #expect(error.diagnostics.first?.message == "Expected ']' after array.")
}

@Test func parserReportsMissingObjectKeyAndClosingParen() throws {
    let error = try expectDecodeError("Node(meta: ( : true)")
    let messages = error.diagnostics.map(\.message)

    #expect(messages.contains("Expected object key."))
    #expect(
        messages.contains("Expected ')' after object.")
            || messages.contains("Expected ')' after parameter list.")
    )
}

@Test func parserReportsUnexpectedTokenAtDocumentRoot() throws {
    let error = try expectDecodeError("}")

    #expect(error.diagnostics.first?.message == "Expected node name.")
}

@Test func parserRecoversFromUnexpectedRootTokenBeforeNextNode() throws {
    let error = try expectDecodeError(") Screen")

    #expect(error.diagnostics.first?.message == "Expected node name.")
}

@Test func parserRecoversFromUnexpectedTokenInsideBlock() throws {
    let error = try expectDecodeError("Root { ) ( Child }")

    #expect(error.diagnostics.first?.message == "Expected node name.")
}

@Test func parserReportsInvalidArrayValueAndSynchronizesAtComma() throws {
    let error = try expectDecodeError("Node(values: [one, , two])")

    #expect(error.diagnostics.first?.message == "Expected value.")
}

@Test func parserReportsMissingObjectValueAndSynchronizesAtComma() throws {
    let error = try expectDecodeError("Node(meta: (id: , next: true))")

    #expect(error.diagnostics.first?.message == "Expected value.")
}

@Test func parserParameterSynchronizationCanReachEndOfFile() throws {
    let error = try expectDecodeError("Node(:")

    #expect(error.diagnostics.map(\.message).contains("Expected parameter name."))
    #expect(error.diagnostics.map(\.message).contains("Expected ')' after parameter list."))
}

@Test func parserDecodesTaggedEmbeddedValues() throws {
    let document = try RainbowDecoder().decode(
        """
        Screen(
          json: @JSON({"key": "value"}),
          blob: @JSON(#{payload}),
          md: @MARKDOWN(# Title)
        )
        """
    )

    #expect(document.nodes[0].parameters.count == 3)
    guard case let .tagged(jsonLang, jsonBody, _) = document.nodes[0].parameters[0].value else {
        Issue.record("expected json tagged")
        return
    }
    #expect(jsonLang == .json)
    #expect(jsonBody == .text(#"{"key": "value"}"#))

    guard case let .tagged(_, blob, _) = document.nodes[0].parameters[1].value else {
        Issue.record("expected blob tagged")
        return
    }
    #expect(blob == .placeholder("payload"))

    let encoded = RainbowEncoder().encode(document)
    #expect(encoded.contains("@JSON({\"key\": \"value\"})"))
    #expect(encoded.contains("@JSON(#{payload})"))
    #expect(encoded.contains("@MARKDOWN("))
}

private func expectDecodeError(_ source: String) throws -> RainbowParseError {
    do {
        _ = try RainbowDecoder().decode(source)
    } catch {
        return error
    }

    throw ExpectedErrorNotThrown()
}
