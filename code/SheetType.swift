enum SheetType: Int, Identifiable, CaseIterable {
    case signInRequired
    case displayNotification
    case callView

    var id: Int {
        return rawValue
    }
}