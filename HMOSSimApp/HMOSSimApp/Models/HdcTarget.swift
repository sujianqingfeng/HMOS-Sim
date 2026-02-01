import Foundation

struct HdcTarget: Identifiable, Hashable {
    var connectKey: String
    var transport: String
    var state: String
    var description: String?

    var id: String { connectKey }
    var isOnline: Bool { state.caseInsensitiveCompare("Online") == .orderedSame }
}

