import Foundation

enum MenuType: String, CaseIterable {
    case nowPlaying
    case upcoming
    case trending
    case popular
    case topRated
    case genres

    var title: String {
        switch self {
        case .nowPlaying: return "Now Playing"
        case .upcoming: return "Upcoming"
        case .trending: return "Trending"
        case .popular: return "Popular"
        case .topRated: return "Top Rated"
        case .genres: return "Genres"
        }
    }
}

//    func endpoint() -> APIService.Endpoint {
//        switch self {
//        case .popular: return APIService.Endpoint.popular
//        case .topRated: return APIService.Endpoint.topRated
//        case .upcoming: return APIService.Endpoint.upcoming
//        case .nowPlaying: return APIService.Endpoint.nowPlaying
//        case .trending: return APIService.Endpoint.trending
//        case .genres: return APIService.Endpoint.genres
//        }
//    }

