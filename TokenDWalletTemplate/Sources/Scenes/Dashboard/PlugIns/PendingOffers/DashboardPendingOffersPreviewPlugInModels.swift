import Foundation

enum DashboardPendingOffersPreviewPlugIn {
    
    // MARK: - Typealiases

    // MARK: -
    
    enum Model {}
    enum Event {}
}

extension DashboardPendingOffersPreviewPlugIn.Model { }

extension DashboardPendingOffersPreviewPlugIn.Event {
    enum DidSelectViewMore {
        struct Request { }
        struct Response { }
        struct ViewModel { }
    }
}
