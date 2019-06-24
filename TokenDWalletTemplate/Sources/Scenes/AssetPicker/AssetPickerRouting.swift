import Foundation

extension AssetPicker {
    public struct Routing {
        let onAssetPicked: (_ ownerAccountId: String, _ assetCode: String) -> Void
    }
}
