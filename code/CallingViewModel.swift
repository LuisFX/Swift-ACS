import Combine
import PushKit
import CallKit
import AVFoundation
import AzureCommunicationCalling

class CallingViewModel: NSObject, ObservableObject {
    private static var sharedInstance: CallingViewModel?
    private(set) var callClient: CallClient?
    private(set) var callAgent: CallAgent?
    private(set) var call: Call?
    private(set) var deviceManager: DeviceManager?
    private(set) var localVideoStream: LocalVideoStream?
    private var pushRegistry: PKPushRegistry
    private var voIPToken: Data?

    @Published var hasCallAgent: Bool = false
    @Published var callState: CallState = CallState.none
    @Published var localVideoStreamModel: LocalVideoStreamModel?
    @Published var remoteVideoStreamModels: [RemoteVideoStreamModel] = []
    @Published var isLocalVideoStreamEnabled:Bool = false
    @Published var isMicrophoneMuted:Bool = false
    @Published var incomingCallPushNotification: IncomingCallPushNotification?
    @Published var callee: String = Constants.callee
    @Published var groupId: String = "29228d3e-040e-4656-a70e-890ab4e173e5"

    static func shared() -> CallingViewModel {
        if sharedInstance == nil {
            sharedInstance = CallingViewModel()

            // This is to initialize CallKit properly before requesting first outgoing/incoming call
            _ = CallKitManager.shared()
        }
        return sharedInstance!
    }

    override init() {
        callClient = CallClient()
        pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        super.init()
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [PKPushType.voIP]
    }

    func initCallAgent(communicationUserTokenModel: CommunicationUserTokenModel, displayName: String?, completion: @escaping (Bool) -> Void) {
        if let communicationUserId = communicationUserTokenModel.communicationUserId,
           let token = communicationUserTokenModel.token {
            do {
                let communicationTokenCredential = try CommunicationTokenCredential(token: token)
                let callAgentOptions = CallAgentOptions()
                callAgentOptions?.displayName = displayName ?? communicationUserId
                self.callClient?.createCallAgent(userCredential: communicationTokenCredential, options: callAgentOptions) { (callAgent, error) in
                    if self.callAgent != nil {
                        self.callAgent?.delegate = nil
                    }
                    self.callAgent = callAgent
                    self.callAgent?.delegate = self
                    self.hasCallAgent = true

                    print("CallAgent successfully created.\n")
                    completion(true)
                }
            } catch {
                print("Error: \(error.localizedDescription)")
                completion(false)
            }
        } else {
            print("Invalid communicationUserTokenModel.\n")
        }
    }

    func initPushNotification() {
        self.callAgent?.registerPushNotifications(deviceToken: self.voIPToken, completionHandler: { (error) in
            if(error == nil) {
                print("Successfully registered to VoIP push notification.\n")
            } else {
                print("Failed to register VoIP push notification.\(String(describing: error))\n")
            }
        })
    }

    func getCall(callId: UUID) -> Call? {
        if let call = self.call {
            print("incoming callId: \(call.callId.uppercased())")
            print("push callId: \(callId)")

            if let currentCallId = UUID(uuidString: call.callId) {
                if currentCallId == callId {
                    return call
                } else {
                    return nil
                }
            } else {
                print("Error parsing callId from currentCall.\n")
            }
        } else {
            print("call not exist in CallingViewModel!!!.\n")
        }
        return nil
    }

    func resetCallAgent() {
        if let callAgent = self.callAgent {
            unRegisterVoIP()
            callAgent.delegate = nil
            self.callAgent = nil
        } else {
            print("callAgent not found.\n")
        }
        self.hasCallAgent = false
    }

    func getDeviceManager(completion: @escaping (Bool) -> Void) {
        requestVideoPermission { success in
            if success {
                self.callClient?.getDeviceManager(completionHandler: { (deviceManager, error) in
                    if (error == nil) {
                        print("Got device manager instance")
                        self.deviceManager = deviceManager

                        if let videoDeviceInfo: VideoDeviceInfo = deviceManager?.getCameraList()?.first {
                            self.localVideoStream = LocalVideoStream(camera: videoDeviceInfo)
                            self.localVideoStreamModel = LocalVideoStreamModel(identifier: Constants.identifier, displayName: Constants.displayName)
                            print("LocalVideoStream instance initialized.")
                            completion(true)
                        } else {
                            print("LocalVideoStream instance initialize faile.")
                            completion(false)
                        }
                    } else {
                        print("Failed to get device manager instance: \(String(describing: error))")
                        completion(false)
                    }
                })
            } else {
                print("Permission denied.\n")
                completion(false)
            }
        }
    }

