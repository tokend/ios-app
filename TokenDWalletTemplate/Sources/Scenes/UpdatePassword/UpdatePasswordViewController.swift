import RxCocoa
import RxSwift
import SnapKit
import UIKit

protocol UpdatePasswordDisplayLogic: class {
    func displayViewDidLoadSync(viewModel: UpdatePassword.Event.ViewDidLoadSync.ViewModel)
    func displaySubmitAction(viewModel: UpdatePassword.Event.SubmitAction.ViewModel)
}

extension UpdatePassword {
    typealias DisplayLogic = UpdatePasswordDisplayLogic
    
    class ViewController: UIViewController {
        
        // MARK: - Private properties
        
        private let contentView: View = View()
        
        private let disposeBag = DisposeBag()
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        
        func inject(interactorDispatch: InteractorDispatch?, routing: Routing?) {
            self.interactorDispatch = interactorDispatch
            self.routing = routing
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupContentView()
            self.setupSubmitButton()
            self.setupLayout()
            
            self.view.backgroundColor = Theme.Colors.contentBackgroundColor
            let request = UpdatePassword.Event.ViewDidLoadSync.Request()
            self.interactorDispatch?.sendSyncRequest { businessLogic in
                businessLogic.onViewDidLoadSync(request: request)
            }
        }
        
        // MARK: - Private
        
        private func setupViewWithFields(_ fields: [View.Field]) {
            self.contentView.setupFields(fields)
        }
        
        private func setupContentView() {
            self.contentView.onEditField = { [weak self] fieldType, text in
                let request = UpdatePassword.Event.FieldEditing.Request(fieldType: fieldType, text: text)
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onFieldEditing(request: request)
                })
            }
        }
        
        private func setupSubmitButton() {
            let button = UIBarButtonItem(image: #imageLiteral(resourceName: "Checkmark"), style: .plain, target: nil, action: nil)
            button.rx
                .tap
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.view.endEditing(true)
                    let request = Event.SubmitAction.Request()
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onSubmitAction(request: request)
                    })
                })
                .disposed(by: self.disposeBag)
            self.navigationItem.rightBarButtonItem = button
        }
        
        private func setupLayout() {
            self.view.addSubview(self.contentView)
            self.contentView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }
}

extension UpdatePassword.ViewController: UpdatePassword.DisplayLogic {
    func displayViewDidLoadSync(viewModel: UpdatePassword.Event.ViewDidLoadSync.ViewModel) {
        self.setupViewWithFields(viewModel.fields)
    }
    
    func displaySubmitAction(viewModel: UpdatePassword.Event.SubmitAction.ViewModel) {
        switch viewModel {
        case .loading:
            self.routing?.onShowProgress()
            
        case .loaded:
            self.routing?.onHideProgress()
            
        case .failed(let errorModel):
            self.routing?.onShowErrorMessage(errorModel.message)
            
        case .succeeded:
            self.routing?.onSubmitSucceeded()
        }
    }
}
