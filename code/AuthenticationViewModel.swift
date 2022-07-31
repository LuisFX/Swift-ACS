import Combine
import AzureCommunicationCalling

class AuthenticationViewModel: ObservableObject {
    @Published var currentTab: Tab = .home
    @Published var isAuthenticating = false
    @Published var signInRequired = false
    @Published var error: String?

    @Published var email = ""
    @Published var password = ""
    @Published var identifier = Constants.identifier
    @Published var token = Constants.token
    @Published var displayName = Constants.displayName

    func getCommunicationUserToken() -> CommunicationUserTokenModel? {
        isAuthenticating = true
        // MARK: modify below to get token from auth server.
        if !Constants.token.isEmpty && !Constants.identifier.isEmpty {
            let communicationUserTokenModel = CommunicationUserTokenModel(token: Constants.token, expiresOn: nil, communicationUserId: Constants.identifier)
            isAuthenticating = false
            return communicationUserTokenModel
        }

        isAuthenticating = false
        return nil
    }
}