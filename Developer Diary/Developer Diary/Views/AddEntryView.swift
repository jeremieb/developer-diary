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
    
    let viewModel: JournalViewModel
    let entryToEdit: JournalEntry?
    
    private var isEditing: Bool {
        entryToEdit != nil
    }
    
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
                Section(header: Text("Title")) {
                    TextField("Enter title", text: $title)
                }
                
                Section(header: Text("Description")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Image")) {
                    VStack(spacing: 12) {
                        if let sceneString, !sceneString.isEmpty && sceneString != "/dev/null" {
                            if isEditing, let entry = entryToEdit {
                                // For editing, use the actual entry to maintain cache
                                PreviewImageView(
                                    entry: entry,
                                    viewModel: viewModel,
                                    height: 150,
                                    showEditButton: false
                                )
                            } else {
                                // For new entries, show a simple preview or placeholder
                                if let previewImageURL, let previewImage = loadPreviewImage(from: previewImageURL) {
                                    Image(uiImage: previewImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 150)
                                        .cornerRadius(8)
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(height: 150)
                                        .overlay(
                                            VStack(spacing: 8) {
                                                Image(systemName: "photo.on.rectangle")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.blue)
                                                Text("Scene created")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        )
                                }
                            }
                            
                            Button("Edit Image") {
                                showEditor = true
                            }
                            .foregroundColor(.blue)
                        } else {
                            Button("Add Image") {
                                showEditor = true
                            }
                            .foregroundColor(.blue)
                        }
                    }
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
                        if isEditing, let entry = entryToEdit {
                            viewModel.updateEntry(entry, title: title, note: description, sceneString: sceneString, previewImageURL: previewImageURL)
                        } else {
                            viewModel.addEntry(title: title, note: description, sceneString: sceneString, previewImageURL: previewImageURL)
                        }
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            if let entry = entryToEdit {
                title = entry.title
                description = entry.note
                sceneString = entry.sceneString != "/dev/null" ? entry.sceneString : nil
                previewImageURL = entry.previewImageURL
                
                // Generate preview for the existing entry
                viewModel.generatePreviewImage(for: entry)
            }
        }
        .fullScreenCover(isPresented: $showEditor) {
            EditorView(
                onSave: { savedSceneString, previewImageURL in
                    sceneString = savedSceneString
                    self.previewImageURL = previewImageURL
                    
                    // If we're editing an existing entry, refresh its preview
                    if let entry = entryToEdit {
                        viewModel.refreshPreviewImage(for: entry)
                    }
                },
                existingSceneString: sceneString
            )
        }
    }
}
