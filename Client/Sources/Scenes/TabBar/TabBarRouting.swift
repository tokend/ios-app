import Foundation

extension TabBar {
    public struct Routing {
        
        /// Should return `true` if screen for selected tab for shown and tab bar should select the tab.
        /// Otherwise return `false`
        let onTabSelected: (_ identifier: String) -> Bool
    }
}
