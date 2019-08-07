import Foundation

enum DashboardScene {
    
    // MARK: - Typealiases
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

extension DashboardScene.Model {
    struct SceneModel {
        var plugIns: [DashboardScene.PlugIn]
    }
}

extension DashboardScene.Event {
    enum ViewDidLoadSync {
        struct Request { }
    }
    
    enum DidInitiateRefresh {
        struct Request { }
    }
    
    enum PlugInsDidChange {
        struct Response {
            let plugIns: [DashboardScene.PlugIn]
        }
        struct ViewModel {
            let plugIns: [DashboardScene.PlugIn]
        }
    }
}
