import Foundation
import RxSwift
import RxCocoa

protocol TransactionDetailsBusinessLogic {
    func onViewDidLoad(request: TransactionDetails.Event.ViewDidLoad.Request)
    func onTransactionAction(request: TransactionDetails.Event.TransactionAction.Request)
    func onSelectedCell(request: TransactionDetails.Event.SelectedCell.Request)
}

extension TransactionDetails {
    typealias BusinessLogic = TransactionDetailsBusinessLogic
    
    class Interactor {
        
        private var sceneModel: Model.SceneModel
        private let presenter: PresentationLogic
        private let sectionsProvider: SectionsProviderProtocol
        private let disposeBag: DisposeBag = DisposeBag()
        
        init(
            sectionsProvider: SectionsProviderProtocol,
            presenter: PresentationLogic,
            sceneModel: Model.SceneModel
            ) {
            self.sectionsProvider = sectionsProvider
            self.presenter = presenter
            self.sceneModel = sceneModel
        }
        
        // MARK: - Private
        
        private func observeTransaction() {
            self.presenter.presentTransactionUpdated(response: .loading)
            self.sectionsProvider
                .observeTransaction()
                .subscribe(onNext: { [weak self] (sectionModels) in
                    self?.onTransactionUpdate(sectionModels: sectionModels)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func onTransactionUpdate(sectionModels: [Model.SectionModel]) {
            self.presenter.presentTransactionUpdated(
                response: Event.TransactionUpdated.Response.loaded
            )
            self.sceneModel.sections = sectionModels
            self.presenter.presentTransactionUpdated(
                response: Event.TransactionUpdated.Response.succeeded(
                    self.sceneModel.sections
                )
            )
            let actions = self.sectionsProvider.getActions()
            let rightItems = actions.map { (action) -> Event.TransactionActionsDidUpdate.Action.Item in
                return Event.TransactionActionsDidUpdate.Action.Item(
                    id: action.id,
                    icon: action.icon,
                    title: action.title,
                    message: action.message
                )
            }
            let response = Event.TransactionActionsDidUpdate.Response(
                rightItems: rightItems
            )
            self.presenter.presentTransactionActionsDidUpdate(response: response)
        }
    }
}

extension TransactionDetails.Interactor: TransactionDetails.BusinessLogic {
    func onViewDidLoad(request: TransactionDetails.Event.ViewDidLoad.Request) {
        self.presenter.presentViewDidLoad(response: TransactionDetails.Event.ViewDidLoad.Response())
        self.observeTransaction()
    }
    
    func onTransactionAction(request: TransactionDetails.Event.TransactionAction.Request) {
        self.sectionsProvider.performActionWithId(
            request.id,
            onSuccess: { [weak self] in
                self?.presenter.presentTransactionAction(response: .success)
            },
            onShowLoading: { [weak self] in
                self?.presenter.presentTransactionAction(response: .loading)
            },
            onHideLoading: { [weak self] in
                self?.presenter.presentTransactionAction(response: .loaded)
            },
            onError: { [weak self] (error) in
                self?.presenter.presentTransactionAction(response: .error(error))
        })
    }
    
    func onSelectedCell(request: TransactionDetails.Event.SelectedCell.Request) {
        guard let detailsModel = request.model as? TransactionDetailsCell.Model else {
            return
        }
        switch detailsModel.identifier {
            
        case .recipient, .sender:
            UIPasteboard.general.string = detailsModel.title
            let response = TransactionDetails.Event.SelectedCell.Response(
                message: Localized(.address_is_copied_to_pasteboard)
            )
            self.presenter.presentSelectedCell(response: response)
            
        default:
            break
        }
    }
}
