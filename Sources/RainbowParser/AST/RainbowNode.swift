public struct RainbowNode: Equatable, Sendable {
    public let name: String
    public let parameters: [RainbowParameter]
    public let block: RainbowBlock?
    public let leading: RainbowLeadingTrivia

    public var children: [RainbowNode] {
        block?.children ?? []
    }

    public var hasBlock: Bool {
        block != nil
    }

    public init(
        name: String,
        parameters: [RainbowParameter] = [],
        block: RainbowBlock? = nil,
        leading: RainbowLeadingTrivia = RainbowLeadingTrivia()
    ) {
        self.name = name
        self.parameters = parameters
        self.block = block
        self.leading = leading
    }

    public init(
        name: String,
        parameters: [RainbowParameter] = [],
        children: [RainbowNode],
        leading: RainbowLeadingTrivia = RainbowLeadingTrivia()
    ) {
        self.name = name
        self.parameters = parameters
        self.block = RainbowBlock(children: children)
        self.leading = leading
    }
}
