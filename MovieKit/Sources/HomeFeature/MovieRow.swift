import ComposableArchitecture
import Common
import Data
import Foundation
import SwiftUI

struct MovieRowFeature: ReducerProtocol {
    struct State: Equatable {
        var movie: Movie
    }

    enum Action: Equatable {}

    var body: some ReducerProtocolOf<Self> {
        Reduce<State, Action> { state, action in
            return .none
        }
    }
}

struct MovieRow: View {
    let store: StoreOf<MovieRowFeature>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            HStack {
                ZStack(alignment: .topLeading) {
                    Image(systemName: "camera.shutter.button")
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
            .redacted(reason: .placeholder)
        }
    }
}

struct MovieRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            MovieRow(store: .init(initialState: .init(movie: .mock)) {
                MovieRowFeature()
            })
        }
    }
}
