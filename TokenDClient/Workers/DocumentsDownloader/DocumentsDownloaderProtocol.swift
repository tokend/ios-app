import Foundation

enum DocumentsDownloaderError: Swift.Error {
    
    case invalidStatusCode
    case noLocalUrl
}

protocol DocumentsDownloaderProtocol {
    
    func loadDocument(
        with link: URL,
        completion: @escaping (Result<Data, Swift.Error>) -> Void
    )
}
