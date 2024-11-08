import ComposableArchitecture
import Dependencies
import Foundation
import SwiftUI

public struct MoviesHomeFeature: ReducerProtocol {
    @Dependency(\.fetchNowPlayingMoviesClient.get) var fetchClient
    public struct State: Equatable {
        var mode: HomeMode = .list
    }

    public enum Action: Equatable {
        case onTask
    }

    public var body: some ReducerProtocolOf<Self> {
        Reduce<State, Action> { state, action in
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
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Text("To do")
                .task {
                    await viewStore.send(.onTask).finish()
                }
        }
    }
}
