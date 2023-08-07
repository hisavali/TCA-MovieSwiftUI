import Data
import HomeFeature
import SwiftUI
import Dependencies

@main
struct TCA_MovieSwiftUIApp: App {
    @Dependency(\.fetchNowPlayingMoviesClient.get) var fetchMovie
    @State var movie: Movie = .mock
    var body: some Scene {
        WindowGroup {
            MovieRow(
                store: .init(
                    initialState: .init(
                        movie: self.movie,
                        moviePoster: Image(systemName: "camera.shutter.button")
                    )
                ) {
                    MovieRowFeature()
                        ._printChanges()
                })
            .task {
                do {
                    let r = try await self.fetchMovie()
                    // TODO: remove this `task` and move it to parent and it's store
                    self.movie = r.results.first ?? .mock
                    print(r)
                } catch {
                    print(error)
                }
            }
        }
    }
}
