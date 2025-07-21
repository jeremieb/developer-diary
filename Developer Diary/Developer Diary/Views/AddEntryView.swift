//
//  AddEntryView.swift
//  Developer Diary
//
//  Created by Jeremie Berduck on 18/07/2025.
//

import SwiftUI

struct AddEntryView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var showEditor = false
    @State private var sceneString: String?
    @State private var previewImageURL: URL?
    @State private var entry: JournalEntry?
    
    let viewModel: JournalViewModel
    let entryToEdit: JournalEntry?
    private var isEditing: Bool { entryToEdit != nil }

    init(viewModel: JournalViewModel, entryToEdit: JournalEntry? = nil) {
        self.viewModel = viewModel
        self.entryToEdit = entryToEdit
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
                           let entry = entry {
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
            .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") {
                        if isEditing {
                            viewModel.saveEntry(entryToEdit, title: title, note: description, sceneString: sceneString, previewImageURL: previewImageURL)
                        } else {
                            viewModel.saveEntry(title: title, note: description, sceneString: sceneString, previewImageURL: previewImageURL)
                        }
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            if let entryToEdit = entryToEdit {
                // Editing existing entry
                entry = entryToEdit
                title = entryToEdit.title
                description = entryToEdit.note
                sceneString = entryToEdit.sceneString != "/dev/null" ? entryToEdit.sceneString : nil
                previewImageURL = entryToEdit.previewImageURL
                
                // Generate preview for the existing entry
                viewModel.generatePreviewImage(for: entryToEdit)
            }
        }
        .fullScreenCover(isPresented: $showEditor) {
            EditorView(
                onSave: { savedSceneString, previewImageURL in
                    sceneString = savedSceneString
                    self.previewImageURL = previewImageURL
                    
                    if isEditing {
                        // Update existing entry
                        entry?.sceneString = savedSceneString
                        if let previewImageURL {
                            entry?.previewImageURL = previewImageURL
                        }
                        if let entry = entry {
                            viewModel.refreshPreviewImage(for: entry)
                        }
                    } else {
                        // Create temporary entry for preview
                        entry = JournalEntry(
                            title: "Preview",
                            note: "",
                            sceneString: savedSceneString,
                            previewImageURL: previewImageURL
                        )
                        
                        if let entry = entry {
                            viewModel.generatePreviewImage(for: entry)
                        }
                    }
                },
                existingSceneString: sceneString
            )
        }
    }
}
