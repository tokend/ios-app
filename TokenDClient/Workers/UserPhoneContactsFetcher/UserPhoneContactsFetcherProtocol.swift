import UIKit
import Contacts

public protocol UserPhoneContactsFetcherProtocol {
    
    func getContactsList() throws -> [Contact]
}

public struct Contact {
    let id: String
    let avatar: UIImage?
    let firstName: String
    let lastName: String
    let phoneNumber: String
}
