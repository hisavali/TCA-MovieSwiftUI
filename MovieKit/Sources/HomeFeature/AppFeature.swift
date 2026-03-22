import ComposableArchitecture
import Common
import Data
import Foundation
import NetworkClient
import SwiftUI

// MARK: - AppFeature

@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        public var selectedTab: Tab = .movies
        public var moviesHome = MoviesHome.State()
        public var discover = Discover.State()

        public init() {}
    }

    public enum Tab: Int, Equatable, Sendable {
        case movies, discover, fanClub, myLists
    }

    public enum Action {
        case discover(Discover.Action)
        case moviesHome(MoviesHome.Action)
        case tabSelected(Tab)
    }

    public var body: some ReducerOf<Self> {
        Scope(state: \.moviesHome, action: \.moviesHome) {
            MoviesHome()
        }
        Scope(state: \.discover, action: \.discover) {
            Discover()
        }
        Reduce { state, action in
            switch action {
            case .discover:
                return .none
            case .moviesHome:
                return .none
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
            }
        }
    }

    public init() {}
}

// MARK: - AppView

public struct AppView: View {
    @Perception.Bindable var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            MoviesHomeView(store: store.scope(state: \.moviesHome, action: \.moviesHome))
                .tabItem {
                    Label("Movies", systemImage: "film")
                }
                .tag(AppFeature.Tab.movies)

            DiscoverView(store: store.scope(state: \.discover, action: \.discover))
                .tabItem {
                    Label("Discover", systemImage: "square.stack")
                }
                .tag(AppFeature.Tab.discover)

            FanClubPlaceholderView()
                .tabItem {
                    Label("Fan Club", systemImage: "star.circle.fill")
                }
                .tag(AppFeature.Tab.fanClub)

            MyListsPlaceholderView()
                .tabItem {
                    Label("My Lists", systemImage: "heart.circle")
                }
                .tag(AppFeature.Tab.myLists)
        }
        .accentColor(.steam_gold)
    }
}

// MARK: - Placeholder views for Fan Club and My Lists tabs

struct FanClubPlaceholderView: View {
    var body: some View {
        NavigationStack {
            Text("Fan Club - Coming Soon")
                .foregroundColor(.secondary)
                .navigationTitle("Fan Club")
        }
    }
}

struct MyListsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            Text("My Lists - Coming Soon")
                .foregroundColor(.secondary)
                .navigationTitle("My Lists")
        }
    }
}
