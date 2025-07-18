//
//  JournalDetailView.swift
//  Developer Diary
//
//  Created by Jeremie Berduck on 18/07/2025.
//

import SwiftUI
import IMGLYDesignEditor
import IMGLYEngine

struct JournalDetailView: View {
    let entry: JournalEntry
    let viewModel: JournalViewModel
    
    @State private var showEditView = false
    @State private var showImageEditor = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if entry.hasSceneFile {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Image")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        PreviewImageView(
                            entry: entry,
                            viewModel: viewModel,
                            height: 200,
                            showEditButton: true
                        ) {
                            showImageEditor = true
                        }
                    }
                    
                    Divider()
                }

                // Title section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(entry.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Divider()
                
                // Date section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(entry.date.formatted(date: .complete, time: .shortened))
                        .font(.body)
                }
                
                Divider()
                
                // Note section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(entry.note)
                        .font(.body)
                        .lineLimit(nil)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Entry Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showEditView = true
                }
            }
        }
        .fullScreenCover(isPresented: $showEditView) {
            AddEntryView(viewModel: viewModel, entryToEdit: entry)
        }
        .fullScreenCover(isPresented: $showImageEditor) {
            EditorView(
                onSave: { savedSceneString, previewImageURL in
                    viewModel.updateEntry(entry, title: entry.title, note: entry.note, sceneString: savedSceneString, previewImageURL: previewImageURL)
                    viewModel.refreshPreviewImage(for: entry)
                },
                existingSceneString: entry.sceneString != "/dev/null" ? entry.sceneString : nil
            )
        }
    }
}
