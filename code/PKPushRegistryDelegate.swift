extension CallingViewModel: PKPushRegistryDelegate {
    func unRegisterVoIP() {
        self.callAgent?.unRegisterPushNotifications(completionHandler: { (error) in
            if (error != nil) {
                print("Register of push notification failed, please try again.\n")
            } else {
                print("Unregister of push notification was successful.\n")
            }
        })
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let deviceToken = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
                print("pushRegistry -> deviceToken :\(deviceToken)")

        self.voIPToken = pushCredentials.token
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("pusRegistry invalidated.")
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        let dictionaryPayload = payload.dictionaryPayload
        print("dictionaryPayload: \(dictionaryPayload)")

        if type == .voIP {
            if let incomingCallPushNotification = IncomingCallPushNotification.fromDictionary(payload.dictionaryPayload) {
                self.configureAudioSession()
                CallKitManager.shared().reportNewIncomingCall(incomingCallPushNotification: incomingCallPushNotification) { success in
                    if success {
                        print("Handling of report incoming call was succesful.\n")
                        completion()
                    } else {
                        print("Handling of report incoming call failed.\n")
                        completion()
                    }
                }

                if self.callAgent == nil {
                    self.incomingCallPushNotification = incomingCallPushNotification

                    print("CallAgent not found.\nConnecting to Communication Services...\n")
                    // MARK: generate communicationUserToken from stored data.
                    let token = Constants.token
                    let identifier = Constants.identifier
                    let displayName = Constants.displayName

                    if !token.isEmpty && !identifier.isEmpty {
                        let communicationUserToken = CommunicationUserTokenModel(token: token, expiresOn: nil, communicationUserId: identifier)
                        self.initCallAgent(communicationUserTokenModel: communicationUserToken, displayName: displayName) { (success) in
                            if success {
                                self.initPushNotification()

                                self.callAgent?.handlePush(notification: incomingCallPushNotification, completionHandler: { error in
                                    if (error != nil) {
                                        print("Handling of push notification to call failed: \(error.debugDescription)\n")
                                    } else {
                                        print("Handling of push notification to call was successful.\n")
                                        self.incomingCallPushNotification = nil
                                    }
                                })
                            } else {
                                print("initCallAgent failed.\n")
                            }
                        }
                    } else {
                        // MARK: no token found, unregister push notification when signing out.
                        print("No token found,\n")
                    }
                }
            }
        } else {
            print("Pushnotification is not type of voIP.\n")
        }
    }
}