import UIKit

enum SideMenu {
    
    // MARK: - Typealiases
    
    // MARK: -
   
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension SideMenu.Model {
    
    struct HeaderModel {
        let icon: UIImage?
        let title: String?
        let subTitle: String?
    }
    
    class SceneModel {
        
        var sections: [[MenuItem]]
        
        init(sections: [[MenuItem]]) {
            self.sections = sections
        }
    }
    
    class MenuItem {
        
        typealias OnSelected = (() -> Void)
        
        let iconImage: UIImage?
        var title: String
        
        var onSelected: OnSelected?
        
        // MARK: -
        
        init(
            iconImage: UIImage,
            title: String,
            onSelected: OnSelected?
            ) {
            
            self.iconImage = iconImage
            self.title = title
            
            self.onSelected = onSelected
        }
    }
}

// MARK: - Events

extension SideMenu.Event {
    enum ViewDidLoad {
        struct Request {
            
        }
        
        struct Response {
            let header: SideMenu.Model.HeaderModel
            let sections: [[SideMenu.Model.MenuItem]]
        }
        
        struct ViewModel {
            let header: SideMenu.Model.HeaderModel
            let sections: [[SideMenuTableViewCell.Model]]
        }
    }
}
