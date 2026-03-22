import Foundation

public struct People: Codable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public var character: String?
    public var department: String?
    public let profile_path: String?

    public let known_for_department: String?
    public var known_for: [KnownFor]?
    public let also_known_as: [String]?

    public let birthDay: String?
    public let deathDay: String?
    public let place_of_birth: String?

    public let biography: String?
    public let popularity: Double?

    public var images: [ImageData]?

    public struct KnownFor: Codable, Equatable, Identifiable, Sendable {
        public let id: Int
        public let original_title: String?
        public let poster_path: String?
    }

    public var knownForText: String? {
        guard let knownFor = known_for else { return nil }
        let names = knownFor.compactMap(\.original_title)
        return names.joined(separator: ", ")
    }
}
