//
//  AddMemoryView.swift
//  Developer Diary
//
//  Created by Jeremie Berduck on 18/07/2025.
//

import SwiftUI

struct AddMemoryView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var showEditor = false
    @State private var sceneString: String?
    @State private var previewImageURL: URL?
    @State private var memory: Memory?
    
    let viewModel: JournalViewModel
    let memoryToEdit: Memory?
    private var isEditing: Bool { memoryToEdit != nil }

    init(viewModel: JournalViewModel, memoryToEdit: Memory? = nil) {
        self.viewModel = viewModel
        self.memoryToEdit = memoryToEdit
    }
    
    private func loadPreviewImage(from url: URL) -> UIImage? {
        do {
            let data = try Data(contentsOf: url)
            return UIImage(data: data)
        } catch {
            print("Error loading preview image: \(error.localizedDescription)")
            return nil
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Image")) {
                    ZStack(alignment: .topTrailing) {
                        if let sceneString, !sceneString.isEmpty && sceneString != "/dev/null",
                           let entry = memory {
                            PreviewImageView(
                                entry: entry,
                                viewModel: viewModel,
                                showEditButton: false
                            )
                        }
                        
                        Button(isEditing ? "Edit Image" : "Add Image") {
                            showEditor = true
                        }.buttonStyle(.borderedProminent).padding()
                    }
                }.listRowInsets(.init())
                
                Section(header: Text("Title")) {
                    TextField("Enter title", text: $title)
                }
                
                Section(header: Text("Description")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isEditing ? "Edit Memory" : "New Memory")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") {
                        if isEditing {
                            viewModel.saveMemory(memoryToEdit, title: title, note: description, sceneString: sceneString, previewImageURL: previewImageURL)
                        } else {
                            viewModel.saveMemory(title: title, note: description, sceneString: sceneString, previewImageURL: previewImageURL)
                        }
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            if let memoryToEdit = memoryToEdit {
                // Editing existing memory
                memory = memoryToEdit
                title = memoryToEdit.title
                description = memoryToEdit.note
                sceneString = memoryToEdit.sceneString != "/dev/null" ? memoryToEdit.sceneString : nil
                previewImageURL = memoryToEdit.previewImageURL
                
                // Generate preview for the existing memory
                viewModel.generatePreviewImage(for: memoryToEdit)
            }
        }
        .fullScreenCover(isPresented: $showEditor) {
            EditorView(
                onSave: { savedSceneString, previewImageURL in
                    sceneString = savedSceneString
                    self.previewImageURL = previewImageURL
                    
                    if isEditing {
                        // Update existing memory
                        memory?.sceneString = savedSceneString
                        if let previewImageURL {
                            memory?.previewImageURL = previewImageURL
                        }
                        if let memory = memory {
                            viewModel.refreshPreviewImage(for: memory)
                        }
                    } else {
                        // Create temporary entry for preview
                        memory = Memory(
                            title: "Preview",
                            note: "",
                            sceneString: savedSceneString,
                            previewImageURL: previewImageURL
                        )
                        
                        if let memory = memory {
                            viewModel.generatePreviewImage(for: memory)
                        }
                    }
                },
                existingSceneString: sceneString
            )
        }
    }
}
