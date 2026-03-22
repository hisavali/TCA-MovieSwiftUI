import Dependencies
import Foundation
import Data

let baseURL = URL(string: "https://api.themoviedb.org/3")!
let apiKey = "1d9b898a212ea52e283351e521e17871"

public enum APIError: Error {
    case invalidResponseCode
    case noResponse
    case jsonDecodingError(error: Error)
    case networkError(error: Error)
}

public enum Endpoint {
    case popular, topRated, upcoming, nowPlaying, trending
    case movieDetail(movie: Int), recommended(movie: Int), similar(movie: Int), videos(movie: Int)
    case credits(movie: Int), review(movie: Int)
    case searchMovie, searchKeyword, searchPerson
    case popularPersons
    case personDetail(person: Int)
    case personMovieCredits(person: Int)
    case personImages(person: Int)
    case genres
    case discover

    func path() -> String {
        switch self {
        case .popular: return "movie/popular"
        case .popularPersons: return "person/popular"
        case .topRated: return "movie/top_rated"
        case .upcoming: return "movie/upcoming"
        case .nowPlaying: return "movie/now_playing"
        case .trending: return "trending/movie/day"
        case let .movieDetail(movie): return "movie/\(movie)"
        case let .videos(movie): return "movie/\(movie)/videos"
        case let .personDetail(person): return "person/\(person)"
        case let .credits(movie): return "movie/\(movie)/credits"
        case let .review(movie): return "movie/\(movie)/reviews"
        case let .recommended(movie): return "movie/\(movie)/recommendations"
        case let .similar(movie): return "movie/\(movie)/similar"
        case let .personMovieCredits(person): return "person/\(person)/movie_credits"
        case let .personImages(person): return "person/\(person)/images"
        case .searchMovie: return "search/movie"
        case .searchKeyword: return "search/keyword"
        case .searchPerson: return "search/person"
        case .genres: return "genre/movie/list"
        case .discover: return "discover/movie"
        }
    }
}

// MARK: - Raw API transport

struct APITransport {
    static func get<T: Codable>(_ endpoint: Endpoint, params: [String: String]?) async throws -> T {
        let queryURL = baseURL.appendingPathComponent(endpoint.path())
        var components = URLComponents(url: queryURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: Locale.preferredLanguages[0]),
        ]
        if let params {
            for (key, value) in params {
                components.queryItems?.append(.init(name: key, value: value))
            }
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw APIError.invalidResponseCode
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.jsonDecodingError(error: error)
        }
    }
}

// MARK: - Movies Client

public struct MoviesClient: Sendable {
    public var fetchMenuList: @Sendable (_ endpoint: Endpoint, _ page: Int, _ region: String?) async throws -> PaginatedResponse<Movie>
    public var fetchDetail: @Sendable (_ movieId: Int) async throws -> Movie
    public var fetchRecommended: @Sendable (_ movieId: Int) async throws -> PaginatedResponse<Movie>
    public var fetchSimilar: @Sendable (_ movieId: Int) async throws -> PaginatedResponse<Movie>
    public var fetchReviews: @Sendable (_ movieId: Int) async throws -> PaginatedResponse<Review>
    public var fetchVideos: @Sendable (_ movieId: Int) async throws -> PaginatedResponse<Video>
    public var fetchSearch: @Sendable (_ query: String, _ page: Int) async throws -> PaginatedResponse<Movie>
    public var fetchSearchKeyword: @Sendable (_ query: String) async throws -> PaginatedResponse<Keyword>
    public var fetchGenres: @Sendable () async throws -> GenresResponse
    public var fetchDiscover: @Sendable (_ params: [String: String]) async throws -> PaginatedResponse<Movie>
    public var fetchMoviesByGenre: @Sendable (_ genreId: Int, _ page: Int, _ sortBy: String) async throws -> PaginatedResponse<Movie>
    public var fetchMoviesByKeyword: @Sendable (_ keywordId: Int, _ page: Int) async throws -> PaginatedResponse<Movie>
    public var fetchMoviesByCrew: @Sendable (_ crewId: Int) async throws -> PaginatedResponse<Movie>
}

