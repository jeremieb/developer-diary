//
//  PreviewImageView.swift
//  Developer Diary
//
//  Created by Jeremie Berduck on 18/07/2025.
//

import SwiftUI

struct PreviewImageView: View {
    let entry: JournalEntry
    let viewModel: JournalViewModel
    let height: CGFloat
    let showEditButton: Bool
    let onEditTap: (() -> Void)?
    
    init(entry: JournalEntry, viewModel: JournalViewModel, height: CGFloat = 200, showEditButton: Bool = true, onEditTap: (() -> Void)? = nil) {
        self.entry = entry
        self.viewModel = viewModel
        self.height = height
        self.showEditButton = showEditButton
        self.onEditTap = onEditTap
        viewModel.generatePreviewImage(for: entry)
    }
    
    var body: some View {
        ZStack {
            VStack {
                Group {
                    if viewModel.isGeneratingPreview(for: entry) {
                        VStack(spacing: 12) {
                            ProgressView()
                        }
                        .frame(maxHeight: .infinity)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.secondary.opacity(0.1))
                    } else if let previewImage = viewModel.previewImage(for: entry) {
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
                            Text("Scene length: \(entry.sceneString.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                if showEditButton && viewModel.previewImage(for: entry) != nil {
                    Button("Edit Image") {
                        onEditTap?()
                    }
                    .foregroundColor(.blue)
                    .font(.caption)
                }
            }.animation(.easeInOut, value: viewModel.isGeneratingPreview(for: entry))
        }.frame(maxHeight: .infinity).frame(height: height)
    }
}
