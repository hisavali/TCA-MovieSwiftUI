import Dependencies
import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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
            let (data, _) = try await URLSession.shared.data(for: size.path(poster: imageName))
            #if canImport(UIKit)
            guard let uiImage = UIImage(data: data) else {
                throw ImageClientError.invalidImageResponse
            }
            return Image(uiImage: uiImage)
            #elseif canImport(AppKit)
            guard let nsImage = NSImage(data: data) else {
                throw ImageClientError.invalidImageResponse
            }
            return Image(nsImage: nsImage)
            #endif
        }
    }
}

extension DependencyValues {
    public var imageClient: ImageClient {
        set { self[ImageClient.self] = newValue }
        get { self[ImageClient.self] }
    }
}
