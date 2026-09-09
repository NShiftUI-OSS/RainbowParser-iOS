public struct RainbowObjectEntry: Equatable, Sendable {
    public let key: String
    public let value: RainbowValue

    public init(key: String, value: RainbowValue) {
        self.key = key
        self.value = value
    }
}
