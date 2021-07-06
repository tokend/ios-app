import Foundation

class DefaultTFACodeProcessor { }

// MARK: - TFACodeProcessorProtocol

extension DefaultTFACodeProcessor: TFACodeProcessorProtocol {

    func process(
        tfaCode: String
    ) throws -> String {
        
        return tfaCode
    }
}
