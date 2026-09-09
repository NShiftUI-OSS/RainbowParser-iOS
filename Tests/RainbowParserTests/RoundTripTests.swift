import Testing
@testable import RainbowParser

@Test func canonicalRoundTripPreservesStructure() throws {
    let source = #"Button( title:"Entrar", meta:(id:"login") ){OnTap{Navigate(to:"Home")}}"#
    let parser = RainbowParser()

    let firstDocument = try parser.decode(source)
    let encoded = parser.encode(firstDocument)
    let secondDocument = try parser.decode(encoded)

    #expect(secondDocument == firstDocument)
    #expect(encoded == """
    Button(
      title: "Entrar",
      meta: (id: "login")
    ) {
      OnTap {
        Navigate(to: "Home")
      }
    }
    """)
}

@Test func formatPreservesLeadingCommentsAndBlankSiblings() throws {
    let formatted = try RainbowParser().encode(
        RainbowParser().decode(
            """
            use Screen@1.0.0
            // root comment
            Screen {
              Text(text: "a")
              // between plugins
              Button(title: "b")
            }
            """
        )
    )

    #expect(formatted.contains("use Screen@1.0.0\n\n// root comment\nScreen {"))
    #expect(formatted.contains("Text(text: \"a\")\n\n  // between plugins\n  Button(title: \"b\")"))
}

@Test func parserCanBeUsedConcurrently() async throws {
    let parser = RainbowParser()
    let source = """
    Screen(name: "Home") {
      Button(title: "Entrar") {
        OnTap {
          Navigate(to: "Dashboard")
        }
      }
    }
    """
    let expected = try parser.decode(source)

    try await withThrowingTaskGroup(of: RainbowDocument.self) { group in
        for _ in 0..<64 {
            group.addTask {
                try parser.decode(source)
            }
        }

        for try await document in group {
            #expect(document == expected)
        }
    }
}

struct ExpectedErrorNotThrown: Error {}
