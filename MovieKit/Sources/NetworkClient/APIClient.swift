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
        case .popular:
            return "movie/popular"
        case .popularPersons:
            return "person/popular"
        case .topRated:
            return "movie/top_rated"
        case .upcoming:
            return "movie/upcoming"
        case .nowPlaying:
            return "movie/now_playing"
        case .trending:
            return "trending/movie/day"
        case let .movieDetail(movie):
            return "movie/\(String(movie))"
        case let .videos(movie):
            return "movie/\(String(movie))/videos"
        case let .personDetail(person):
            return "person/\(String(person))"
        case let .credits(movie):
            return "movie/\(String(movie))/credits"
        case let .review(movie):
            return "movie/\(String(movie))/reviews"
        case let .recommended(movie):
            return "movie/\(String(movie))/recommendations"
        case let .similar(movie):
            return "movie/\(String(movie))/similar"
        case let .personMovieCredits(person):
            return "person/\(person)/movie_credits"
        case let .personImages(person):
            return "person/\(person)/images"
        case .searchMovie:
            return "search/movie"
        case .searchKeyword:
            return "search/keyword"
        case .searchPerson:
            return "search/person"
        case .genres:
            return "genre/movie/list"
        case .discover:
            return "discover/movie"
        }
    }
}

public struct FetchNowPlayingMoviesClient {
    public var get: () async throws -> PaginatedResponse<Movie>
}

extension FetchNowPlayingMoviesClient: DependencyKey {
    public static var liveValue: FetchNowPlayingMoviesClient {
        return .init {
            let response: PaginatedResponse<Movie> = try await APIClient.get(Endpoint.nowPlaying, params: nil)
            return response
        }
    }
}

extension DependencyValues {
    public var fetchNowPlayingMoviesClient: FetchNowPlayingMoviesClient {
        get {
            self[FetchNowPlayingMoviesClient.self]
        }
        set {
            self[FetchNowPlayingMoviesClient.self] = newValue
        }
    }
}

private struct APIClient<T: Codable> {
    fileprivate static func get(_ endpoint: Endpoint, params: [String: String]?) async throws -> T {
        let queryURL = baseURL.appendingPathComponent(endpoint.path())
        var components = URLComponents(url: queryURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: Locale.preferredLanguages[0])
        ]

        if let params {
            for (_, value) in params.enumerated() {
                components.queryItems?.append(.init(name: value.key, value: value.value))
            }
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    throw APIError.invalidResponseCode
                }
            }

            let object = try JSONDecoder().decode(T.self, from: data)
            return object

        } catch let error as DecodingError {
            print(">>>", error)
            throw APIError.noResponse
        }
        catch let error {
            throw APIError.networkError(error: error)
        }
    }
}

