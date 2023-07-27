import Foundation

public struct ImageData: Codable, Equatable, Identifiable {
    public var id: String {
        file_path
    }
    let aspect_ratio: Float
    let file_path: String
    let height: Int
    let width: Int

    public init(aspect_ratio: Float, file_path: String, height: Int, width: Int) {
        self.aspect_ratio = aspect_ratio
        self.file_path = file_path
        self.height = height
        self.width = width
    }
}
