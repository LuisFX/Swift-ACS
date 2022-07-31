func notificationHub(_ notificationHub: MSNotificationHub, didSave installation: MSInstallation) {
      DispatchQueue.main.async {
          self.installationId = installation.installationId
          self.pushChannel = installation.pushChannel
          print("notificationHub installation was successful.")
          CallingViewModel.shared().initPushNotification()
      }
  }