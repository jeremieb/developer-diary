//
//  MemoryView.swift
//  Developer Diary
//
//  Created by Jeremie Berduck on 18/07/2025.
//

import SwiftUI
import IMGLYDesignEditor
import IMGLYEngine

struct MemoryView: View {
    let memory: Memory
    let viewModel: JournalViewModel
    
    @State private var showEditView = false
    
    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 16) {
                if memory.title != "" {
                    // Title section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(memory.title)
                            .font(.title2)
                            .fontWeight(.semibold).fontWidth(.expanded)
                    }
                }
                
                // Note section
                if memory.note != "" {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text(memory.note)
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
            if memory.hasSceneFile {
                PreviewImageView(
                    entry: memory,
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
            AddMemoryView(viewModel: viewModel, memoryToEdit: memory)
        }
    }
}
