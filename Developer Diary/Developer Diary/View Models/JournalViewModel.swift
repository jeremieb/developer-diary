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
    private var sharedEngine: Engine?
    private var isInitializingEngine = false
    
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
    }
    
    // MARK: - Preview Image Generation
    
    func getPreviewImage(for entry: JournalEntry) -> UIImage? {
        return previewImageCache[entry.id]
    }
    
    func isGeneratingPreview(for entry: JournalEntry) -> Bool {
        return generatingPreviews.contains(entry.id)
    }
    
    private func getOrCreateEngine() async throws -> Engine {
        if let sharedEngine = sharedEngine {
            return sharedEngine
        }
        
        // Prevent multiple engine creation attempts
        if isInitializingEngine {
            // Wait for existing initialization
            while isInitializingEngine {
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
            if let sharedEngine = sharedEngine {
                return sharedEngine
            }
        }
        
        isInitializingEngine = true
        
        do {
            let engine = try await Engine(
                license: "w4PVeqZdxtlB4FicODTgcf-keMYt-U6Vr6qhqIdBtPdlRhvxb6j1OvWUuTFhI8rw",
                userID: "myUniqueUserID01"
            )
            
            sharedEngine = engine
            isInitializingEngine = false
            
            return engine
        } catch {
            isInitializingEngine = false
            throw error
        }
    }
    
    @MainActor
    func generatePreviewImage(for entry: JournalEntry) {
        // Don't generate if already generating or if no scene
        guard !generatingPreviews.contains(entry.id) && entry.hasSceneFile else { return }
        
        // Check if we already have a cached image
        if previewImageCache[entry.id] != nil { return }
        
        // First try to load from stored URL
        if let previewImageURL = entry.previewImageURL {
            do {
                let data = try Data(contentsOf: previewImageURL)
                if let image = UIImage(data: data) {
                    previewImageCache[entry.id] = image
                    return
                }
            } catch {
                print("Error loading stored preview image: \(error.localizedDescription)")
            }
        }
        
        // Generate from scene string
        generatingPreviews.insert(entry.id)
        
        Task {
            do {
                let engine = try await getOrCreateEngine()
                
                // Load scene from string
                try await engine.scene.load(from: entry.sceneString)
                
                // Get the scene
                guard let scene = try engine.scene.get() else {
                    generatingPreviews.remove(entry.id)
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
                
                // Convert to UIImage
                let image = UIImage(data: imageData)
                
                if let image = image {
                    previewImageCache[entry.id] = image
                }
                generatingPreviews.remove(entry.id)
                
            } catch {
                print("Error generating preview image: \(error.localizedDescription)")
                generatingPreviews.remove(entry.id)
            }
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
        sharedEngine = nil
    }
}