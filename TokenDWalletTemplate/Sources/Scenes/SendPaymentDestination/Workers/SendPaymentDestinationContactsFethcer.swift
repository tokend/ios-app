import Foundation
import Contacts

public enum SendPaymentDestinationContactsFetcherResult {
    case failure(FetchError)
    case success([SendPaymentDestination.Model.ContactModel])
    
    public enum FetchError: Error {
        case permissionIsNotGranted
        case other(Error)
    }
}
public protocol SendPaymentDestinationContactsFetcherProtocol {
    func fetchContacts(
        completion: @escaping(SendPaymentDestinationContactsFetcherResult) -> Void
    )
}

extension SendPaymentDestination {
    public typealias ContactsFetcherProtocol = SendPaymentDestinationContactsFetcherProtocol
    public typealias ContactsFetcherResult = SendPaymentDestinationContactsFetcherResult
    
    public class ContactsFetcher {
        
        // MARK: - Private properties
        
        private let contactStore: CNContactStore = CNContactStore()
        
        // MARK: - Private
        
        private func continueWithGrantedPermission(
            completion: @escaping (SendPaymentDestination.ContactsFetcherResult) -> Void
            ) {
            
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey]
            let request = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])
            var contacts: [Model.ContactModel] = []
            
            try? self.contactStore.enumerateContacts(
                with: request,
                usingBlock: { (contact, _) in
                    guard let email = contact.emailAddresses.first else {
                        return
                    }
                    let name = contact.givenName + " " + contact.familyName
                    let contactModel = Model.ContactModel(
                        name: name,
                        email: email.value as String
                    )
                    contacts.append(contactModel)
            })
            completion(.success(contacts))
        }
    }
}

extension SendPaymentDestination.ContactsFetcher: SendPaymentDestination.ContactsFetcherProtocol {
    
    public func fetchContacts(completion: @escaping (SendPaymentDestination.ContactsFetcherResult) -> Void) {
        self.contactStore.requestAccess(
            for: .contacts,
            completionHandler: { (permissionGranted, fetchingError) in
                if let error = fetchingError {
                    completion(.failure(.other(error)))
                    return
                } else if !permissionGranted {
                    completion(.failure(.permissionIsNotGranted))
                    return
                } else {
                    self.continueWithGrantedPermission(completion: completion)
                }
        })
    }
}
