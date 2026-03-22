import ComposableArchitecture
import Common
import Data
import Foundation
import NetworkClient
import SwiftUI

// MARK: - MovieDetail Feature

@Reducer
public struct MovieDetail {
    @ObservableState
    public struct State: Equatable {
        public var movieId: Int
        public var movie: Movie?
        public var cast: [People] = []
        public var crew: [People] = []
        public var recommended: [Movie] = []
        public var similar: [Movie] = []
        public var reviews: [Review] = []
        public var isLoading = false

        public init(movieId: Int, movie: Movie? = nil) {
            self.movieId = movieId
            self.movie = movie
        }
    }

    public enum Action {
        case castResponse(Result<CastResponse, any Error>)
        case detailResponse(Result<Movie, any Error>)
        case onTask
        case recommendedResponse(Result<PaginatedResponse<Movie>, any Error>)
        case reviewsResponse(Result<PaginatedResponse<Review>, any Error>)
        case similarResponse(Result<PaginatedResponse<Movie>, any Error>)
    }

    @Dependency(\.moviesClient) var moviesClient
    @Dependency(\.peopleClient) var peopleClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .castResponse(.success(response)):
                state.cast = response.cast
                state.crew = response.crew
                return .none

            case .castResponse(.failure):
                return .none

            case let .detailResponse(.success(movie)):
                state.movie = movie
                state.isLoading = false
                return .none

            case .detailResponse(.failure):
                state.isLoading = false
                return .none

            case .onTask:
                state.isLoading = true
                let movieId = state.movieId
                return .merge(
                    .run { send in
                        await send(.detailResponse(Result {
                            try await moviesClient.fetchDetail(movieId)
                        }))
                    },
                    .run { send in
                        await send(.castResponse(Result {
                            try await peopleClient.fetchMovieCasts(movieId)
                        }))
                    },
                    .run { send in
                        await send(.recommendedResponse(Result {
                            try await moviesClient.fetchRecommended(movieId)
                        }))
                    },
                    .run { send in
                        await send(.similarResponse(Result {
                            try await moviesClient.fetchSimilar(movieId)
                        }))
                    },
                    .run { send in
                        await send(.reviewsResponse(Result {
                            try await moviesClient.fetchReviews(movieId)
                        }))
                    }
                )

            case let .recommendedResponse(.success(response)):
                state.recommended = response.results
                return .none

            case .recommendedResponse(.failure):
                return .none

            case let .reviewsResponse(.success(response)):
                state.reviews = response.results
                return .none

            case .reviewsResponse(.failure):
                return .none

            case let .similarResponse(.success(response)):
                state.similar = response.results
                return .none

            case .similarResponse(.failure):
                return .none
            }
        }
    }

    public init() {}
}

// MARK: - MovieDetailView

public struct MovieDetailView: View {
    let store: StoreOf<MovieDetail>

    public init(store: StoreOf<MovieDetail>) {
        self.store = store
    }

    public var body: some View {
        List {
            if let movie = store.movie {
                topSection(movie: movie)
                castSection
                crewSection
                relatedSection
            } else if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .listStyle(.plain)
        .navigationTitle(store.movie?.userTitle ?? "")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .task {
            store.send(.onTask)
        }
    }

    // MARK: - Top Section

    private func topSection(movie: Movie) -> some View {
        Section {
            // Info row
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 4) {
                    PopularityBadge(score: Int(movie.vote_average * 10))
                    VStack(alignment: .leading, spacing: 4) {
                        if let releaseDate = movie.releaseDate {
                            Text(releaseDate, style: .date)
                                .font(.subheadline)
                        }
                        if let runtime = movie.runtime {
                            Text("\(runtime) minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if let status = movie.status {
                            Text(status)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let countries = movie.production_countries, !countries.isEmpty {
                    Text(countries.map(\.name).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Genres
                if let genres = movie.genres, !genres.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(genres) { genre in
                                Text(genre.name)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }

            // Reviews count
            if !store.reviews.isEmpty {
                NavigationLink {
                    ReviewsListView(reviews: store.reviews)
                } label: {
                    Text("\(store.reviews.count) reviews")
                        .foregroundColor(.blue)
                }
            }

            // Overview
            if !movie.overview.isEmpty {
                Text(movie.overview)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            // Keywords
            if let keywords = movie.keywords?.keywords, !keywords.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(keywords) { keyword in
                            Text(keyword.name)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.steam_gold.opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Cast Section

    @ViewBuilder
    private var castSection: some View {
        if !store.cast.isEmpty {
            Section("Cast") {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(store.cast.prefix(20)) { person in
                            VStack {
                                Circle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Text(String(person.name.prefix(1)))
                                            .font(.title2)
                                            .foregroundColor(.steam_gold)
                                    )
                                Text(person.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                if let character = person.character {
                                    Text(character)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .frame(width: 80)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Crew Section

    @ViewBuilder
    private var crewSection: some View {
        if !store.crew.isEmpty {
            let directors = store.crew.filter { $0.department == "Directing" }
            if !directors.isEmpty {
                Section("Crew") {
                    ForEach(directors.prefix(5)) { person in
                        HStack {
                            Text("Director:")
                                .font(.callout)
                            Text(person.name)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Related Section

    @ViewBuilder
    private var relatedSection: some View {
        if !store.similar.isEmpty {
            Section("Similar Movies") {
                movieCrossline(movies: store.similar)
            }
        }
        if !store.recommended.isEmpty {
            Section("Recommended Movies") {
                movieCrossline(movies: store.recommended)
            }
        }
    }

    private func movieCrossline(movies: [Movie]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(movies.prefix(10)) { movie in
                    NavigationLink(value: movie.id) {
                        VStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 100, height: 150)
                                .overlay(
                                    Text(movie.userTitle)
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
                                        .padding(4)
                                )
                            Text(movie.userTitle)
                                .font(.caption)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 100)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - ReviewsListView

struct ReviewsListView: View {
    let reviews: [Review]

    var body: some View {
        List(reviews) { review in
            VStack(alignment: .leading, spacing: 8) {
                Text(review.author)
                    .font(.headline)
                    .foregroundColor(.steam_gold)
                Text(review.content)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Reviews")
    }
}
