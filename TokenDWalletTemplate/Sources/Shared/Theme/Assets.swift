import UIKit

enum Assets: String {
    case addIcon = "Add icon"
    case checkmark = "Checkmark"
    case closeIcon = "Close icon"
    case copyright = "Copyright"
    case dashboardIcon = "Dashboard icon"
    case depositIcon = "Deposit icon"
    case documentIcon = "Document icon"
    case exploreFundsIcon = "Explore funds icon"
    case exploreTokensIcon = "Explore tokens icon"
    case faceIdIcon = "Face ID icon"
    case fee = "Fee"
    case filledStarIcon = "Filled star icon"
    case flashLightIcon = "Flash Light icon"
    case icon = "Icon"
    case incomeIcon = "Income icon"
    case inviteAFriendIcon = "Invite a friend icon"
    case lock = "Lock icon"
    case match = "Match icon"
    case menuIcon = "Menu icon"
    case outcomeIcon = "Outcome icon"
    case passwordIcon = "Password icon"
    case pendingIcon = "Pending icon"
    case placeHolderIcon = "Place holder icon"
    case plusIcon = "Plus icon"
    case scanQrIcon = "Scan QR icon"
    case securityIcon = "Security icon"
    case seed = "Seed"
    case send = "Send"
    case sendIcon = "Send icon"
    case settingsIcon = "Settings icon"
    case shareIcon = "Share icon"
    case signOutIcon = "Sign out icon"
    case starIcon = "Star icon"
    case timeIcon = "Time icon"
    case touchIdIcon = "Touch ID icon"
    case tradeIcon = "Trade icon"
    case unlock = "Unlock icon"
    case upcomingImage = "Upcoming image"
    case verificationIcon = "Verification icon"
    case walletIcon = "Wallet icon"
    case withdrawIcon = "Withdraw icon"
}

extension Assets {
    
    public var image: UIImage {
        return UIImage(imageLiteralResourceName: self.rawValue)
    }
}
