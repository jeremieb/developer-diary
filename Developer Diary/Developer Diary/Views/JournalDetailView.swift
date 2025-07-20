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
    
    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 16) {
                if entry.title != "" {
                    // Title section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                
                // Note section
                if entry.note != "" {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.note)
                            .font(.body)
                            .lineLimit(nil)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .padding()
            .foregroundStyle(Color.primary)
        }
        .background {
            if entry.hasSceneFile {
                PreviewImageView(
                    entry: entry,
                    viewModel: viewModel,
                    height: UIScreen.main.bounds.height,
                    showEditButton: false
                )
                .frame(maxHeight: .infinity)
                .ignoresSafeArea()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showEditView.toggle()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .fullScreenCover(isPresented: $showEditView) {
            AddEntryView(viewModel: viewModel, entryToEdit: entry)
        }
    }
}
