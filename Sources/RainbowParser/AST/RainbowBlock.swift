public struct RainbowBlock: Equatable, Sendable {
    public let children: [RainbowNode]

    public init(children: [RainbowNode] = []) {
        self.children = children
    }
}
