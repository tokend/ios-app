import UIKit

protocol BiometricsAuthDisplayLogic: class {
    func displayViewDidAppear(viewModel: BiometricsAuth.Event.ViewDidAppear.ViewModel)
}

extension BiometricsAuth {
    typealias DisplayLogic = BiometricsAuthDisplayLogic
    
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
            
            self.setupView()
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            let request = BiometricsAuth.Event.ViewDidAppear.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidAppear(request: request)
            }
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.contentBackgroundColor
        }
    }
}

extension BiometricsAuth.ViewController: BiometricsAuth.DisplayLogic {
    func displayViewDidAppear(viewModel: BiometricsAuth.Event.ViewDidAppear.ViewModel) {
        switch viewModel {
            
        case .failure:
            self.routing?.onAuthFailed()
            
        case .success(let account):
            self.routing?.onAuthSucceeded(account)
            
        case .userCancel:
            self.routing?.onUserCancelled()
            
        case .userFallback:
            self.routing?.onUserFallback()
        }
    }
}
