import Foundation

public struct CastResponse: Codable, Equatable {
    public let id: Int
    public let cast: [People]
    public let crew: [People]
}
