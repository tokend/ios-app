import Foundation

class APIConfigurationFetcher {
    
    enum FetcherError: Error, LocalizedError {
        case couldNotFindConfigurationPlist(named: String)
        case couldNotParseData
        
        var errorDescription: String? {
            switch self {
            case .couldNotFindConfigurationPlist(let name):
                return "Could not find \(name).plist file"
            case .couldNotParseData:
                return "Could not parse APIConfigurationModel from provided .plist file"
            }
        }
    }
    
    static func fetchApiConfigurationFromPlist(_ plistName: String) throws -> APIConfigurationModel {
        guard let path = Bundle.main.path(forResource: plistName, ofType: "plist"),
            let dictionary = NSDictionary(contentsOfFile: path) as? [String: Any]
            else {
                throw FetcherError.couldNotFindConfigurationPlist(named: plistName)
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            return try APIConfigurationModel.decode(from: data)
        } catch {
            throw FetcherError.couldNotParseData
        }
    }
}
