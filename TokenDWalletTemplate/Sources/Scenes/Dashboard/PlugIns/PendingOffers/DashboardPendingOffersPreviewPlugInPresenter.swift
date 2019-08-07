import Foundation

protocol DashboardPendingOffersPreviewPlugInPresentationLogic {
    func presentDidSelectViewMore(response: DashboardPendingOffersPreviewPlugIn.Event.DidSelectViewMore.Response)
}

extension DashboardPendingOffersPreviewPlugIn {
    typealias PresentationLogic = DashboardPendingOffersPreviewPlugInPresentationLogic
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        
        init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
    }
}

extension DashboardPendingOffersPreviewPlugIn.Presenter: DashboardPendingOffersPreviewPlugIn.PresentationLogic {
    func presentDidSelectViewMore(response: DashboardPendingOffersPreviewPlugIn.Event.DidSelectViewMore.Response) {
        let viewModel = DashboardPendingOffersPreviewPlugIn.Event.DidSelectViewMore.ViewModel()
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayDidSelectViewMore(viewModel: viewModel)
        }
    }
}