    // MARK: Request RecordPermission
    func requestRecordPermission(completion: @escaping (Bool) -> Void) {
        let audioSession = AVAudioSession.sharedInstance()
        switch audioSession.recordPermission {
        case .undetermined:
            audioSession.requestRecordPermission { granted in
                if granted {
                    completion(true)
                } else {
                    print("User did not grant audio permission")
                    completion(false)
                }
            }
        case .denied:
            print("User did not grant audio permission, it should redirect to Settings")
            completion(false)
        case .granted:
            completion(true)
        @unknown default:
            print("Audio session record permission unknown case detected")
            completion(false)
        }
    }

    // MARK: Request VideoPermission
    func requestVideoPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                if authorized {
                    completion(true)
                } else {
                    print("User did not grant video permission")
                    completion(false)
                }
            }
        case .restricted, .denied:
            print("User did not grant video permission, it should redirect to Settings")
            completion(false)
        case .authorized:
            completion(true)
        @unknown default:
            print("AVCaptureDevice authorizationStatus unknown case detected")
            completion(false)
        }
    }

    // MARK: Configure AudioSession
    func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            if audioSession.category != .playAndRecord {
                try audioSession.setCategory(AVAudioSession.Category.playAndRecord,
                                             options: AVAudioSession.CategoryOptions.allowBluetooth)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            }
            if audioSession.mode != .voiceChat {
                try audioSession.setMode(.voiceChat)
            }
        } catch {
            print("Error configuring AVAudioSession: \(error.localizedDescription)")
        }
    }

    func startVideo(call: Call, localVideoStream: LocalVideoStream) -> Void {
        requestVideoPermission { success in
            if success {
                if let localVideoStreamModel = self.localVideoStreamModel {
                    call.startVideo(stream: localVideoStream) { error in
                        if error != nil {
                            print("LocalVideo failed to start.\n")
                        } else {
                            print("LocalVideo started successfully.\n")
                            localVideoStreamModel.createView(localVideoStream: localVideoStream)
                            self.isLocalVideoStreamEnabled = true
                        }
                    }
                }
            } else {
                print("Permission denied.\n")
            }
        }
    }

    func stopVideo(competion: @escaping (Bool) -> Void) {
        if let call = self.call {
            call.stopVideo(stream: self.localVideoStream) { error in
                if error != nil {
                    print("LocalVideo failed to stop.\n")
                    competion(false)
                } else {
                    print("LocalVideo stopped successfully.\n")
                    if self.localVideoStreamModel != nil {
                        self.isLocalVideoStreamEnabled = false
                    }
                    competion(true)
                }
            }
        }
    }

    func stopVideo() {
        self.stopVideo { success in
            if success {
                self.localVideoStreamModel?.renderer?.dispose()
                self.localVideoStreamModel?.renderer = nil
                self.localVideoStreamModel?.videoStreamView = nil
            }
        }
    }

    func joinGroup() {
        requestRecordPermission { success in
            guard success else {
                print("recordPermission not authorized.")
                return
            }

            if let callAgent = self.callAgent {
                let groupCallLocator = GroupCallLocator(groupId: UUID(uuidString: self.groupId))
                let joinCallOptions = JoinCallOptions()

                self.getDeviceManager { _ in
                    if let localVideoStream = self.localVideoStream {
                        let videoOptions = VideoOptions(localVideoStream: localVideoStream)

                        joinCallOptions?.videoOptions = videoOptions

                        self.call = callAgent.join(with: groupCallLocator, joinCallOptions: joinCallOptions)

                        self.call?.delegate = self
                        self.startVideo(call: self.call!, localVideoStream: localVideoStream)
                        CallKitManager.shared().startOutgoingCall(call: self.call!, callerDisplayName: Constants.displayName)
                        print("outgoing call started.")
                    } else {
                        self.call = self.callAgent?.join(with: groupCallLocator, joinCallOptions: joinCallOptions)
                        CallKitManager.shared().startOutgoingCall(call: self.call!, callerDisplayName: Constants.displayName)
                        self.call?.delegate = self
                        print("outgoing call started.")
                    }
                }
            } else {
                print("callAgent not initialized.\n")
            }
        }
    }

    func startCall() {
        requestRecordPermission { success in
            guard success else {
                print("recordPermission not authorized.")
                return
            }

            if let callAgent = self.callAgent {
                let callees:[CommunicationUserIdentifier] = [CommunicationUserIdentifier(identifier: self.callee)]
                let startCallOptions = StartCallOptions()

                self.getDeviceManager { _ in
                    if let localVideoStream = self.localVideoStream {
                        let videoOptions = VideoOptions(localVideoStream: localVideoStream)
                        startCallOptions?.videoOptions = videoOptions

                        self.call = callAgent.call(participants: callees, options: startCallOptions)
                        self.call?.delegate = self
                        self.startVideo(call: self.call!, localVideoStream: localVideoStream)
                        CallKitManager.shared().startOutgoingCall(call: self.call!, callerDisplayName: Constants.displayName)
                        print("outgoing call started.")
                    } else {
                        self.call = callAgent.call(participants: callees, options: startCallOptions)
                        CallKitManager.shared().startOutgoingCall(call: self.call!, callerDisplayName: Constants.displayName)
                        self.call?.delegate = self
                        print("outgoing call started.")
                    }
                }
            } else {
                print("callAgent not initialized.\n")
            }
        }
    }

    // Accept incoming call
    func acceptCall(callId: UUID, completion: @escaping (Bool) -> Void) {
        if self.incomingCallPushNotification == nil {
            self.requestRecordPermission { authorized in
                if authorized {
                    if let call = self.getCall(callId: callId) {
                        let acceptCallOptions = AcceptCallOptions()

                        self.getDeviceManager { _ in
                            if let localVideoStream = self.localVideoStream {
                                let videoOptions = VideoOptions(localVideoStream: localVideoStream)
                                acceptCallOptions?.videoOptions = videoOptions
                                // MARK: startVideo when connection has made
                                self.startVideo(call: call, localVideoStream: localVideoStream)
                            }

                            call.accept(options: acceptCallOptions) { error in
                                if let error = error {
                                    print("Failed to accpet incoming call: \(error.localizedDescription)\n")
                                    completion(false)
                                } else {
                                    print("Incoming call accepted with acceptCallOptions.\n")
                                    completion(true)
                                }
                            }
                        }
                    } else {
                        print("Call not found when trying to accept.\n")
                        completion(false)
                    }
                } else {
                    print("recordPermission not authorized.")
                }
            }
        } else {
            print("incomingCallPushNotification not processed yet")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self.incomingCallPushNotification = nil
                self.acceptCall(callId: callId) { _ in }
            }
        }
    }

    func endCall() -> Void {
        print("endCall requested from App.\n")
        if let call = self.call {
            call.hangup(options: HangupOptions()) { error in
                if let error = error {
                    print("hangup failed: \(error.localizedDescription).\n")
                } else {
                    print("hangup succeed.\n")
                }
            }
        } else {
            print("Call not found.\n")
        }
    }

    func endCall(callId: UUID, completion: @escaping (Bool) -> Void) {
        print("endCall requested from CallKit.\n")
        if let call = self.getCall(callId: callId) {
            call.hangup(options: HangupOptions()) { error in
                if let error = error {
                    print("hangup failed: \(error.localizedDescription).\n")
                    completion(false)
                } else {
                    print("hangup succeed.\n")
                    completion(true)
                }
            }
        } else {
            print("Call not found when trying to hangup.\n")
            completion(false)
        }
    }

    func mute() {
        if let call = self.call {
            if call.isMicrophoneMuted {
                call.unmute(completionHandler:{ (error) in
                    if error == nil {
                        print("Successfully un-muted")
                        self.isMicrophoneMuted = false
                    } else {
                        print("Failed to unmute")
                    }
                })
            } else {
                call.mute(completionHandler: { (error) in
                    if error == nil {
                        print("Successfully muted")
                        self.isMicrophoneMuted = true
                    } else {
                        print("Failed to mute")
                    }
                })
            }
        }
    }

    func toggleVideo() {
        if let call = self.call,
           let localVideoStream = self.localVideoStream {
            if isLocalVideoStreamEnabled {
                stopVideo()
            } else {
                startVideo(call: call, localVideoStream: localVideoStream)
            }
        }
    }
}