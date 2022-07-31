import SwiftUI

@main
struct AzureCommunicationVideoCallingSampleApp: App {

    init() {
        // Fill in DevSettings.plist for AzureNotificationHubs hubName and connectionString.
        Constants.hubName = getPlistInfo(resourceName: "DevSettings", key: "HUB_NAME")
        Constants.connectionString = getPlistInfo(resourceName: "DevSettings", key: "CONNECTION_STRING")

        // Fill in FirstUser.plist with displayName, identifier, token and receiver identifier to test call feature.
        // Change resouceName to "FirstUser" or "SecondUser" to deploy different credentials.
        let resourceName = "FirstUser"
        Constants.displayName = getPlistInfo(resourceName: resourceName, key: "DISPLAYNAME")
        Constants.identifier = getPlistInfo(resourceName: resourceName, key: "IDENTIFIER")
        Constants.token = getPlistInfo(resourceName: resourceName, key: "TOKEN")
        Constants.callee = getPlistInfo(resourceName: resourceName, key: "CALLEE")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}