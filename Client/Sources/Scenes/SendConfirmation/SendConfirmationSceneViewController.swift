import UIKit

public protocol SendConfirmationSceneDisplayLogic: AnyObject {
    
    typealias Event = SendConfirmationScene.Event
    
    func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel)
    func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel)
}

extension SendConfirmationScene {
    
    public typealias DisplayLogic = SendConfirmationSceneDisplayLogic
    
    @objc(SendConfirmationSceneViewController)
    public class ViewController: BaseViewController {
        
        public typealias Event = SendConfirmationScene.Event
        public typealias Model = SendConfirmationScene.Model
        
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
        }
    }
}

// MARK: - Private methods

private extension SendConfirmationScene.ViewController {
    
    func setup(
        with sceneViewModel: Model.SceneViewModel,
        animated: Bool
    ) { }
}

// MARK: - DisplayLogic

extension SendConfirmationScene.ViewController: SendConfirmationScene.DisplayLogic {
    
    public func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
}
