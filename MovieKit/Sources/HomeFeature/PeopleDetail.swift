import ComposableArchitecture
import Common
import Data
import Foundation
import NetworkClient
import SwiftUI

// MARK: - PeopleDetail Feature

@Reducer
public struct PeopleDetail {
    @ObservableState
    public struct State: Equatable {
        public var personId: Int
        public var person: People?
        public var castCredits: [Movie] = []
        public var crewCredits: [Movie] = []
        public var images: [ImageData] = []
        public var isInFanClub = false
        public var isLoading = false

        public init(personId: Int) {
            self.personId = personId
        }
    }

    public enum Action {
        case creditsResponse(Result<PeopleCreditsResponse, any Error>)
        case detailResponse(Result<People, any Error>)
        case fanClubToggleTapped
        case imagesResponse(Result<PeopleImagesResponse, any Error>)
        case onTask
    }

    @Dependency(\.peopleClient) var peopleClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .creditsResponse(.success(response)):
                state.castCredits = response.cast ?? []
                state.crewCredits = response.crew ?? []
                return .none

            case .creditsResponse(.failure):
                return .none

            case let .detailResponse(.success(person)):
                state.person = person
                state.isLoading = false
                return .none

            case .detailResponse(.failure):
                state.isLoading = false
                return .none

            case .fanClubToggleTapped:
                state.isInFanClub.toggle()
                return .none

            case let .imagesResponse(.success(response)):
                state.images = response.profiles
                return .none

            case .imagesResponse(.failure):
                return .none

            case .onTask:
                state.isLoading = true
                let personId = state.personId
                return .merge(
                    .run { send in
                        await send(.detailResponse(Result {
                            try await peopleClient.fetchDetail(personId)
                        }))
                    },
                    .run { send in
                        await send(.creditsResponse(Result {
                            try await peopleClient.fetchCredits(personId)
                        }))
                    },
                    .run { send in
                        await send(.imagesResponse(Result {
                            try await peopleClient.fetchImages(personId)
                        }))
                    }
                )
            }
        }
    }

    public init() {}
}

// MARK: - PeopleDetailView

public struct PeopleDetailView: View {
    let store: StoreOf<PeopleDetail>

    public init(store: StoreOf<PeopleDetail>) {
        self.store = store
    }

    public var body: some View {
        List {
            if let person = store.person {
                headerSection(person: person)
                biographySection(person: person)
                imagesSection
                filmographySection
            } else if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .listStyle(.plain)
        .navigationTitle(store.person?.name ?? "")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    store.send(.fanClubToggleTapped)
                } label: {
                    Image(systemName: store.isInFanClub ? "star.fill" : "star")
                        .foregroundColor(.steam_gold)
                }
            }
        }
        .task {
            store.send(.onTask)
        }
    }

    private func headerSection(person: People) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 16) {
                    Circle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(String(person.name.prefix(1)))
                                .font(.largeTitle)
                                .foregroundColor(.steam_gold)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(person.name)
                            .font(.title2)
                            .foregroundColor(.steam_gold)
                        if let department = person.known_for_department {
                            Text(department)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        if let knownFor = person.knownForText {
                            Text(knownFor)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func biographySection(person: People) -> some View {
        Section("Biography") {
            VStack(alignment: .leading, spacing: 8) {
                if let birthDay = person.birthDay {
                    HStack {
                        Text("Born:")
                            .font(.subheadline)
                        Text(birthDay)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                if let deathDay = person.deathDay {
                    HStack {
                        Text("Died:")
                            .font(.subheadline)
                        Text(deathDay)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                if let place = person.place_of_birth {
                    HStack {
                        Text("Place:")
                            .font(.subheadline)
                        Text(place)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                if let biography = person.biography, !biography.isEmpty {
                    Text(biography)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var imagesSection: some View {
        if !store.images.isEmpty {
            Section("Photos") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.images.prefix(10)) { image in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 80, height: 120)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var filmographySection: some View {
        if !store.castCredits.isEmpty {
            Section("Filmography (Cast)") {
                ForEach(store.castCredits.prefix(20)) { movie in
                    NavigationLink(value: movie.id) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(movie.userTitle)
                                    .font(.subheadline)
                                if let character = movie.character {
                                    Text("as \(character)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if let date = movie.release_date {
                                Text(date.prefix(4))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        if !store.crewCredits.isEmpty {
            Section("Filmography (Crew)") {
                ForEach(store.crewCredits.prefix(20)) { movie in
                    NavigationLink(value: movie.id) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(movie.userTitle)
                                    .font(.subheadline)
                                if let department = movie.department {
                                    Text(department)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if let date = movie.release_date {
                                Text(date.prefix(4))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}
