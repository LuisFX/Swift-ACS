extension CallingViewModel: CallAgentDelegate {
    func onCallsUpdated(_ callAgent: CallAgent!, args: CallsUpdatedEventArgs!) {
        print("\n---------------")
        print("onCallsUpdated")
        print("---------------\n")

        if let addedCall = args.addedCalls?.first(where: {$0.isIncoming }) {
            print("addedCalls: \(args.addedCalls.count)")
            self.call = addedCall
            self.call?.delegate = self
            self.callState = addedCall.state
            self.isMicrophoneMuted = addedCall.isMicrophoneMuted
        }

        if let removedCall = args.removedCalls?.first {
            print("removedCalls: \(args.removedCalls.count)\n")
            let removedCallUUID = UUID(uuidString: removedCall.callId)
            // MARK: report CallKitManager for endCall.
            CallKitManager.shared().reportCallEndedFromRemote(callId: removedCallUUID!, reason: CXCallEndedReason.remoteEnded)

            if let call = self.call {
                print("call removed.\n")
                if call.callId == removedCall.callId {
                    self.callState = removedCall.state
                    self.call?.delegate = nil
                    self.call = nil
                }
            } else {
                print("\ncall removed before initizliaztion.\n")
            }
        } else {
            print("removedCall: \(String(describing: args.removedCalls))")
            if let incomingCallPushNotification = self.incomingCallPushNotification {
                CallKitManager.shared().reportCallEndedFromRemote(callId: incomingCallPushNotification.callId, reason: CXCallEndedReason.remoteEnded)
            }
        }
    }
}