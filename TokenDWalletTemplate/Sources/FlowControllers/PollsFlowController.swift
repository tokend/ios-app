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
        let balancesFetcher = Polls.BalancesFetcher(
            balancesRepo: self.reposController.balancesRepo
        )
        let pollsFetcher = Polls.PollsFetcher(reposController: reposController)
        
        let routing = Polls.Routing(
            onPresentPicker: { [weak self] (assets, onSelected) in
                self?.showAssetPicker(targetAssets: assets, onSelected: onSelected)
            },
            onPollSelected: {
                
        })
        
        Polls.Configurator.configure(
            viewController: vc,
            balancesFetcher: balancesFetcher,
            pollsFetcher: pollsFetcher,
            routing: routing
        )
        
        return vc
    }
    
    private func showAssetPicker(
        targetAssets: [String],
        onSelected: @escaping ((String) -> Void)
        ) {
        
        let navController = NavigationController()
        
        let vc = self.setupAssetPicker(
            targetAssets: targetAssets,
            onSelected: onSelected
        )
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
        targetAssets: [String],
        onSelected: @escaping ((String) -> Void)
        ) -> UIViewController {
        
        let vc = AssetPicker.ViewController()
        let imageUtility = ImagesUtility(
            storageUrl: self.flowControllerStack.apiConfigurationModel.storageEndpoint
        )
        let assetsFetcher = AssetPicker.AssetsFetcher(
            balancesRepo: self.reposController.balancesRepo,
            assetsRepo: self.reposController.assetsRepo,
            imagesUtility: imageUtility,
            targetAssets: targetAssets
        )
        let sceneModel = AssetPicker.Model.SceneModel(
            assets: [],
            filter: nil
        )
        let amountFormatter = AssetPicker.AmountFormatter()
        let routing = AssetPicker.Routing(
            onAssetPicked: { (balanceId) in
                onSelected(balanceId)
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
