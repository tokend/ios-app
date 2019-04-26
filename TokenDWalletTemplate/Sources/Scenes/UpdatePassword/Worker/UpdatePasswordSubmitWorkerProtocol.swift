import UIKit

enum UpdatePasswordSubmitResult {
    typealias SubmitError = Error
    
    case failed(UpdatePassword.Event.SubmitAction.Response.ErrorModel)
    case succeeded
}

protocol UpdatePasswordSubmitWorkerProtocol {
    typealias Result = UpdatePasswordSubmitResult 
    
    func submitFields(
        _ fields: [UpdatePassword.Model.Field],
        startLoading: @escaping () -> Void,
        stopLoading: @escaping () -> Void,
        completion: @escaping (_ result: UpdatePasswordSubmitWorkerProtocol.Result) -> Void
    )
}

extension UpdatePassword {
    typealias SubmitPasswordHandler = UpdatePasswordSubmitWorkerProtocol
}
