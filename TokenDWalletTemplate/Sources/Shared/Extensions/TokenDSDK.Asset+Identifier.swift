import Foundation
import TokenDSDK

extension TokenDSDK.Asset {
    var identifier: ExploreTokensScene.TokenIdentifier {
        return self.code + (self.defaultDetails?.name ?? "")
    }
}
