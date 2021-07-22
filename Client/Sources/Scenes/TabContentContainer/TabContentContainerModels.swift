import UIKit

public enum TabContentContainer {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension TabContentContainer.Model { }

// MARK: - Events

extension TabContentContainer.Event {
    
    public typealias Model = TabContentContainer.Model
    
    // MARK: -
}
