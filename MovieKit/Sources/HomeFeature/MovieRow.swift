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
    @Dependency(\.imageClient) var imageClient
    public struct State: Equatable {
        var movie: Movie
        var moviePoster: Image
        var isMoviePosterLoading: Bool

        public init(
            movie: Movie,
            moviePoster: Image = .init(systemName: defaultPosterName),
            isMoviePosterLoading: Bool = false//,
            //imageClient: ImageClient = ???
        ) {
            self.movie = movie
            self.moviePoster = moviePoster
            self.isMoviePosterLoading = isMoviePosterLoading
        }
    }

    public enum Action: Equatable {
        case onTask
        case didFetchImage(Image)
    }

    public enum MovieRowError: Error {
        case invalidPosterName
    }

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
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
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            HStack {
                ZStack(alignment: .topLeading) {
                    viewStore.moviePoster
                        .resizable()
                        .renderingMode(.original)
                        .fixedSize()
                        .animation(.spring())
                        .transition(.opacity)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(viewStore.movie.userTitle)
                        .titleStyle()
                        .foregroundColor(.steam_gold)
                        .lineLimit(2)
                    HStack {
                        PopularityBadge(score: Int(viewStore.movie.popularity))

                        Text(viewStore.movie.releaseDate?.description ?? "Release date")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    Text(viewStore.movie.overview)
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
            .redacted(reason: viewStore.isMoviePosterLoading ? .placeholder : [])
            .task {
                await viewStore.send(.onTask).finish()
            }
        }
    }
}

struct MovieRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            MovieRow(
                store: .init(
                    initialState: .init(
                        movie: .mock,
                        moviePoster: .init(systemName: MovieRowFeature.defaultPosterName)
                    )
            ) {
                MovieRowFeature()
                    ._printChanges()
            })
        }
    }
}
