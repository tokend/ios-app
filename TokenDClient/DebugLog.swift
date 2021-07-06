import Foundation

enum DebugOutputType {
    case `deinit`(object: AnyObject)
    case debug(message: String)
    case log(message: String)
    case error(error: String)
    case fatalError(error: String)
    
    var rawValue: String {
        switch self {
        case .deinit:
            return "- deinit"
        case .debug:
            return "- debug"
        case .log:
            return "- log"
        case .error:
            return "- error"
        case .fatalError:
            return "- FATAL"
        }
    }
    
    var emoji: String {
        switch self {
        case .deinit:
            return "♻️"
        case .debug:
            return "🚾"
        case .log:
            return "❕"
        case .error:
            return "⚠️"
        case .fatalError:
            return "🚫"
        }
    }
    
    var message: String {
        switch self {
        case .deinit(let object):
            return NSStringFromClass(type(of: object))
        case .debug(let message):
            return message
        case .log(let message):
            return message
        case .error(let error):
            return error
        case .fatalError(let error):
            return error.uppercased()
        }
    }
}

func print(
    _ debugOutputType: DebugOutputType,
    fileName: String = #file,
    line: Int = #line,
    column: Int = #column,
    functionName: String = #function) {
    
    DebugOutput.instance.print(
        outputType: debugOutputType,
        outputTypeString: debugOutputType.rawValue,
        outputEmoji: debugOutputType.emoji,
        message: debugOutputType.message,
        fileName: fileName,
        line: line,
        column: column,
        functionName: functionName)
}

protocol Logger {
    func log(_ message: String)
}

func setLogger(_ logger: Logger) {
    DebugOutput.instance.logger = logger
}

private struct DebugOutput {
    
    // MARK: - Singleton
    
    fileprivate static var instance = DebugOutput()
    private init() { }
    
    // MARK: - Date formatter
    
    private let debugOutputDateFormat = "yyyy-MM-dd hh:mm:ssSSS"
    fileprivate lazy var debugOutputDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = debugOutputDateFormat
        return formatter
    }()
    fileprivate var logger: Logger? = nil
    
    //  MARK: - Helpers
    
    private func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
    
    // MARK: - Print
    
    func print(
        outputType debugOutputType: DebugOutputType,
        outputTypeString debugOutputTypeString: String,
        outputEmoji debugOutputEmoji: String,
        message: String?,
        fileName: String = #file,
        line: Int = #line,
        column: Int = #column,
        functionName: String = #function) {
        
        #if APPSTOREDEBUG // Set correct Scheme names
            //let date = Date().toDebugOutputString()
            let debugType = debugOutputTypeString.padding(toLength: 9, withPad: " ", startingAt: 0)
            let outputEmoji = debugOutputEmoji
            let fileName = sourceFileName(filePath: fileName).padding(toLength: 40, withPad: " ", startingAt: 0)
            let functionName = functionName.padding(toLength: 30, withPad: " ", startingAt: 0)
            let lineAndColumn = ":\(line):\(column)".padding(toLength: 10, withPad: " ", startingAt: 0)
            var stringToPrint = ""// Uncomment to print with date "\(date) "
            stringToPrint += "\(debugType)\(outputEmoji) \(fileName)  \(functionName) \(lineAndColumn)"
            if let message = message {
                stringToPrint += " :: \(message)"
            }
            
            logger?.log(stringToPrint)
            #if APPSTOREDEBUG
                Swift.print(stringToPrint)
                
                switch debugOutputType {
                case .fatalError(let error):
                    assertionFailure(error)
                default:
                    break
                }
            #endif
        #endif
    }
}

// MARK: - Date convinient extension

private extension Date {
    func toDebugOutputString() -> String {
        return DebugOutput.instance.debugOutputDateFormatter.string(from: self)
    }
}

