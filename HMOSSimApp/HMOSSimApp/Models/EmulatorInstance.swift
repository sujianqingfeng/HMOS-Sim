import Foundation

struct EmulatorInstance: Identifiable, Hashable {
    var name: String
    var id: String { name }
}

