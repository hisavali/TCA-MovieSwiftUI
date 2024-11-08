import Foundation

public struct PaginatedResponse<T: Codable>: Codable {
    public let page: Int?
    public let total_results: Int?
    public let total_pages: Int?
    public let results: [T]

    init(
        page: Int?,
        total_results: Int?,
        total_pages: Int?,
        results: [T]
    ) {
        self.page = page
        self.total_results = total_results
        self.total_pages = total_pages
        self.results = results
    }

    public struct Builder {
        public var page: Int? = nil
        public var total_results: Int? = nil
        public var total_pages: Int? = nil
        public var results: [T] = []

        func build() -> PaginatedResponse<T> {
            return PaginatedResponse(
                page: self.page,
                total_results: self.total_results,
                total_pages: self.total_pages,
                results: self.results)
        }
    }

    static public func build(_ set: @escaping (inout Builder) -> Void) -> Self {
        var builder = Builder()
        set(&builder)
        return builder.build()
    }
}

