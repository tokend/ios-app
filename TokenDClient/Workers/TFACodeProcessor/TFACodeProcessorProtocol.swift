import Foundation

protocol TFACodeProcessorProtocol {

    func process(
        tfaCode: String
    ) throws -> String
}
