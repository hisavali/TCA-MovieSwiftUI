import Foundation
import Tagged

public struct Keyword: Codable, Equatable, Identifiable {
    public let id: Tagged<Self, UUID>
    public let name: String

    public struct Builder {
        public var id: Tagged<Keyword, UUID> = .init()
        public var name: String = ""

        func build() -> Keyword {
            Keyword(id: self.id, name: self.name)
        }
    }

    public static func build(_ set: (inout Builder) -> Void) -> Keyword {
        var builder = Builder()
        set(&builder)
        return builder.build()
    }
}
