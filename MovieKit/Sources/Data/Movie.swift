import Dependencies
import Foundation
import Tagged

public struct Movie: Codable, Equatable, Identifiable {
    public let id: Tagged<Self, UUID>
    let original_title: String
    let title: String
    public var userTitle: String {
        // TODO: Revisit
        //return AppUserDefaults.alwaysOriginalTitle ? original_title : title
        return title
    }

    public let overview: String
    let poster_path: String?
    let backdrop_path: String?
    public let popularity: Float
    let vote_average: Float
    let vote_count: Int

    let release_date: String?
    public var releaseDate: Date? {
        return release_date != nil ? Movie.dateFormatter.date(from: release_date!) : Date()
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyy-MM-dd"
        return formatter
    }()

    let genres: [Genre]?
    let runtime: Int?
    let status: String?
    let video: Bool

    var keywords: Keywords?
    var images: MovieImages?

    var production_countries: [ProductionCountry]?

    var character: String?
    var department: String?

    public struct Keywords: Codable, Equatable {
        let keywords: [Keyword]?
        public init(keywords: [Keyword]?) {
            self.keywords = keywords
        }
    }

    public struct MovieImages: Codable, Equatable {
        let posters: [ImageData]?
        let backdrops: [ImageData]?

        public init(posters: [ImageData]?, backdrops: [ImageData]?) {
            self.posters = posters
            self.backdrops = backdrops
        }
    }

    public struct ProductionCountry: Codable, Equatable, Identifiable {
        public var id: String { name }
        let name: String

        public init(name: String) {
            self.name = name
        }
    }

    public struct Builder {
        var id: Tagged<Movie, UUID> = .init()
        var original_title: String = ""
        var title: String = ""
        var overview: String = ""
        var poster_path: String? = nil
        var backdrop_path: String? = nil
        var popularity: Float = 0
        var vote_average: Float = 0
        var vote_count: Int = 0
        var release_date: String? = nil
        var genres: [Genre]? = nil
        var runtime: Int? = nil
        var status: String? = nil
        var video: Bool = false
        var keywords: Keywords? = nil
        var images: MovieImages? = nil
        var production_countries: [ProductionCountry]? = nil
        var character: String? = nil
        var department: String? = nil

        func build() -> Movie {
            .init(
                id: self.id,
                original_title: self.original_title,
                title: self.title,
                overview: self.overview,
                poster_path: self.poster_path,
                backdrop_path: self.backdrop_path,
                popularity: self.popularity,
                vote_average: self.vote_average,
                vote_count: self.vote_count,
                release_date: self.release_date,
                genres: self.genres,
                runtime: self.runtime,
                status: self.status,
                video: self.video
            )
        }
    }

    public static func build(_ set: (inout Builder) -> Void) -> Movie {
        var builder = Builder()
        set(&builder)
        return builder.build()
    }
}

extension Movie {
    public static let mock: Movie = .build {
        $0.id = .init(.init(0))
        $0.original_title = "Test movie Test movie Test movie Test movie Test movie Test movie Test movie "
        $0.title = "Test movie Test movie Test movie Test movie Test movie Test movie Test movie  Test movie Test movie Test movie"
        $0.overview = "Test desc"
        $0.poster_path = "/uC6TTUhPpQCmgldGyYveKRAu8JN.jpg"
        $0.backdrop_path = "/nl79FQ8xWZkhL3rDr1v2RFFR6J0.jpg"
        $0.popularity = 50.5
        $0.vote_average = 8.9
        $0.vote_count = 1000
        $0.release_date = "1972-03-14"
        $0.genres = [Genre(id: .init(.init(0)), name: "test")]
        $0.runtime = 80
        $0.status = "released"
        $0.video = false
    }
}
