public struct RainbowDocument: Equatable, Sendable {
    public let uses: [RainbowUseDeclaration]
    public let nodes: [RainbowNode]

    public init(
        uses: [RainbowUseDeclaration] = [],
        nodes: [RainbowNode] = []
    ) {
        self.uses = uses
        self.nodes = nodes
    }
}
