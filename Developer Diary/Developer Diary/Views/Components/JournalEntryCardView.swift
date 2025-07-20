//
//  JournalEntryCardView.swift
//  Developer Diary
//
//  Created by Jeremie Berduck on 18/07/2025.
//

import SwiftUI

struct JournalEntryCardView: View {
    let entry: JournalEntry
    let viewModel: JournalViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Image used as card background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.secondary.opacity(1))
                    .overlay {
                        // Preview image section - takes up about 70% of the card
                        if entry.hasSceneFile {
                            PreviewImageView(
                                entry: entry,
                                viewModel: viewModel,
                                height: geometry.size.height,
                                showEditButton: false
                            ).clipped()
                        } else {
                            // Placeholder
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.clear)
                                .frame(height: geometry.size.height)
                                .overlay(
                                    VStack {
                                        Image(systemName: "doc.text")
                                            .font(.system(size: 24))
                                            .foregroundColor(.gray)
                                        Text("No Scene")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                )
                        }
                    }
                
                // Journal entry
                // Content section - takes up remaining 30%
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(entry.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(Color.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding().foregroundStyle(Color.primary)
                .background(.ultraThinMaterial)
            }
        }
        .aspectRatio(9.0/16.0, contentMode: .fit)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
