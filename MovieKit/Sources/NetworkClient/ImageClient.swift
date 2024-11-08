import Dependencies
import Foundation
import SwiftUI

public enum ImageClientError: Error {
    case invalidURL
    case invalidImageResponse
}

public struct ImageClient {
    public enum Size: String {
        case small = "https://image.tmdb.org/t/p/w154/"
        case medium = "https://image.tmdb.org/t/p/w500/"
        case cast = "https://image.tmdb.org/t/p/w185/"
        case original = "https://image.tmdb.org/t/p/original/"

        func path(poster: String) throws -> URLRequest {
            guard let url = URL(string: rawValue) else {
                throw ImageClientError.invalidURL
            }

            return .init(url: url.appendingPathComponent(poster))
        }
    }
    public var fetchImage: @Sendable (String, Size) async throws -> Image
}

extension ImageClient: DependencyKey {
    public static var liveValue: ImageClient {
        .init { imageName, size in
            let (data, response) = try await URLSession.shared.data(for: size.path(poster: imageName))
            _ = response // TODO: Handle error if responsecode is not
            guard let uiImage = UIImage(data: data) else {
                throw ImageClientError.invalidImageResponse
            }

            try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)

            return Image.init(uiImage: uiImage)
        }
    }
    //static public var testValue: ImageClient {}
    //static public var previewValue: ImageClient {}
}

extension DependencyValues {
    public var imageClient: ImageClient {
        set { self[ImageClient.self] = newValue }
        get { self[ImageClient.self] }
    }
}
