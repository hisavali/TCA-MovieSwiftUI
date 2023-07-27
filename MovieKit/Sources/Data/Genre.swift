import Foundation
import Tagged

public struct Genre: Codable, Equatable, Identifiable {
    public let id: Tagged<Self, UUID>
    public let name: String

    public struct Builder {
        public var id: Tagged<Genre, UUID> = .init()
        public var name: String = ""

        func build() -> Genre {
            .init(id: self.id, name: self.name)
        }
    }

    public static func build(_ setProperty: (inout Builder) -> Void) -> Genre {
        var builder = Builder()
        setProperty(&builder)
        return builder.build()
    }
}
