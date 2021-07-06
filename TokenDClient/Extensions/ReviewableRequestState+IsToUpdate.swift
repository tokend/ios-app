import TokenDSDK

extension ReviewableRequestState {

    var isToUpdate: Bool {

        switch self {

        case .approved,
             .canceled,
             .permanentlyRejected,
             .unknown:
            return false

        case .pending,
             .rejected:
            return true
        }
    }
}
