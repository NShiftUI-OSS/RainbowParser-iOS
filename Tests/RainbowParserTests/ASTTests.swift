import Testing
@testable import RainbowParser

@Test func nodeInitializersExposeChildrenAndBlockState() {
    let leaf = RainbowNode(name: "Spacer")
    #expect(leaf.children == [])
    #expect(leaf.hasBlock == false)

    let emptyBlock = RainbowNode(name: "OnTap", block: RainbowBlock())
    #expect(emptyBlock.children == [])
    #expect(emptyBlock.hasBlock == true)

    let child = RainbowNode(name: "Text", parameters: [
        RainbowParameter(name: "value", value: .string("Hello"))
    ])
    let parent = RainbowNode(name: "Button", children: [child])
    #expect(parent.children == [child])
    #expect(parent.hasBlock == true)
}

@Test func documentDefaultsToNoRootNodes() {
    #expect(RainbowDocument().nodes == [])
}

@Test func parseErrorDescriptionIncludesAllDiagnostics() {
    let start = RainbowSourceLocation(offset: 0, line: 1, column: 1)
    let end = RainbowSourceLocation(offset: 1, line: 1, column: 2)
    let range = RainbowSourceRange(start: start, end: end)
    let diagnostic = RainbowDiagnostic(
        code: "test.code",
        message: "Example failure.",
        severity: .warning,
        range: range
    )
    let error = RainbowParseError(diagnostic)

    #expect(start < end)
    #expect(diagnostic.description == "WARNING test.code at 1:1: Example failure.")
    #expect(error.description == diagnostic.description)
}
