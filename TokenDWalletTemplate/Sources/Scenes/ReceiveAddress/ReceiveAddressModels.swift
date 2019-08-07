import Foundation
import UIKit

enum ReceiveAddress {
    
    typealias Address = String
    
    enum Model {}
    enum Event {}
}

extension ReceiveAddress.Model {
    
    struct SceneModel {
        var address: ReceiveAddress.Address
        var qrCodeSize: CGSize
        var availableValueActions: [ValueAction]
        
        init() {
            self.address = ""
            self.qrCodeSize = .zero
            self.availableValueActions = []
        }
    }
    
    struct ViewConfig {
        let copiedLocalizationKey: String
        let tableViewTopInset: CGFloat
    }
    
    enum ValueAction {
        case copy
        case share
    }
}

extension ReceiveAddress.Event {
    
    enum ViewDidLoad {
        struct Request { }
    }
    
    enum ViewDidLoadSync {
        struct Request { }
        struct Response {
            let address: ReceiveAddress.Address
        }
        struct ViewModel {
            let address: ReceiveAddress.Address
            let valueLinesNumber: Int
        }
    }
    
    enum ViewDidLayoutSubviews {
        struct Request {
            let qrCodeSize: CGSize
        }
    }
    
    enum ViewWillAppear {
        struct Request { }
    }
        
    enum CopyAction {
        struct Request { }
        struct Response {
            let stringToCopy: String
        }
        struct ViewModel {
            let stringToCopy: String
        }
    }
    
    enum ShareAction {
        struct Request { }
        struct Response {
            let itemsToShare: [Any]
        }
        struct ViewModel {
            let itemsToShare: [Any]
        }
    }
    
    enum QRCodeRegenerated {
        struct Response {
            let address: ReceiveAddress.Address
            let qrSize: CGSize
        }
        struct ViewModel {
            let qrCode: UIImage
        }
    }
    
    enum ValueChanged {
        struct Response {
            let address: ReceiveAddress.Address
            let availableValueActions: [ReceiveAddress.Model.ValueAction]
        }
        struct ViewModel {
            let value: String
        }
    }
    
    enum ValueActionsChanged {
        struct ViewModel {
            let availableValueActions: [Action]
            
            struct Action {
                let title: String
                let valueAction: ReceiveAddress.Model.ValueAction
            }
        }
    }
}
