import UIKit

protocol WalletRecoveryDisplayLogic: class {
    func displayViewDidLoad(viewModel: WalletRecovery.Event.ViewDidLoad.ViewModel)
}

extension WalletRecovery {
    typealias DisplayLogic = WalletRecoveryDisplayLogic
    
    class ViewController: UIViewController {
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        
        func inject(interactorDispatch: InteractorDispatch?, routing: Routing?) {
            self.interactorDispatch = interactorDispatch
            self.routing = routing
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
//            let request = WalletRecovery.Event.ViewDidLoad.Request()
//            self.interactorDispatch?.sendRequest { businessLogic in
//                businessLogic.onViewDidLoad(request: request)
//            }
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
//            let request = WalletRecovery.Event.ViewDidLoad.Request()
//            self.interactorDispatch?.sendRequest { businessLogic in
//                businessLogic.onViewDidLoad(request: request)
//            }
        }
    }
}

extension WalletRecovery.ViewController: WalletRecovery.DisplayLogic {
    func displayViewDidLoad(viewModel: WalletRecovery.Event.ViewDidLoad.ViewModel) {

    }
}
