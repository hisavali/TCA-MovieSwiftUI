import ComposableArchitecture
import Data
import Foundation
import NetworkClient
import SwiftUI

// MARK: - MenuType

public enum MenuType: String, CaseIterable, Identifiable, Sendable {
    case nowPlaying, upcoming, trending, popular, topRated

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .nowPlaying: return "Now Playing"
        case .upcoming: return "Upcoming"
        case .trending: return "Trending"
        case .popular: return "Popular"
        case .topRated: return "Top Rated"
        }
    }

    var endpoint: Endpoint {
        switch self {
        case .nowPlaying: return .nowPlaying
        case .upcoming: return .upcoming
        case .trending: return .trending
        case .popular: return .popular
        case .topRated: return .topRated
        }
    }
}

// MARK: - MoviesList Feature (list of movies for a menu category)

@Reducer
public struct MoviesList {
    @ObservableState
    public struct State: Equatable {
        public var menu: MenuType
        public var movies: [Movie] = []
        public var currentPage: Int = 1
        public var isLoading = false

        public init(menu: MenuType) {
            self.menu = menu
        }
    }

    public enum Action {
        case loadMoreMoviesAppeared
        case moviesResponse(Result<PaginatedResponse<Movie>, any Error>)
        case onTask
    }

    @Dependency(\.moviesClient) var moviesClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loadMoreMoviesAppeared:
                guard !state.isLoading else { return .none }
                state.currentPage += 1
                state.isLoading = true
                return .run { [page = state.currentPage, endpoint = state.menu.endpoint] send in
                    await send(.moviesResponse(Result {
                        try await moviesClient.fetchMenuList(endpoint, page, nil)
                    }))
                }

            case let .moviesResponse(.success(response)):
                state.isLoading = false
                state.movies.append(contentsOf: response.results)
                return .none

            case .moviesResponse(.failure):
                state.isLoading = false
                return .none

            case .onTask:
                state.isLoading = true
                return .run { [endpoint = state.menu.endpoint] send in
                    await send(.moviesResponse(Result {
                        try await moviesClient.fetchMenuList(endpoint, 1, nil)
                    }))
                }
            }
        }
    }

    public init() {}
}

// MARK: - MoviesHome Feature

@Reducer
public struct MoviesHome {
    @ObservableState
    public struct State: Equatable {
        public var selectedMenu: MenuType = .popular
        public var moviesList: MoviesList.State
        public var genres: [Genre] = []
        @Presents public var movieDetail: MovieDetail.State?

        public init() {
            self.moviesList = MoviesList.State(menu: .popular)
        }
    }

    public enum Action {
        case genresResponse(Result<GenresResponse, any Error>)
        case menuSelected(MenuType)
        case movieDetail(PresentationAction<MovieDetail.Action>)
        case moviesList(MoviesList.Action)
        case onTask
    }

    @Dependency(\.moviesClient) var moviesClient

    public var body: some ReducerOf<Self> {
        Scope(state: \.moviesList, action: \.moviesList) {
            MoviesList()
        }
        Reduce { state, action in
            switch action {
            case let .genresResponse(.success(response)):
                state.genres = response.genres
                return .none

            case .genresResponse(.failure):
                return .none

            case let .menuSelected(menu):
                state.selectedMenu = menu
                state.moviesList = MoviesList.State(menu: menu)
                return .send(.moviesList(.onTask))

            case .movieDetail:
                return .none

            case .moviesList:
                return .none

            case .onTask:
                return .merge(
                    .send(.moviesList(.onTask)),
                    .run { send in
                        await send(.genresResponse(Result {
                            try await moviesClient.fetchGenres()
                        }))
                    }
                )
            }
        }
        .ifLet(\.$movieDetail, action: \.movieDetail) {
            MovieDetail()
        }
    }

    public init() {}
}

// MARK: - MoviesListView

public struct MoviesListView: View {
    let store: StoreOf<MoviesList>

    public init(store: StoreOf<MoviesList>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if store.movies.isEmpty && store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.movies) { movie in
                        NavigationLink(value: movie.id) {
                            MovieRowView(movie: movie)
                        }
                    }
                    if !store.movies.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .onAppear {
                                store.send(.loadMoreMoviesAppeared)
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - MovieRowView (lightweight inline row, no store needed)

struct MovieRowView: View {
    let movie: Movie

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(movie.userTitle)
                    .titleStyle()
                    .foregroundColor(.steam_gold)
                    .lineLimit(2)
                HStack {
                    PopularityBadge(score: Int(movie.vote_average * 10))
                    if let releaseDate = movie.releaseDate {
                        Text(releaseDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
                Text(movie.overview)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .truncationMode(.tail)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - MoviesHomeView

public struct MoviesHomeView: View {
    @PerceptionCore.Bindable var store: StoreOf<MoviesHome>

    public init(store: StoreOf<MoviesHome>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                menuPicker
                MoviesListView(store: store.scope(state: \.moviesList, action: \.moviesList))
            }
            .navigationTitle(store.selectedMenu.title)
            .navigationDestination(for: Int.self) { movieId in
                MovieDetailView(
                    store: Store(initialState: MovieDetail.State(movieId: movieId)) {
                        MovieDetail()
                    }
                )
            }
        }
        .task {
            store.send(.onTask)
        }
    }

    private var menuPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MenuType.allCases) { menu in
                    Button {
                        store.send(.menuSelected(menu))
                    } label: {
                        Text(menu.title)
                            .font(.subheadline)
                            .fontWeight(store.selectedMenu == menu ? .bold : .regular)
                            .foregroundColor(store.selectedMenu == menu ? .steam_gold : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                store.selectedMenu == menu
                                    ? Color.steam_gold.opacity(0.15)
                                    : Color.clear
                            )
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

