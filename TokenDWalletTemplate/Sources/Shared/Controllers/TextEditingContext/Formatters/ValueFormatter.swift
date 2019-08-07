import UIKit

class ValueFormatter <ValueType> {
    
    func stringFromValue(_ value: ValueType?) -> String? {
        return nil
    }
    
    func valueFromString(_ string: String?) -> ValueType? {
        return nil
    }
}

class PlainTextValueFormatter: ValueFormatter <String> {
    override func stringFromValue(_ value: String?) -> String? {
        return value
    }
    
    override func valueFromString(_ string: String?) -> String? {
        return string
    }
}
