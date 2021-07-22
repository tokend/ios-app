import UIKit

extension TabBar {
    
    class TabBarItem: UITabBarItem {
        
        let identifier: Model.TabIdentifier
        
        // MARK: -
        
        init(
            title: String?,
            image: UIImage?,
            identifier: Model.TabIdentifier
            ) {
            
            self.identifier = identifier
            super.init()
            
            self.title = title
            self.image = image
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
