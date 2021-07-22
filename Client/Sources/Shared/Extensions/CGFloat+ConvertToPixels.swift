 import UIKit
 
 extension CGFloat {
    
    public func convertToPixels() -> CGFloat {
        
        return self / UIScreen.main.scale
    }
}
