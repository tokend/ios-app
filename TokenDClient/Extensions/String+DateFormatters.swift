import Foundation

private enum DateFormatterError: Swift.Error {
    case cannotParseData
}

extension String {

    func date(
    ) throws -> Date {

        let dateFormatter: DateFormatter = .init()
        
        let formats: [String] = [
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd"
        ]

        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: self) {
                return date
            }
        }

        throw DateFormatterError.cannotParseData
    }
}
