//
//  EditorView.swift
//  Developer Diary
//
//  Created by Jeremie Berduck on 18/07/2025.
//

import SwiftUI
import IMGLYDesignEditor
import IMGLYEngine

struct EditorView: View {
    
    let engineSettings = EngineSettings(
        license: "w4PVeqZdxtlB4FicODTgcf-keMYt-U6Vr6qhqIdBtPdlRhvxb6j1OvWUuTFhI8rw", 
        userID: "myUniqueUserID01"
    )
    
    // Callback to handle the saved scene string and preview image
    let onSave: (String, URL?) -> Void
    
    // Optional existing scene string to load
    let existingSceneString: String?
    
    @Environment(\.dismiss) private var dismiss
    @State private var engine: Engine?
    
    var body: some View {
        NavigationView {
            DesignEditor(engineSettings)
                .imgly.onCreate { engine in
                    self.engine = engine
                    
                    // Load existing scene if available
                    if let existingSceneString, 
                       existingSceneString != "/dev/null" && !existingSceneString.isEmpty {
                        try await engine.scene.load(from: existingSceneString)
                    } else {
                        // Load default scene if no existing scene
                        try await engine.scene.load(from: DesignEditor.defaultScene)
                    }
                    
                    // Add default asset sources
                    try await engine.addDefaultAssetSources(baseURL: Engine.assetBaseURL)
                    try await engine.addDemoAssetSources(sceneMode: engine.scene.getMode(),
                                                         withUploadAssetSources: true)
                }
                .onDisappear {
                    Task {
                        await saveScene()
                    }
                }
        }
        .navigationViewStyle(.stack)
        .interactiveDismissDisabled()
    }
    
    @MainActor
    private func saveScene() async {
        guard let engine = engine else { return }
        
        do {
            // Save scene as string
            let sceneString = try await engine.scene.saveToString()
            
            // Export scene as PNG image for preview
            let previewImageURL = try await createPreviewImage(engine: engine)
            
            onSave(sceneString, previewImageURL)
            dismiss()
        } catch {
            print("Error saving scene: \(error)")
        }
    }
    
    @MainActor
    private func createPreviewImage(engine: Engine) async throws -> URL? {
        guard let scene = try engine.scene.get() else { return nil }
        
        // Export options for PNG with smaller size for preview
        let exportOptions = ExportOptions(
            pngCompressionLevel: 5,
            targetWidth: 300,
            targetHeight: 300
        )
        
        // Export scene as PNG
        let imageData = try await engine.block.export(
            scene,
            mimeType: .png,
            options: exportOptions
        )
        
        // Save to Documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imageURL = documentsPath.appendingPathComponent("preview_\(UUID().uuidString).png")
        
        try imageData.write(to: imageURL)
        return imageURL
    }
}
