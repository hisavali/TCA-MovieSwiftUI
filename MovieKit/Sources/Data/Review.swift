import Foundation

public struct Review: Codable, Equatable, Identifiable {
    public let id: String
    public let author: String
    public let content: String
}
