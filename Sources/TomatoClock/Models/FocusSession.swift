import Foundation
import SwiftUI

struct FocusSession: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let duration: TimeInterval
    let tag: String
}

struct Tag: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
    
    static let defaults: [Tag] = [
        Tag(name: "Dev", color: .blue),
        Tag(name: "Reading", color: .orange),
        Tag(name: "Meeting", color: .purple),
        Tag(name: "Design", color: .pink),
        Tag(name: "Writing", color: .green),
        Tag(name: "Other", color: .gray)
    ]
}
