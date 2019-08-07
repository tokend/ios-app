import Foundation

protocol DashboardPendingOffersPreviewPlugInBusinessLogic {
    func onDidSelectViewMore(request: DashboardPendingOffersPreviewPlugIn.Event.DidSelectViewMore.Request)
}

extension DashboardPendingOffersPreviewPlugIn {
    typealias BusinessLogic = DashboardPendingOffersPreviewPlugInBusinessLogic
    
    class Interactor {
        
        private let presenter: PresentationLogic
        
        init(presenter: PresentationLogic) {
            self.presenter = presenter
        }
    }
}

extension DashboardPendingOffersPreviewPlugIn.Interactor: DashboardPendingOffersPreviewPlugIn.BusinessLogic {
    func onDidSelectViewMore(request: DashboardPendingOffersPreviewPlugIn.Event.DidSelectViewMore.Request) {
        let response = DashboardPendingOffersPreviewPlugIn.Event.DidSelectViewMore.Response()
        self.presenter.presentDidSelectViewMore(response: response)
    }
}
