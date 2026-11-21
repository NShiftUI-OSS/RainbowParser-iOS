public struct RainbowTrigger: Equatable, Sendable {
    public let name: String
    public let events: [RainbowNode]
    public let leading: RainbowLeadingTrivia

    public init(
        name: String,
        events: [RainbowNode],
        leading: RainbowLeadingTrivia = RainbowLeadingTrivia()
    ) {
        self.name = name
        self.events = events
        self.leading = leading
    }
}

public struct RainbowSlot: Equatable, Sendable {
    public let name: String
    public let plugins: [RainbowNode]
    public let leading: RainbowLeadingTrivia

    public init(
        name: String,
        plugins: [RainbowNode],
        leading: RainbowLeadingTrivia = RainbowLeadingTrivia()
    ) {
        self.name = name
        self.plugins = plugins
        self.leading = leading
    }
}

public struct RainbowNode: Equatable, Sendable {
    public let name: String
    public let parameters: [RainbowParameter]
    public let block: RainbowBlock?
    public let leading: RainbowLeadingTrivia
    public let id: String?
    public let style: [RainbowParameter]
    public let events: [RainbowTrigger]
    public let slots: [RainbowSlot]

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
        leading: RainbowLeadingTrivia = RainbowLeadingTrivia(),
        id: String? = nil,
        style: [RainbowParameter] = [],
        events: [RainbowTrigger] = [],
        slots: [RainbowSlot] = []
    ) {
        self.name = name
        self.parameters = parameters
        self.block = block
        self.leading = leading
        self.id = id
        self.style = style
        self.events = events
        self.slots = slots
    }

    public init(
        name: String,
        parameters: [RainbowParameter] = [],
        children: [RainbowNode],
        leading: RainbowLeadingTrivia = RainbowLeadingTrivia(),
        id: String? = nil,
        style: [RainbowParameter] = [],
        events: [RainbowTrigger] = [],
        slots: [RainbowSlot] = []
    ) {
        self.name = name
        self.parameters = parameters
        self.block = RainbowBlock(children: children)
        self.leading = leading
        self.id = id
        self.style = style
        self.events = events
        self.slots = slots
    }
}
