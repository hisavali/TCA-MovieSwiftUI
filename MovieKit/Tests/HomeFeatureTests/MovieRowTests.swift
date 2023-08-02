import ComposableArchitecture
@testable import HomeFeature
import Data
import SwiftUI
import XCTest

@MainActor
final class MovieRowTests: XCTestCase {
    func testMovieRowOnTask() async {
        let store = TestStore(
            initialState: MovieRowFeature.State(movie: .mock)
        ) {
            MovieRowFeature()
        } withDependencies: {
            $0.imageClient.fetchImage = { _, _ in
                return .init(systemName: "figure.play")
            }
        }

        await store.send(.onTask) {
            $0.isMoviePosterLoading = true
        }

        await store.receive(.didFetchImage(Image(systemName: "figure.play"))) {
            $0.isMoviePosterLoading = false
            $0.moviePoster = Image(systemName: "figure.play")
        }
    }

    func testMovieRowOnTask_InvalidPosterName() async {
        let store = TestStore(
            initialState: MovieRowFeature.State(
                movie: Movie.build {
                    $0.poster_path = nil
                }
            )
        ) {
            MovieRowFeature()
        } withDependencies: {
            // It's important to check that fetchImage isn't called.
            $0.imageClient.fetchImage = unimplemented("FetchImage should never be called")
        }

        await store.send(.onTask) {
            $0.isMoviePosterLoading = true
        }

        await store.receive(.didFetchImage(Image(systemName: MovieRowFeature.defaultPosterName))) {
            $0.isMoviePosterLoading = false
            $0.moviePoster = Image(systemName: MovieRowFeature.defaultPosterName)
        }
    }
}


