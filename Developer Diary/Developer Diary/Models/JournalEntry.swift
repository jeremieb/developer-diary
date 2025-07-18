//
//  JournalEntry.swift
//  Developer Diary
//
//  Created by Jeremie Berduck on 18/07/2025.
//

import Foundation
import SwiftData

@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var title: String
    var note: String
    var date: Date
    var sceneString: String
    // Preview image URL
    var previewImageURL: URL?
    
    var hasSceneFile: Bool {
        !sceneString.isEmpty && sceneString != "/dev/null"
    }
    
    var hasPreviewImage: Bool {
        previewImageURL != nil && previewImageURL?.absoluteString != "/dev/null"
    }
    
    init(title: String, note: String, date: Date = .now, sceneString: String = "/dev/null", previewImageURL: URL? = nil) {
        self.id = UUID()
        self.title = title
        self.note = note
        self.date = date
        self.sceneString = sceneString
        self.previewImageURL = previewImageURL
    }
}
