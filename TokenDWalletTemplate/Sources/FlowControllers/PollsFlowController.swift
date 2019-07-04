import UIKit
import TokenDSDK
import RxSwift

class PollsFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol = NavigationController()
    private let disposeBag: DisposeBag = DisposeBag()
    
    // MARK: -
    
    // MARK: - Public
    
    public func run(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        self.showPollsScreen(showRootScreen: showRootScreen)
    }
    
    // MARK: - Private
    
    private func showPollsScreen(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        let vc = self.setupPollsScene()
        self.navigationController.setViewControllers([vc], animated: false)
        
        if let showRootScreen = showRootScreen {
            showRootScreen(self.navigationController.getViewController())
        } else {
            self.rootNavigation.setRootContent(
                self.navigationController,
                transition: .fade,
                animated: false
            )
        }
    }
    
    private func setupPollsScene() -> UIViewController {
        let vc = Polls.ViewController()
        let assetsFetcher = Polls.AssetsFetcher(
            assetsRepo: self.reposController.assetsRepo
        )
        let pollsFetcher = Polls.PollsFetcher(reposController: reposController)
        let percentFormatter = Polls.PercentFormatter()
        
        let voterWorker = Polls.VoteWorker(
            transactionSender: self.managersController.transactionSender,
            keychainDataProvider: self.keychainDataProvider,
            userDataProvider: self.userDataProvider,
            networkInfoFetcher: self.reposController.networkInfoRepo
        )
        
        let routing = Polls.Routing(
            onPresentPicker: { [weak self] (onSelected) in
                self?.showAssetPicker(onSelected: onSelected)
            },
            showError: { [weak self] (message) in
                self?.navigationController.showErrorMessage(message, completion: nil)
            }, showLoading: { [weak self] in
                self?.navigationController.showProgress()
            }, hideLoading: { [weak self] in
                self?.navigationController.hideProgress()
            })
        
        Polls.Configurator.configure(
            viewController: vc,
            assetsFetcher: assetsFetcher,
            pollsFetcher: pollsFetcher,
            percentFormatter: percentFormatter,
            voteWorker: voterWorker,
            routing: routing
        )
        
        return vc
    }
    
    private func showAssetPicker(onSelected: @escaping ((String, String) -> Void)) {
        let navController = NavigationController()
        
        let vc = self.setupAssetPicker(onSelected: onSelected)
        vc.navigationItem.title = Localized(.choose_asset)
        let closeBarItem = UIBarButtonItem(
            title: Localized(.back),
            style: .plain,
            target: nil,
            action: nil
        )
        closeBarItem
            .rx
            .tap
            .asDriver()
            .drive(onNext: { _ in
                navController
                    .getViewController()
                    .dismiss(animated: true, completion: nil)
            })
            .disposed(by: self.disposeBag)
        
        vc.navigationItem.leftBarButtonItem = closeBarItem
        navController.setViewControllers([vc], animated: false)
        
        self.navigationController.present(
            navController.getViewController(),
            animated: true,
            completion: nil
        )
    }
    
    private func setupAssetPicker(
        onSelected: @escaping ((String, String) -> Void)
        ) -> UIViewController {
        
        let vc = AssetPicker.ViewController()
        let imageUtility = ImagesUtility(
            storageUrl: self.flowControllerStack.apiConfigurationModel.storageEndpoint
        )
        let assetsFetcher = AssetPicker.AssetsFetcher(
            assetsRepo: self.reposController.assetsRepo,
            imagesUtility: imageUtility
        )
        let sceneModel = AssetPicker.Model.SceneModel(
            assets: [],
            filter: nil
        )
        let amountFormatter = AssetPicker.AmountFormatter()
        let routing = AssetPicker.Routing(
            onAssetPicked: { (ownerAccountId, assetCode) in
                onSelected(ownerAccountId, assetCode)
        })
        
        AssetPicker.Configurator.configure(
            viewController: vc,
            assetsFetcher: assetsFetcher,
            sceneModel: sceneModel,
            amountFormatter: amountFormatter,
            routing: routing
        )
        return vc
    }
}
