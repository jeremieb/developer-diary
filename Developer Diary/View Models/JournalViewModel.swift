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
    
    var memories: [Memory] = []
    private var previewImageCache: [UUID: UIImage] = [:]
    private var generatingPreviews: Set<UUID> = []
    
    init(context: ModelContext) {
        self.context = context
        fetchMemories()
    }
    
    func fetchMemories() {
        do {
            let descriptor = FetchDescriptor<Memory>(sortBy: [.init(\.date, order: .reverse)])
            memories = try context.fetch(descriptor)
        } catch {
            print("Error fetching entries: \(error.localizedDescription)")
        }
    }
    
    func saveMemory(_ memory: Memory? = nil, title: String, note: String, sceneString: String?, previewImageURL: URL? = nil) {
        if let memory = memory {
            // Update existing memory
            memory.title = title
            memory.note = note
            if let sceneString {
                memory.sceneString = sceneString
                // Clear cached preview when scene changes
                previewImageCache.removeValue(forKey: memory.id)
                // Also remove from generating set to allow regeneration
                generatingPreviews.remove(memory.id)
            }
            if let previewImageURL {
                memory.previewImageURL = previewImageURL
            }
        } else {
            // Create new memory
            let scene = sceneString ?? "/dev/null"
            let newMemory = Memory(title: title, note: note, sceneString: scene, previewImageURL: previewImageURL)
            context.insert(newMemory)
        }
        
        do {
            try context.save()
            fetchMemories()
            
            // Force regenerate preview if scene was updated
            if let memory = memory, sceneString != nil {
                Task { @MainActor in
                    generatePreviewImage(for: memory)
                }
            }
        } catch {
            print("Error saving entry: \(error.localizedDescription)")
        }
    }
    
    func deleteEntry(_ memory: Memory) {
        // Clean up preview image file if it exists
        if memory.hasPreviewImage, let previewURL = memory.previewImageURL {
            try? FileManager.default.removeItem(at: previewURL)
        }
        
        // Remove from cache
        previewImageCache.removeValue(forKey: memory.id)
        generatingPreviews.remove(memory.id)
        
        context.delete(memory)
        
        do {
            try context.save()
            fetchMemories()
        } catch {
            print("Error deleting entry: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Preview Image Generation
    func getPreviewImage(for memory: Memory) -> UIImage? {
        return previewImageCache[memory.id]
    }
    
    func isGeneratingPreview(for memory: Memory) -> Bool {
        return generatingPreviews.contains(memory.id)
    }
    
    @MainActor
    func generatePreviewImage(for memory: Memory) {
        // Don't generate if already generating or if no scene
        guard !generatingPreviews.contains(memory.id) && memory.hasSceneFile else { return }
        
        // Check if we already have a cached image
        if previewImageCache[memory.id] != nil { return }
        
        generatingPreviews.insert(memory.id)
        
        Task {
            defer { generatingPreviews.remove(memory.id) }
            
            do {
                let engine = try await Engine(
                    license: "w4PVeqZdxtlB4FicODTgcf-keMYt-U6Vr6qhqIdBtPdlRhvxb6j1OvWUuTFhI8rw",
                    userID: "myUniqueUserID01"
                )
                
                try await engine.scene.load(from: memory.sceneString)
                guard let scene = try engine.scene.get() else { return }
                
                let exportOptions = ExportOptions(
                    jpegQuality: 3,
                    targetWidth: 1024,
                    targetHeight: 1920
                )
                
                let imageData = try await engine.block.export(scene, mimeType: .jpeg, options: exportOptions)
                
                if let image = UIImage(data: imageData) {
                    previewImageCache[memory.id] = image
                    await savePreviewImage(imageData, for: memory.id)
                }
                
            } catch {
                print("Error generating preview image: \(error.localizedDescription)")
            }
        }
    }
    
    private func savePreviewImage(_ imageData: Data, for memoryID: UUID) async {
        do {
            // Always use the current app container's documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let previewsDirectory = documentsPath.appendingPathComponent("previews")
            
            // Create the directory if it doesn't exist
            try FileManager.default.createDirectory(at: previewsDirectory, withIntermediateDirectories: true)
            
            // Create a consistent filename based on entry ID
            let imageURL = previewsDirectory.appendingPathComponent("preview_\(memoryID.uuidString).jpeg")
            
            // Save the image
            try imageData.write(to: imageURL)
            
            // Update the memory with the new URL
            await MainActor.run {
                // Find the entry by ID and update it
                if let entry = memories.first(where: { $0.id == memoryID }) {
                    entry.previewImageURL = imageURL
                    try? context.save()
                }
            }
        } catch {
            print("Error saving preview image: \(error)")
        }
    }

    @MainActor
    func refreshPreviewImage(for memory: Memory) {
        // Clear cache and force regeneration
        previewImageCache.removeValue(forKey: memory.id)
        generatingPreviews.remove(memory.id)
        generatePreviewImage(for: memory)
    }
    
    func previewImage(for memory: Memory) -> Image? {
        if let uiImage = previewImageCache[memory.id] {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    func hasPreviewImage(for memory: Memory) -> Bool {
        return previewImageCache[memory.id] != nil
    }
}
