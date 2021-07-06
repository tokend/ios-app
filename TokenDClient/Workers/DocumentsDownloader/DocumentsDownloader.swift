import Foundation

class DocumentsDownloader {
    
    // MARK: - Private properties
    
    private var documentsList: [URL: Data] = [:]
}

// MARK: - Private properties

private extension DocumentsDownloader {
    
    func downloadDocument(
        with link: URL,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        
        let task = URLSession.shared.downloadTask(
            with: link,
            completionHandler: { localURL, urlResponse, error in
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let response = urlResponse as? HTTPURLResponse,
                      response.statusCode == 200
                else {
                    completion(.failure(DocumentsDownloaderError.invalidStatusCode))
                    return
                }
                
                guard let localURL = localURL
                else {
                    completion(.failure(DocumentsDownloaderError.noLocalUrl))
                    return
                }
                
                do {
                    let document = try Data(contentsOf: localURL)
                    self.documentsList[link] = document
                    completion(.success(document))
                } catch {
                    completion(.failure(error))
                }
            })
        
        task.resume()
    }
}

extension DocumentsDownloader: DocumentsDownloaderProtocol {
    
    func loadDocument(
        with link: URL,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        
        if let document = documentsList[link] {
            completion(.success(document))
        } else {
            loadDocument(
                with: link,
                completion: completion
            )
        }
    }
}
