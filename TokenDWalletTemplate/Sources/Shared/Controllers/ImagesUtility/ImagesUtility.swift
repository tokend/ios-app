import Foundation

public class ImagesUtility {
    
    // MARK: - Private properties
    
    private let storageUrl: String
    
    // MARK: -
    
    public init(
        storageUrl: String
        ) {
        
        self.storageUrl = storageUrl
    }
    
    // MARK: - Public
    
    public func getImageURL(_ key: ImageKey?) -> URL? {
        guard let key = key else {
            return nil
        }
        
        let urlString: String
        
        switch key {
            
        case .url(let url):
            guard url.count > 0 else {
                return nil
            }
            
            urlString = url
            
        case .key(let key):
            guard key.count > 0 else {
                return nil
            }
            
            let storageUrlChecked: String
            if self.storageUrl.hasSuffix("/") {
                storageUrlChecked = self.storageUrl
            } else {
                storageUrlChecked = self.storageUrl.appending("/")
            }
            
            urlString = storageUrlChecked.appending(key)
        }
        
        return URL(string: urlString)
    }
}

// MARK: -

extension ImagesUtility {
    
    public enum ImageKey {
        
        case url(String)
        case key(String)
    }
}
