extension CallKitManager: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        print("providerDidReset")
    }

    func providerDidBegin(_: CXProvider) {}

    func provider(_: CXProvider, perform action: CXStartCallAction) {
        action.fulfill()
    }

    func provider(_: CXProvider, perform action: CXAnswerCallAction) {
        action.fulfill()
    }

    func provider(_: CXProvider, perform action: CXEndCallAction) {
        action.fulfill()
    }

    func provider(_: CXProvider, perform action: CXSetHeldCallAction) {
        action.fulfill()
    }

    func provider(_: CXProvider, perform action: CXSetMutedCallAction) {
        action.fulfill()
    }

    func provider(_: CXProvider, timedOutPerforming _: CXAction) {}

    func provider(_: CXProvider, didActivate _: AVAudioSession) {}

    func provider(_: CXProvider, didDeactivate _: AVAudioSession) {}
}