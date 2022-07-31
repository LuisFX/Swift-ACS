extension CallingViewModel: CallDelegate {
    func onCallStateChanged(_ call: Call!, args: PropertyChangedEventArgs!) {
        print("\n----------------------------------")
        print("onCallStateChanged: \(String(reflecting: call.state))")
        print("----------------------------------\n")
        self.callState = call.state

        if call.state == .connected {
//            if let localVideoStream = self.localVideoStream {
//                self.startVideo(call: call, localVideoStream: localVideoStream)
//            }
        }

        if call.state == .disconnected || call.state == .none {
            self.stopVideo()
            self.remoteVideoStreamModels.forEach({ (remoteVideoStreamModel) in
                remoteVideoStreamModel.renderer?.dispose()
                remoteVideoStreamModel.videoStreamView = nil
                remoteVideoStreamModel.remoteParticipant?.delegate = nil
            })
            self.remoteVideoStreamModels = []
        }
    }

    func onRemoteParticipantsUpdated(_ call: Call!, args: ParticipantsUpdatedEventArgs!) {
        print("\n---------------------------")
        print("onRemoteParticipantsUpdated")
        print("---------------------------\n")

        if let addedParticipants = args.addedParticipants {
            if addedParticipants.count > 0 {
                print("addedParticipants: \(String(describing: args.addedParticipants.count))")

                addedParticipants.forEach { (remoteParticipant) in
                    if remoteParticipant.identity is CommunicationUserIdentifier {
                        let communicationUserIdentifier = remoteParticipant.identity as! CommunicationUserIdentifier
                        print("addedParticipant identifier:  \(String(describing: communicationUserIdentifier))")
                        print("addedParticipant displayName \(String(describing: remoteParticipant.displayName))")
                        print("addedParticipant streams \(String(describing: remoteParticipant.videoStreams.count))")

                        let remoteVideoStreamModel = RemoteVideoStreamModel(identifier: communicationUserIdentifier.identifier, displayName: remoteParticipant.displayName, remoteParticipant: remoteParticipant)
                        remoteVideoStreamModels.append(remoteVideoStreamModel)
                    }
                }
            }
        }

        if let removedParticipants = args.removedParticipants {
            if removedParticipants.count > 0 {
                print("removedParticipants: \(String(describing: args.removedParticipants.count))")

                removedParticipants.forEach { (remoteParticipant) in
                    if remoteParticipant.identity is CommunicationUserIdentifier {
                        let communicationUserIdentifier = remoteParticipant.identity as! CommunicationUserIdentifier
                        print("removedParticipant identifier:  \(String(describing: communicationUserIdentifier))")
                        print("removedParticipant displayName \(String(describing: remoteParticipant.displayName))")

                        if let removedIndex = remoteVideoStreamModels.firstIndex(where: {$0.identifier == communicationUserIdentifier.identifier}) {
                            let remoteVideoStreamModel = remoteVideoStreamModels[removedIndex]
                            remoteVideoStreamModel.remoteParticipant?.delegate = nil
                            remoteVideoStreamModel.renderer?.dispose()
                            remoteVideoStreamModel.videoStreamView = nil
                            remoteVideoStreamModels.remove(at: removedIndex)
                        }
                    }
                }
            }
        }
    }

    func onLocalVideoStreamsChanged(_ call: Call!, args: LocalVideoStreamsUpdatedEventArgs!) {
        print("\n--------------------------")
        print("onLocalVideoStreamsChanged")
        print("--------------------------\n")

        if let addedStreams = args.addedStreams {
            print("addedStreams: \(addedStreams.count)")
        }

        if let removedStreams = args.removedStreams {
            print("removedStreams: \(removedStreams.count)")
        }
    }
}