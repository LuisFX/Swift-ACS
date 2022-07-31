import SwiftUI
import AzureCommunicationCalling

class LocalVideoStreamModel: VideoStreamModel {
    public func createView(localVideoStream: LocalVideoStream?) {
        do {
            if let localVideoStream = localVideoStream {
                let renderer = try Renderer(localVideoStream: localVideoStream)
                self.renderer = renderer
                self.videoStreamView = VideoStreamView(view: (try renderer.createView()))
            }
        } catch {
            print("Failed starting VideoStreamView for \(String(describing: displayName)) : \(error.localizedDescription)")
        }
    }
}