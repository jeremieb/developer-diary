//
//  PreviewImageView.swift
//  Developer Diary
//
//  Created by Jeremie Berduck on 18/07/2025.
//

import SwiftUI

struct PreviewImageView: View {
    let memory: Memory
    let viewModel: JournalViewModel
    let height: CGFloat
    let showEditButton: Bool
    let onEditTap: (() -> Void)?
    
    init(entry: Memory, viewModel: JournalViewModel, height: CGFloat = 200, showEditButton: Bool = true, onEditTap: (() -> Void)? = nil) {
        self.memory = entry
        self.viewModel = viewModel
        self.height = height
        self.showEditButton = showEditButton
        self.onEditTap = onEditTap
        viewModel.generatePreviewImage(for: entry)
    }
    
    var body: some View {
        VStack {
            Group {
                if viewModel.isGeneratingPreview(for: memory) {
                    VStack(spacing: 12) {
                        ProgressView()
                    }
                } else if let previewImage = viewModel.previewImage(for: memory) {
                    previewImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .cornerRadius(8)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        if showEditButton {
                            Text("Tap to Edit Image")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        Text("Scene length: \(memory.sceneString.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            if showEditButton && viewModel.previewImage(for: memory) != nil {
                Button("Edit Image") {
                    onEditTap?()
                }
                .foregroundColor(.blue)
                .font(.caption)
            }
        }
        .animation(.easeInOut, value: viewModel.isGeneratingPreview(for: memory))
    }
}
