import ComposableArchitecture
import Common
import Data
import Dependencies
import Foundation
import NetworkClient
import SwiftUI

@Reducer
public struct MovieRowFeature {
    public static let defaultPosterName = "camera.shutter.button"

    @ObservableState
    public struct State {
        var movie: Movie
        var moviePoster: Image
        var isMoviePosterLoading: Bool

        public init(
            movie: Movie,
            moviePoster: Image = .init(systemName: defaultPosterName),
            isMoviePosterLoading: Bool = false
        ) {
            self.movie = movie
            self.moviePoster = moviePoster
            self.isMoviePosterLoading = isMoviePosterLoading
        }
    }

    public enum Action {
        case didFetchImage(Image)
        case onTask
    }

    enum CancelID { case fetchImage }

    public enum MovieRowError: Error {
        case invalidPosterName
    }

    @Dependency(\.imageClient) var imageClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onTask:
                state.isMoviePosterLoading = true
                return .run { [imageName = state.movie.poster_path] send in
                    do {
                        guard let imageName = imageName else { throw MovieRowError.invalidPosterName }
                        let image = try await imageClient.fetchImage(imageName, .medium)
                        await send(.didFetchImage(image))
                    } catch {
                        return await send(.didFetchImage(.init(systemName: Self.defaultPosterName)))
                    }
                }
            case let .didFetchImage(image):
                state.isMoviePosterLoading = false
                state.moviePoster = image
                return .none
            }
        }
    }

    public init() { }
}

public struct MovieRow: View {
    let store: StoreOf<MovieRowFeature>

    public init(store: StoreOf<MovieRowFeature>) {
        self.store = store
    }

    public var body: some View {
        HStack {
            ZStack(alignment: .topLeading) {
                store.moviePoster
                    .resizable()
                    .renderingMode(.original)
                    .fixedSize()
                    .animation(.spring, value: store.moviePoster)
                    .transition(.opacity)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(store.movie.userTitle)
                    .titleStyle()
                    .foregroundColor(.steam_gold)
                    .lineLimit(2)
                HStack {
                    PopularityBadge(score: Int(store.movie.popularity))

                    Text(store.movie.releaseDate?.description ?? "Release date")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                Text(store.movie.overview)
                    .foregroundColor(.secondary)
                    .lineLimit(13) // TODO: To come from store
                    .truncationMode(.tail)
            }.padding(.leading, 16)
        }
        .padding()
        .contextMenu {
            VStack {
                Text("Add to favourite") // TODO: Add
            }
        }
        .redacted(reason: store.isMoviePosterLoading ? .placeholder : [])
        .task {
            store.send(.onTask)
        }
    }
}

#Preview {
    List {
        MovieRow(
            store: Store(
                initialState: MovieRowFeature.State(
                    movie: .mock,
                    moviePoster: Image(systemName: MovieRowFeature.defaultPosterName)
                )
            ) {
                MovieRowFeature()
                    ._printChanges()
            }
        )
    }
}
