//
//  Developer_DiaryApp.swift
//  Developer Diary
//
//  Created by Jeremie Berduck on 18/07/2025.
//

import SwiftUI
import SwiftData

@main
struct Developer_DiaryApp: App {
    var body: some Scene {
        WindowGroup {
            JournalListView()
        }
        .modelContainer(for: Memory.self)
    }
}
