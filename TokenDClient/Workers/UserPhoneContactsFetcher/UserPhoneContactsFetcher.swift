import UIKit
import Contacts

class UserPhoneContactsFetcher {
    
    // MARK: - Private properties
    
    private let store = CNContactStore()
}

// MARK: - Private methods

extension UserPhoneContactsFetcher: UserPhoneContactsFetcherProtocol {
    
    func getContactsList() throws -> [Contact] {
        
        var contacts: [Contact] = []
        
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey,
            CNContactImageDataAvailableKey,
            CNContactThumbnailImageDataKey
        ]
        
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        
        do {
            try self.store.enumerateContacts(
                with: request,
                usingBlock: { (contact, stopPointer) in
                    
                    let mappedContacts = contact.mapToContactsModel()
                    contacts.append(contentsOf: mappedContacts)
                }
            )
        } catch let error {
            throw error
        }
        
        return contacts
    }
}

// MARK: - Private methods

private extension CNContact {
    
    enum MapToContactError: Swift.Error {
        case emptyContact
    }
    
    func mapToContactsModel(
    ) -> [Contact] {

        phoneNumbers.map { (phoneNumber) -> Contact in
            var avatar: UIImage? = nil
            if let image = self.thumbnailImageData {
                avatar = UIImage(data: image)
            }

            let phone = phoneNumber.value.stringValue

            return .init(
                id: [self.identifier, phone].joined(),
                avatar: avatar,
                firstName: self.givenName,
                lastName: self.familyName,
                phoneNumber: phone
            )
        }
    }
}
