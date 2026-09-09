import Testing
@testable import RainbowParser

@Test func printerEncodesUseDeclarations() {
    let document = RainbowDocument(
        uses: [
            RainbowUseDeclaration(name: "Screen", version: "1.0.0"),
            RainbowUseDeclaration(name: "Button", version: "2.0.0"),
        ],
        nodes: [
            RainbowNode(name: "Screen", parameters: [
                RainbowParameter(name: "name", value: .string("Home")),
            ]),
        ]
    )

    #expect(
        RainbowEncoder().encode(document) ==
            """
            use Screen@1.0.0
            use Button@2.0.0

            Screen(name: "Home")
            """
    )
}

@Test func printerEncodesCanonicalRainbow() {
    let document = RainbowDocument(nodes: [
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
                        RainbowNode(name: "OnTap", block: RainbowBlock()),
                    ]
                ),
            ]
        ),
    ])

    #expect(
        RainbowEncoder().encode(document) ==
            """
            Screen(name: "Home") {
              Button(
                title: "Entrar",
                variant: primary
              ) {
                OnTap {
                }
              }
            }
            """
    )
}

@Test func printerEncodesAllValueShapes() {
    let document = RainbowDocument(nodes: [
        RainbowNode(
            name: "Node",
            parameters: [
                RainbowParameter(name: "text", value: .string("quote: \" slash: \\ newline: \n")),
                RainbowParameter(name: "control", value: .string("tab: \t return: \r null: \0")),
                RainbowParameter(name: "int", value: .int(-2)),
                RainbowParameter(name: "double", value: .double(2.5)),
                RainbowParameter(name: "enabled", value: .bool(true)),
                RainbowParameter(name: "disabled", value: .bool(false)),
                RainbowParameter(name: "variant", value: .identifier("primary")),
                RainbowParameter(name: "items", value: .array([.string("a"), .int(1), .null])),
                RainbowParameter(
                    name: "meta",
                    value: .object([
                        RainbowObjectEntry(key: "id", value: .string("home")),
                        RainbowObjectEntry(key: "dash-key", value: .bool(false)),
                        RainbowObjectEntry(key: "", value: .int(0)),
                        RainbowObjectEntry(key: "1bad", value: .int(1)),
                        RainbowObjectEntry(key: "a-", value: .int(2)),
                        RainbowObjectEntry(key: "😀", value: .int(3)),
                        RainbowObjectEntry(key: "_id", value: .int(4)),
                        RainbowObjectEntry(key: "A1", value: .int(5)),
                        RainbowObjectEntry(key: "a😀", value: .int(6)),
                    ])
                ),
            ]
        ),
    ])

    #expect(
        RainbowEncoder().encode(document) ==
            """
            Node(
              text: "quote: \\" slash: \\\\ newline: \\n",
              control: "tab: \\t return: \\r null: \\0",
              int: -2,
              double: 2.5,
              enabled: true,
              disabled: false,
              variant: primary,
              items: ["a", 1, null],
              meta: (id: "home", "dash-key": false, "": 0, "1bad": 1, "a-": 2, "😀": 3, _id: 4, A1: 5, "a😀": 6)
            )
            """
    )
}

@Test func printerUsesCustomFormatStyle() {
    let document = RainbowDocument(nodes: [
        RainbowNode(name: "Root", children: [
            RainbowNode(name: "Child"),
        ]),
    ])
    let style = RainbowFormatStyle(indentation: "    ", newline: "\r\n")

    #expect(RainbowEncoder(style: style).encode(document) == "Root {\r\n    Child\r\n}")
}

@Test func parserFacadeEncodesAndDecodes() throws {
    let parser = RainbowParser()
    let source = #"Button(title: "Entrar") { OnTap {} }"#
    let document = try parser.decode(source)

    #expect(RainbowParserVersion.current == "0.1.0-beta.1")
    #expect(parser.encode(document) == """
    Button(title: "Entrar") {
      OnTap {
      }
    }
    """)
}

@Test func emptyDocumentEncodesToEmptyString() {
    #expect(RainbowEncoder().encode(RainbowDocument()) == "")
}