extension MoviesClient: DependencyKey {
    public static var liveValue: MoviesClient {
        .init(
            fetchMenuList: { endpoint, page, region in
                var params = ["page": "\(page)"]
                if let region { params["region"] = region }
                return try await APITransport.get(endpoint, params: params)
            },
            fetchDetail: { movieId in
                try await APITransport.get(
                    .movieDetail(movie: movieId),
                    params: [
                        "append_to_response": "keywords,images",
                        "include_image_language": "\(Locale.current.language.languageCode?.identifier ?? "en"),en,null",
                    ]
                )
            },
            fetchRecommended: { movieId in
                try await APITransport.get(.recommended(movie: movieId), params: nil)
            },
            fetchSimilar: { movieId in
                try await APITransport.get(.similar(movie: movieId), params: nil)
            },
            fetchReviews: { movieId in
                try await APITransport.get(.review(movie: movieId), params: ["language": "en-US"])
            },
            fetchVideos: { movieId in
                try await APITransport.get(.videos(movie: movieId), params: nil)
            },
            fetchSearch: { query, page in
                try await APITransport.get(.searchMovie, params: ["query": query, "page": "\(page)"])
            },
            fetchSearchKeyword: { query in
                try await APITransport.get(.searchKeyword, params: ["query": query])
            },
            fetchGenres: {
                try await APITransport.get(.genres, params: nil)
            },
            fetchDiscover: { params in
                try await APITransport.get(.discover, params: params)
            },
            fetchMoviesByGenre: { genreId, page, sortBy in
                try await APITransport.get(
                    .discover,
                    params: ["with_genres": "\(genreId)", "page": "\(page)", "sort_by": sortBy]
                )
            },
            fetchMoviesByKeyword: { keywordId, page in
                try await APITransport.get(
                    .discover,
                    params: ["page": "\(page)", "with_keywords": "\(keywordId)"]
                )
            },
            fetchMoviesByCrew: { crewId in
                try await APITransport.get(.discover, params: ["with_people": "\(crewId)"])
            }
        )
    }
}

extension DependencyValues {
    public var moviesClient: MoviesClient {
        get { self[MoviesClient.self] }
        set { self[MoviesClient.self] = newValue }
    }
}

// MARK: - People Client

public struct PeopleCreditsResponse: Codable, Equatable, Sendable {
    public let cast: [Movie]?
    public let crew: [Movie]?
}

public struct PeopleImagesResponse: Codable, Equatable, Sendable {
    public let id: Int
    public let profiles: [ImageData]
}

public struct PeopleClient: Sendable {
    public var fetchDetail: @Sendable (_ personId: Int) async throws -> People
    public var fetchImages: @Sendable (_ personId: Int) async throws -> PeopleImagesResponse
    public var fetchCredits: @Sendable (_ personId: Int) async throws -> PeopleCreditsResponse
    public var fetchMovieCasts: @Sendable (_ movieId: Int) async throws -> CastResponse
    public var fetchSearch: @Sendable (_ query: String, _ page: Int) async throws -> PaginatedResponse<People>
    public var fetchPopular: @Sendable (_ page: Int, _ region: String?) async throws -> PaginatedResponse<People>
}

extension PeopleClient: DependencyKey {
    public static var liveValue: PeopleClient {
        .init(
            fetchDetail: { personId in
                try await APITransport.get(.personDetail(person: personId), params: nil)
            },
            fetchImages: { personId in
                try await APITransport.get(.personImages(person: personId), params: nil)
            },
            fetchCredits: { personId in
                try await APITransport.get(.personMovieCredits(person: personId), params: nil)
            },
            fetchMovieCasts: { movieId in
                try await APITransport.get(.credits(movie: movieId), params: nil)
            },
            fetchSearch: { query, page in
                try await APITransport.get(.searchPerson, params: ["query": query, "page": "\(page)"])
            },
            fetchPopular: { page, region in
                var params = ["page": "\(page)"]
                if let region { params["region"] = region }
                return try await APITransport.get(.popularPersons, params: params)
            }
        )
    }
}

extension DependencyValues {
    public var peopleClient: PeopleClient {
        get { self[PeopleClient.self] }
        set { self[PeopleClient.self] = newValue }
    }
}

