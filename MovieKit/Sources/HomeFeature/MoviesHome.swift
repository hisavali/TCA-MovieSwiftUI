import ComposableArchitecture
import Dependencies
import Foundation
import SwiftUI

@Reducer
public struct MoviesHomeFeature {
    @ObservableState
    public struct State {
        var mode: HomeMode = .list
    }

    public enum Action {
        case onTask
    }

    @Dependency(\.fetchNowPlayingMoviesClient.get) var fetchClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onTask:
                return .none
            }
        }
    }

    public enum HomeMode {
        case list, grid
        var icon: String {
            switch self {
            case .list: return "rectangle.3.offgrid.fill"
            case .grid: return "rectangle.grid.1x2"
            }
        }
    }
}

public struct MoviesHome: View {
    let store: StoreOf<MoviesHomeFeature>

    public init(store: StoreOf<MoviesHomeFeature>) {
        self.store = store
    }

    public var body: some View {
        Text("To do")
            .task {
                store.send(.onTask)
            }
    }
}
