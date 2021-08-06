import Foundation

public protocol SettingsScenePresentationLogic {
    
    typealias Event = SettingsScene.Event
    
    func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response)
    func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response)
    func presentDidTapItemSync(response: Event.DidTapItemSync.Response)
    func presentErrorOccured(response: Event.ErrorOccured.Response)
}

extension SettingsScene {
    
    public typealias PresentationLogic = SettingsScenePresentationLogic
    
    @objc(SettingsScenePresenter)
    public class Presenter: NSObject {
        
        public typealias Event = SettingsScene.Event
        public typealias Model = SettingsScene.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        
        // MARK: -
        
        public init(
            presenterDispatch: PresenterDispatch
        ) {
            
            self.presenterDispatch = presenterDispatch
        }
    }
}

// MARK: - Private methods

private extension SettingsScene.Presenter {
    
    func mapSceneModel(_ sceneModel: Model.SceneModel) -> Model.SceneViewModel {
        
        var sections: [Model.Section] = []
        
        for section in sceneModel.sections {
            var cells: [CellViewAnyModel] = []
            
            for item in section.items {
                
                switch item {
                
                case .language:
                    cells.append(
                        IconTitleDescriptionDisclosureCell.ViewModel(
                            id: item.rawValue,
                            icon: .uiImage( Assets.settings_language_icon.image),
                            title: Localized(.settings_app_language),
                            description: sceneModel.preferredLanguage
                        )
                    )
                    
                    sections.append(
                        Model.Section(
                            id: section.id,
                            header: CommonHeaderView.ViewModel(
                                id: "\(section.id)Header",
                                title: Localized(.settings_app_title).uppercased()
                            ),
                            footer: nil,
                            cells: cells
                        )
                    )
                    cells = []
                    
                case .accountId:
                    cells.append(
                        IconTitleDisclosureCell.ViewModel(
                            id: item.rawValue,
                            icon: .uiImage(Assets.settings_account_id_icon.image),
                            title: Localized(.settings_account_account_id)
                        )
                    )
                    
                case .verification:
                    cells.append(
                        IconTitleDisclosureCell.ViewModel(
                            id: item.rawValue,
                            icon: .uiImage(Assets.settings_verification_icon.image),
                            title: Localized(.settings_account_verification)
                        )
                    )
                    sections.append(
                        Model.Section(
                            id: section.id,
                            header: CommonHeaderView.ViewModel(
                                id: "\(section.id)Header",
                                title: Localized(.settings_account_title).uppercased()
                            ),
                            footer: CommonFooterView.ViewModel(
                                id: "\(section.id)Footer",
                                title: Localized(.settings_account_verification_description)
                            ),
                            cells: cells
                        )
                    )
                    cells = []
                
                case .secretSeed:
                    cells.append(
                        IconTitleDisclosureCell.ViewModel(
                            id: item.rawValue,
                            icon: .uiImage(Assets.settings_secret_seed_icon.image),
                            title: Localized(.settings_account_secret_seed)
                        )
                    )
                    sections.append(
                        Model.Section(
                            id: section.id,
                            header: nil,
                            footer: CommonFooterView.ViewModel(
                                id: "\(section.id)Footer",
                                title: Localized(.settings_account_secret_seed_description)
                            ),
                            cells: cells
                        )
                    )
                    cells = []

                case .signOut:
                    cells.append(
                        IconTitleDisclosureCell.ViewModel(
                            id: item.rawValue,
                            icon: .uiImage(Assets.settings_sign_out_icon.image),
                            title: Localized(.settings_account_sign_out)
                        )
                    )
                    sections.append(
                        Model.Section(
                            id: section.id,
                            header: nil,
                            footer: nil,
                            cells: cells
                        )
                    )
                    cells = []
                    
                case .lockApp:
                    cells.append(
                        SettingsScene.SwitcherCell.ViewModel(
                            id: item.rawValue,
                            icon: .uiImage(Assets.settings_lock_app_icon.image),
                            title: Localized(.settings_security_lock_app),
                            switcherStatus: sceneModel.lockAppIsEnabled,
                            isLoading: false
                        )
                    )
                    
                case .biometrics:
                    
                    switch sceneModel.biometricsType {
                    
                    case .faceId:
                        cells.append(
                            SettingsScene.SwitcherCell.ViewModel(
                                id: item.rawValue,
                                icon: .uiImage(Assets.face_id_icon.image),
                                title: Localized(.face_id_title),
                                switcherStatus: sceneModel.biometricsIsEnabled,
                                isLoading: false
                            )
                        )
                        
                    case .touchId:
                        cells.append(
                            SettingsScene.SwitcherCell.ViewModel(
                                id: item.rawValue,
                                icon: .uiImage(Assets.touch_id_icon.image),
                                title: Localized(.touch_id_title),
                                switcherStatus: sceneModel.biometricsIsEnabled,
                                isLoading: false
                            )
                        )
                    case .none:
                        break
                    }
                    
                case .tfa:
                    
                    switch sceneModel.tfaStatus {
                    
                    case .loaded(enabled: let enabled):
                        cells.append(
                            SettingsScene.SwitcherCell.ViewModel(
                                id: item.rawValue,
                                icon: .uiImage(Assets.settings_tfa_icon.image),
                                title: Localized(.settings_security_tfa),
                                switcherStatus: enabled,
                                isLoading: false
                            )
                        )
                        
                    case .loading:
                        cells.append(
                            SettingsScene.SwitcherCell.ViewModel(
                                id: item.rawValue,
                                icon: .uiImage(Assets.settings_tfa_icon.image),
                                title: Localized(.settings_security_tfa),
                                switcherStatus: false,
                                isLoading: true
                            )
                        )
                        
                    case .undetermined,
                        .failed:
                        break
                    }
                    
                case .changePassword:
                    cells.append(
                        IconTitleDisclosureCell.ViewModel(
                            id: item.rawValue,
                            icon: .uiImage(Assets.settings_change_password_icon.image),
                            title: Localized(.settings_security_change_password)
                        )
                    )
                    
                    sections.append(
                        Model.Section(
                            id: section.id,
                            header: CommonHeaderView.ViewModel(
                                id: "\(section.id)Header",
                                title: Localized(.settings_security_title).uppercased()
                            ),
                            footer: nil,
                            cells: cells
                        )
                    )
                    cells = []
                }
            }
        }
        
        return .init(
            isLoading: sceneModel.loadingStatus == .loading,
            content: .content(sections: sections)
        )
    }
}

// MARK: - PresenterLogic

extension SettingsScene.Presenter: SettingsScene.PresentationLogic {
    
    public func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response) {
        let viewModel = mapSceneModel(response.sceneModel)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySceneDidUpdate(
                viewModel: .init(
                    viewModel: viewModel,
                    animated: response.animated
                )
            )
        }
    }
    
    public func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response) {
        let viewModel = mapSceneModel(response.sceneModel)
        self.presenterDispatch.displaySync { (displayLogic) in
            displayLogic.displaySceneDidUpdateSync(
                viewModel: .init(
                    viewModel: viewModel,
                    animated: response.animated
                )
            )
        }
    }
    
    public func presentDidTapItemSync(response: Event.DidTapItemSync.Response) {
        presenterDispatch.displaySync { (displayLogic) in
            displayLogic.displayDidTapItemSync(viewModel: response)
        }
    }
    
    public func presentErrorOccured(response: Event.ErrorOccured.Response) {
        let viewModel: Event.ErrorOccured.ViewModel = response
        presenterDispatch.display { (displayLogic) in
            displayLogic.displayErrorOccured(viewModel: viewModel)
        }
    }
}
