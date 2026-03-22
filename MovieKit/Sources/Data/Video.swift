import Foundation

public struct Video: Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let site: String
    public let key: String
    public let type: String
}
