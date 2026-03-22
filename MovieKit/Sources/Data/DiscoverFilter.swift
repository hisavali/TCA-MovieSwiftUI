import Foundation

public struct DiscoverFilter: Codable, Equatable, Sendable {
    public let year: Int
    public let startYear: Int?
    public let endYear: Int?
    public let sort: String
    public let genre: Int?
    public let region: String?

    public init(
        year: Int,
        startYear: Int? = nil,
        endYear: Int? = nil,
        sort: String,
        genre: Int? = nil,
        region: String? = nil
    ) {
        self.year = year
        self.startYear = startYear
        self.endYear = endYear
        self.sort = sort
        self.genre = genre
        self.region = region
    }

    public static func randomFilter() -> DiscoverFilter {
        DiscoverFilter(
            year: randomYear(),
            sort: randomSort()
        )
    }

    public static func randomYear() -> Int {
        let calendar = Calendar.current
        return Int.random(in: 1950..<calendar.component(.year, from: Date()))
    }

    public static func randomSort() -> String {
        let sortBy = [
            "popularity.desc",
            "popularity.asc",
            "vote_average.asc",
            "vote_average.desc",
        ]
        return sortBy[Int.random(in: 0..<sortBy.count)]
    }

    public static func randomPage() -> Int {
        Int.random(in: 1..<20)
    }

    public func toParams() -> [String: String] {
        var params: [String: String] = [:]
        if let startYear, let endYear {
            params["primary_release_date.gte"] = "\(startYear)"
            params["primary_release_date.lte"] = "\(endYear)"
        } else {
            params["year"] = "\(year)"
        }
        if let genre {
            params["with_genres"] = "\(genre)"
        }
        if let region {
            params["region"] = region
        }
        params["page"] = "\(DiscoverFilter.randomPage())"
        params["sort_by"] = sort
        params["language"] = "en-US"
        return params
    }

    public func toText(genres: [Genre]) -> String {
        var text = ""
        if let startYear, let endYear {
            text += "\(startYear)-\(endYear)"
        } else {
            text += " · Random"
        }
        if let genre,
           let stateGenre = genres.first(where: { $0.id == genre })
        {
            text += " · \(stateGenre.name)"
        }
        if let region {
            text += " · \(region)"
        }
        return text
    }
}
