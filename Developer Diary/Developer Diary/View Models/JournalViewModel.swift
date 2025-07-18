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
        cleanupOrphanedPreviewImages()
    }
    
    func fetchEntries() {
        do {
            let descriptor = FetchDescriptor<JournalEntry>(sortBy: [.init(\.date, order: .reverse)])
            entries = try context.fetch(descriptor)
        } catch {
            print("Error fetching entries: \(error.localizedDescription)")
        }
    }
    
    func addEntry(title: String, note: String, sceneString: String?, previewImageURL: URL? = nil) {
        let scene = sceneString ?? "/dev/null"
        let entry = JournalEntry(title: title, note: note, sceneString: scene, previewImageURL: previewImageURL)
        context.insert(entry)
        
        do {
            try context.save()
            fetchEntries()
        } catch {
            print("Error saving entry: \(error.localizedDescription)")
        }
    }
    
    @MainActor func updateEntry(_ entry: JournalEntry, title: String, note: String, sceneString: String?, previewImageURL: URL? = nil) {
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
        
        do {
            try context.save()
            fetchEntries()
            
            // Force regenerate preview if scene was updated
            if sceneString != nil {
                generatePreviewImage(for: entry)
            }
        } catch {
            print("Error updating entry: \(error.localizedDescription)")
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
        
        cleanupOrphanedPreviewImages()
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
        
        // Try to load from stored URL, but don't fail if file doesn't exist
        if let previewImageURL = entry.previewImageURL {
            do {
                let data = try Data(contentsOf: previewImageURL)
                if let image = UIImage(data: data) {
                    previewImageCache[entry.id] = image
                    return
                }
            } catch {
                // File doesn't exist or can't be loaded, we'll regenerate it
                print("Will regenerate preview for entry: \(entry.title)")
            }
        }
        
        // Extract values we need for the async task
        let entryID = entry.id
        let sceneString = entry.sceneString
        
        // Generate from scene string - each entry gets its own engine to avoid conflicts
        generatingPreviews.insert(entryID)
        
        Task {
            do {
                // Create a separate engine instance for each preview generation
                let engine = try await Engine(
                    license: "w4PVeqZdxtlB4FicODTgcf-keMYt-U6Vr6qhqIdBtPdlRhvxb6j1OvWUuTFhI8rw",
                    userID: "myUniqueUserID01"
                )
                
                // Load scene from string
                try await engine.scene.load(from: sceneString)
                
                // Get the scene
                guard let scene = try engine.scene.get() else {
                    generatingPreviews.remove(entryID)
                    return
                }
                
                // Export as PNG
                let exportOptions = ExportOptions(
                    pngCompressionLevel: 5,
                    targetWidth: 300,
                    targetHeight: 300
                )
                
                let imageData = try await engine.block.export(
                    scene,
                    mimeType: .png,
                    options: exportOptions
                )
                
                // Convert to UIImage and cache it
                if let image = UIImage(data: imageData) {
                    previewImageCache[entryID] = image
                    
                    // Save the image to current app container
                    await savePreviewImage(imageData, for: entryID)
                }
                
                generatingPreviews.remove(entryID)
                
            } catch {
                print("Error generating preview image: \(error.localizedDescription)")
                generatingPreviews.remove(entryID)
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
            let imageURL = previewsDirectory.appendingPathComponent("preview_\(entryID.uuidString).png")
            
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
    
    private func getCurrentPreviewDirectory() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("previews")
    }
    
    func cleanupOrphanedPreviewImages() {
        let previewsDirectory = getCurrentPreviewDirectory()
        
        guard FileManager.default.fileExists(atPath: previewsDirectory.path) else { return }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: previewsDirectory, includingPropertiesForKeys: nil)
            let entryIDs = Set(entries.map { $0.id.uuidString })
            
            for file in files {
                let filename = file.deletingPathExtension().lastPathComponent
                if filename.hasPrefix("preview_") {
                    let entryID = String(filename.dropFirst(8)) // Remove "preview_" prefix
                    if !entryIDs.contains(entryID) {
                        try FileManager.default.removeItem(at: file)
                        print("Cleaned up orphaned preview: \(filename)")
                    }
                }
            }
        } catch {
            print("Error cleaning up orphaned previews: \(error)")
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
