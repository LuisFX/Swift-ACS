enum ProfileCategory: Int, Identifiable, CaseIterable {
    case coummunications
    case notifications

    var id: Int {
        return rawValue
    }
}