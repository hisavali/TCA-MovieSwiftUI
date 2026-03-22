import ComposableArchitecture
import Common
import Data
import Foundation
import NetworkClient
import SwiftUI

// MARK: - Discover Feature

@Reducer
public struct Discover {
    @ObservableState
    public struct State: Equatable {
        public var movies: [Movie] = []
        public var currentFilter: DiscoverFilter?
        public var genres: [Genre] = []
        public var isLoading = false
        @Presents public var movieDetail: MovieDetail.State?

        var currentMovie: Movie? {
            movies.last
        }

        public init() {}
    }

    public enum Action {
        case addToSeenListButtonTapped
        case addToWishlistButtonTapped
        case discoverResponse(Result<PaginatedResponse<Movie>, any Error>)
        case genresResponse(Result<GenresResponse, any Error>)
        case movieDetail(PresentationAction<MovieDetail.Action>)
        case movieTapped(Movie)
        case onTask
        case refreshButtonTapped
        case skipButtonTapped
        case undoButtonTapped(Movie)
    }

    @Dependency(\.moviesClient) var moviesClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .addToSeenListButtonTapped:
                if !state.movies.isEmpty {
                    state.movies.removeLast()
                }
                return fetchIfNeeded(state: &state)

            case .addToWishlistButtonTapped:
                if !state.movies.isEmpty {
                    state.movies.removeLast()
                }
                return fetchIfNeeded(state: &state)

            case let .discoverResponse(.success(response)):
                state.isLoading = false
                state.movies.insert(contentsOf: response.results, at: 0)
                return .none

            case .discoverResponse(.failure):
                state.isLoading = false
                return .none

            case let .genresResponse(.success(response)):
                state.genres = response.genres
                return .none

            case .genresResponse(.failure):
                return .none

            case .movieDetail:
                return .none

            case let .movieTapped(movie):
                state.movieDetail = MovieDetail.State(movieId: movie.id, movie: movie)
                return .none

            case .onTask:
                let filter = DiscoverFilter.randomFilter()
                state.currentFilter = filter
                return .merge(
                    fetchDiscover(filter: filter, state: &state),
                    .run { send in
                        await send(.genresResponse(Result {
                            try await moviesClient.fetchGenres()
                        }))
                    }
                )

            case .refreshButtonTapped:
                state.movies = []
                let filter = DiscoverFilter.randomFilter()
                state.currentFilter = filter
                return fetchDiscover(filter: filter, state: &state)

            case .skipButtonTapped:
                if !state.movies.isEmpty {
                    state.movies.removeLast()
                }
                return fetchIfNeeded(state: &state)

            case let .undoButtonTapped(movie):
                state.movies.append(movie)
                return .none
            }
        }
        .ifLet(\.$movieDetail, action: \.movieDetail) {
            MovieDetail()
        }
    }

    private func fetchIfNeeded(state: inout State) -> Effect<Action> {
        guard state.movies.count < 10 else { return .none }
        return fetchDiscover(filter: state.currentFilter, state: &state)
    }

    private func fetchDiscover(filter: DiscoverFilter?, state: inout State) -> Effect<Action> {
        let filter = filter ?? DiscoverFilter.randomFilter()
        state.isLoading = true
        return .run { send in
            await send(.discoverResponse(Result {
                try await moviesClient.fetchDiscover(filter.toParams())
            }))
        }
    }

    public init() {}
}

// MARK: - DiscoverView

public struct DiscoverView: View {
    @PerceptionCore.Bindable var store: StoreOf<Discover>
    @State private var offset: CGSize = .zero

    public init(store: StoreOf<Discover>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.steam_black.ignoresSafeArea()

                VStack {
                    filterLabel

                    ZStack {
                        ForEach(Array(store.movies.suffix(3).enumerated()), id: \.element.id) { index, movie in
                            let isTop = movie.id == store.currentMovie?.id
                            movieCard(movie: movie, isTop: isTop)
                                .zIndex(isTop ? 1 : 0)
                                .scaleEffect(isTop ? 1 : 0.95)
                        }
                    }
                    .frame(height: 400)

                    if let movie = store.currentMovie {
                        Text(movie.userTitle)
                            .foregroundColor(.white)
                            .font(.FjallaOne(size: 18))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Discover")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sheet(item: $store.scope(state: \.movieDetail, action: \.movieDetail)) { detailStore in
                NavigationStack {
                    MovieDetailView(store: detailStore)
                }
            }
        }
        .task {
            store.send(.onTask)
        }
    }

    private var filterLabel: some View {
        Group {
            if let filter = store.currentFilter {
                Text(filter.toText(genres: store.genres))
                    .font(.caption)
                    .foregroundColor(.steam_gold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.steam_gold.opacity(0.15))
                    .cornerRadius(16)
            }
        }
    }

    private func movieCard(movie: Movie, isTop: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 250, height: 375)
            .overlay(
                VStack {
                    Text(movie.userTitle)
                        .font(.headline)
                        .foregroundColor(.steam_gold)
                        .multilineTextAlignment(.center)
                        .padding()
                    if let overview = movie.overview.isEmpty ? nil : movie.overview {
                        Text(overview)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(6)
                            .padding(.horizontal)
                    }
                    Spacer()
                    PopularityBadge(score: Int(movie.vote_average * 10))
                        .padding(.bottom)
                }
            )
            .offset(isTop ? offset : .zero)
            .rotationEffect(.degrees(isTop ? Double(offset.width / 20) : 0))
            .gesture(
                isTop
                    ? DragGesture()
                        .onChanged { value in
                            offset = value.translation
                        }
                        .onEnded { value in
                            if abs(value.translation.width) > 100 {
                                if value.translation.width < 0 {
                                    store.send(.addToWishlistButtonTapped)
                                } else {
                                    store.send(.addToSeenListButtonTapped)
                                }
                            }
                            offset = .zero
                        }
                    : nil
            )
            .animation(.spring(), value: offset)
            .onTapGesture {
                if isTop {
                    store.send(.movieTapped(movie))
                }
            }
    }

    private var actionButtons: some View {
        HStack(spacing: 30) {
            Button {
                store.send(.addToWishlistButtonTapped)
            } label: {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                    .frame(width: 50, height: 50)
            }

            Button {
                store.send(.skipButtonTapped)
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.red)
                    .frame(width: 50, height: 50)
            }

            Button {
                store.send(.addToSeenListButtonTapped)
            } label: {
                Image(systemName: "eye.fill")
                    .foregroundColor(.green)
                    .frame(width: 50, height: 50)
            }

            Button {
                store.send(.refreshButtonTapped)
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.steam_gold)
                    .frame(width: 50, height: 50)
            }
        }
        .padding(.top, 16)
    }
}
