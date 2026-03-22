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

        await store.receive(\.didFetchImage) {
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
            $0.imageClient.fetchImage = unimplemented("FetchImage should never be called")
        }

        await store.send(.onTask) {
            $0.isMoviePosterLoading = true
        }

        await store.receive(\.didFetchImage) {
            $0.isMoviePosterLoading = false
            $0.moviePoster = Image(systemName: MovieRowFeature.defaultPosterName)
        }
    }

    func testMoviesListOnTask() async {
        let movies = [Movie.mock]
        let store = TestStore(
            initialState: MoviesList.State(menu: .popular)
        ) {
            MoviesList()
        } withDependencies: {
            $0.moviesClient.fetchMenuList = { _, _, _ in
                PaginatedResponse(page: 1, total_results: 1, total_pages: 1, results: movies)
            }
        }

        await store.send(.onTask) {
            $0.isLoading = true
        }

        await store.receive(\.moviesResponse.success) {
            $0.isLoading = false
            $0.movies = movies
        }
    }
}


