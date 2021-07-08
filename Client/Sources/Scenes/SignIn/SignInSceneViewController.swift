import UIKit

public protocol SignInSceneDisplayLogic: class {
    
    typealias Event = SignInScene.Event
    
    func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel)
    func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel)
}

extension SignInScene {
    
    public typealias DisplayLogic = SignInSceneDisplayLogic
    
    @objc(SignInSceneViewController)
    public class ViewController: BaseViewController {
        
        public typealias Event = SignInScene.Event
        public typealias Model = SignInScene.Model
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        private var onDeinit: DeinitCompletion = nil
        
        public func inject(
            interactorDispatch: InteractorDispatch?,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.routing = routing
            self.onDeinit = onDeinit
        }
        
        // MARK: - Overridden
        
        public override func viewDidLoad() {
            super.viewDidLoad()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
            
            let requestSync = Event.ViewDidLoadSync.Request()
            self.interactorDispatch?.sendSyncRequest { businessLogic in
                businessLogic.onViewDidLoadSync(request: requestSync)
            }
        }
        
        public override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            
            removeKeyboardObserver()
        }
        
        public override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            addKeyboardObserver()
        }
    }
}

// MARK: - Private methods

private extension SignInScene.ViewController {
    
    func setup() {
        setupView()
        setupNetworkTextField()
    }
    
    func setupView() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.title = "Sign in"
    }
    
    func setupNetworkTextField() {
        
    }
    
    func setup(
        with sceneViewModel: Model.SceneViewModel,
        animated: Bool
    ) { }
    
    func addKeyboardObserver() {
        let observer: KeyboardObserver = .init(
            self,
            keyboardWillChange: { [weak self] (attributes) in
                self?.updateView(with: attributes)
            }
        )
        KeyboardController.shared.add(observer: observer)
    }
    
    func removeKeyboardObserver() {
        KeyboardController.shared.remove(observer: .init(self))
    }
    
    func updateView(
        with attributes: KeyboardAttributes? = KeyboardController.shared.attributes
    ) {
        
        guard let attributes = attributes
        else {
            relayoutView(with: nil)
            return
        }
        
        UIView.animate(
            withKeyboardAttributes: attributes,
            animations: {
                self.relayoutView(with: attributes)
                if self.view.isVisible {
                    self.view.layoutIfNeeded()
                }
        })
    }
    
    func relayoutView(
        with attributes: KeyboardAttributes?
    ) {
        
        let keyboardHeightInView: CGFloat = attributes?.heightIn(view: self.view) ?? 0.0
    }
}

// MARK: - DisplayLogic

extension SignInScene.ViewController: SignInScene.DisplayLogic {
    
    public func display<#Event#>(viewModel: Event.<#Event#>.ViewModel) {
        
    }
    
    public func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
}
