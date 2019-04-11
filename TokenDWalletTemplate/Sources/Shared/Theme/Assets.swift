import UIKit

enum Assets: String {
    case addIcon = "Add icon"
    case checkmark = "Checkmark"
    case closeIcon = "Close icon"
    case copyright = "Copyright"
    case dashboardIcon = "Dashboard icon"
    case delete = "Delete"
    case depositAction = "Deposit action"
    case depositIcon = "Deposit icon"
    case documentIcon = "Document icon"
    case exploreFundsIcon = "Explore funds icon"
    case exploreTokensIcon = "Explore tokens icon"
    case faceIdIcon = "Face ID icon"
    case fee = "Fee"
    case filledStarIcon = "Filled star icon"
    case flashLightIcon = "Flash Light icon"
    case icon = "Icon"
    case incoming = "Incoming"
    case inviteAFriendIcon = "Invite a friend icon"
    case lock = "Lock"
    case match = "Match"
    case menuIcon = "Menu icon"
    case outgoing = "Outgoing"
    case passwordIcon = "Password icon"
    case paymentAction = "Payment action"
    case pendingIcon = "Pending icon"
    case placeHolderIcon = "Place holder icon"
    case plusIcon = "Plus icon"
    case receive = "Receive"
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
    case unlock = "Unlock"
    case upcomingImage = "Upcoming image"
    case verificationIcon = "Verification icon"
    case walletIcon = "Wallet icon"
    case withdrawAction = "Withdraw action"
    case withdrawIcon = "Withdraw icon"
}

extension Assets {
    
    public var image: UIImage {
        return UIImage(imageLiteralResourceName: self.rawValue)
    }
}
