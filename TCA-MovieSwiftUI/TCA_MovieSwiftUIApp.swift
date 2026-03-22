import ComposableArchitecture
import HomeFeature
import SwiftUI

@main
struct TCA_MovieSwiftUIApp: App {
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
            ._printChanges()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}
