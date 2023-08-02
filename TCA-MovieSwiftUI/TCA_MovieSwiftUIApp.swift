import Data
import HomeFeature
import SwiftUI

@main
struct TCA_MovieSwiftUIApp: App {
    var body: some Scene {
        WindowGroup {
            MovieRow(
                store: .init(
                    initialState: .init(
                        movie: Movie.mock,
                        moviePoster: Image(systemName: "camera.shutter.button")
                    )
                ) {
                    MovieRowFeature()
                        ._printChanges()
                })
        }
    }
}
