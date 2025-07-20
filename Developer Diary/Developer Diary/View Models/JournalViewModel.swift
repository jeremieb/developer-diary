//
//  JournalViewModel.swift
//  Developer Diary
//
//  Created by Jeremie Berduck on 18/07/2025.
//

import Foundation
import SwiftData
import SwiftUI
import IMGLYEngine

@Observable
final class JournalViewModel {
    private let context: ModelContext
    
    var entries: [JournalEntry] = []
    private var previewImageCache: [UUID: UIImage] = [:]
    private var generatingPreviews: Set<UUID> = []
    
    init(context: ModelContext) {
        self.context = context
        fetchEntries()
    }
    
    func fetchEntries() {
        do {
            let descriptor = FetchDescriptor<JournalEntry>(sortBy: [.init(\.date, order: .reverse)])
            entries = try context.fetch(descriptor)
        } catch {
            print("Error fetching entries: \(error.localizedDescription)")
        }
    }
    
    func saveEntry(_ entry: JournalEntry? = nil, title: String, note: String, sceneString: String?, previewImageURL: URL? = nil) {
        if let entry = entry {
            // Update existing entry
            entry.title = title
            entry.note = note
            if let sceneString {
                entry.sceneString = sceneString
                // Clear cached preview when scene changes
                previewImageCache.removeValue(forKey: entry.id)
                // Also remove from generating set to allow regeneration
                generatingPreviews.remove(entry.id)
            }
            if let previewImageURL {
                entry.previewImageURL = previewImageURL
            }
        } else {
            // Create new entry
            let scene = sceneString ?? "/dev/null"
            let newEntry = JournalEntry(title: title, note: note, sceneString: scene, previewImageURL: previewImageURL)
            context.insert(newEntry)
        }
        
        do {
            try context.save()
            fetchEntries()
            
            // Force regenerate preview if scene was updated
            if let entry = entry, sceneString != nil {
                Task { @MainActor in
                    generatePreviewImage(for: entry)
                }
            }
        } catch {
            print("Error saving entry: \(error.localizedDescription)")
        }
    }
    
    func deleteEntry(_ entry: JournalEntry) {
        // Clean up preview image file if it exists
        if entry.hasPreviewImage, let previewURL = entry.previewImageURL {
            try? FileManager.default.removeItem(at: previewURL)
        }
        
        // Remove from cache
        previewImageCache.removeValue(forKey: entry.id)
        generatingPreviews.remove(entry.id)
        
        context.delete(entry)
        
        do {
            try context.save()
            fetchEntries()
        } catch {
            print("Error deleting entry: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Preview Image Generation
    
    func getPreviewImage(for entry: JournalEntry) -> UIImage? {
        return previewImageCache[entry.id]
    }
    
    func isGeneratingPreview(for entry: JournalEntry) -> Bool {
        return generatingPreviews.contains(entry.id)
    }
    
    @MainActor
    func generatePreviewImage(for entry: JournalEntry) {
        // Don't generate if already generating or if no scene
        guard !generatingPreviews.contains(entry.id) && entry.hasSceneFile else { return }
        
        // Check if we already have a cached image
        if previewImageCache[entry.id] != nil { return }
        
        generatingPreviews.insert(entry.id)
        
        Task {
            defer { generatingPreviews.remove(entry.id) }
            
            do {
                let engine = try await Engine(
                    license: "w4PVeqZdxtlB4FicODTgcf-keMYt-U6Vr6qhqIdBtPdlRhvxb6j1OvWUuTFhI8rw",
                    userID: "myUniqueUserID01"
                )
                
                try await engine.scene.load(from: entry.sceneString)
                guard let scene = try engine.scene.get() else { return }
                
                let exportOptions = ExportOptions(
                    jpegQuality: 3,
                    targetWidth: 1024,
                    targetHeight: 1920
                )
                
                let imageData = try await engine.block.export(scene, mimeType: .jpeg, options: exportOptions)
                
                if let image = UIImage(data: imageData) {
                    previewImageCache[entry.id] = image
                    await savePreviewImage(imageData, for: entry.id)
                }
                
            } catch {
                print("Error generating preview image: \(error.localizedDescription)")
            }
        }
    }
    
    private func savePreviewImage(_ imageData: Data, for entryID: UUID) async {
        do {
            // Always use the current app container's documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let previewsDirectory = documentsPath.appendingPathComponent("previews")
            
            // Create the directory if it doesn't exist
            try FileManager.default.createDirectory(at: previewsDirectory, withIntermediateDirectories: true)
            
            // Create a consistent filename based on entry ID
            let imageURL = previewsDirectory.appendingPathComponent("preview_\(entryID.uuidString).jpeg")
            
            // Save the image
            try imageData.write(to: imageURL)
            
            // Update the entry with the new URL
            await MainActor.run {
                // Find the entry by ID and update it
                if let entry = entries.first(where: { $0.id == entryID }) {
                    entry.previewImageURL = imageURL
                    try? context.save()
                }
            }
        } catch {
            print("Error saving preview image: \(error)")
        }
    }

    @MainActor
    func refreshPreviewImage(for entry: JournalEntry) {
        // Clear cache and force regeneration
        previewImageCache.removeValue(forKey: entry.id)
        generatingPreviews.remove(entry.id)
        generatePreviewImage(for: entry)
    }
    
    func previewImage(for entry: JournalEntry) -> Image? {
        if let uiImage = previewImageCache[entry.id] {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    func hasPreviewImage(for entry: JournalEntry) -> Bool {
        return previewImageCache[entry.id] != nil
    }
    
    deinit {
    }
}
