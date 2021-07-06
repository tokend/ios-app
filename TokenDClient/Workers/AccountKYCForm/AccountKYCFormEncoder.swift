import Foundation
import TokenDSDK

class AccountKYCFormEncoder {

    // MARK: - Private properties

    private let documentUploader: DocumentUploaderWorkerProtocol

    // MAKR: -

    init(
        documentUploader: DocumentUploaderWorkerProtocol
    ) {

        self.documentUploader = documentUploader
    }
}

// MARK: - Public methods

extension AccountKYCFormEncoder {

    enum EncodeKYCFormResult {
        case success(jsonString: String)
        case failure(Swift.Error)
    }
    enum EncodeKYCFormError: Swift.Error {
        case failedToFormJSON
    }
    func encodeKYCForm(
        _ form: AccountKYCForm,
        completion: @escaping (EncodeKYCFormResult) -> Void
    ) {

        var error: Swift.Error?
        let group: DispatchGroup = .init()
        
        group.enter()
        
        var newDocuments: [String: AccountKYCForm.KYCDocument] = form.documents
        
        for documentKey in newDocuments.keys {
            
            switch newDocuments[documentKey] {
            
            case .new(let image, let uploadPolicy):
                group.enter()
                documentUploader.upload(
                    image: image,
                    name: nil,
                    contentType: nil,
                    uploadPolicy: uploadPolicy,
                    completion: { (result) in
                        
                        switch result {
                        
                        case .failure(let avatarError):
                            error = avatarError
                            
                        case .success(let attachment):
                            newDocuments[documentKey] = .uploaded(attachment)
                        }
                        group.leave()
                    })
                
            case .uploaded,
                 .none:
                break
            }
        }

        group.notify(
            queue: .main,
            execute: {
                
                let kyc = form.update(with: newDocuments)

                if let error = error {
                    completion(.failure(error))
                } else {
                    do {
                        let kycFormJSONData = try kyc.encode()
                        guard let kycFormJSONString = String(
                            data: kycFormJSONData,
                            encoding: .utf8
                            )
                            else {
                                completion(.failure(EncodeKYCFormError.failedToFormJSON))
                                return
                        }
                        completion(.success(jsonString: kycFormJSONString))
                    } catch (let error) {
                        completion(.failure(error))
                    }
                }
        })
        group.leave()
    }
}
