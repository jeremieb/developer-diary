//
//  JournalListView.swift
//  Developer Diary
//
//  Created by Jeremie Berduck on 18/07/2025.
//

import SwiftUI
import SwiftData

struct JournalListView: View {
    @Environment(\.modelContext) private var context
    @State private var showAddView = false
    @State private var viewModel: JournalViewModel?
    
    var body: some View {
        NavigationView {
            List {
                if let viewModel {
                    ForEach(viewModel.entries, id: \.id) { entry in
                        NavigationLink(destination: JournalDetailView(entry: entry, viewModel: viewModel)) {
                            HStack(spacing: 12) {
                                // Preview thumbnail
                                if entry.hasSceneFile {
                                    PreviewImageView(
                                        entry: entry,
                                        viewModel: viewModel,
                                        height: 60,
                                        showEditButton: false
                                    )
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.title)
                                        .font(.headline)
                                    Text(entry.note)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.map { viewModel.entries[$0] }.forEach(viewModel.deleteEntry)
                    }
                }
            }
            .navigationTitle("Diary of a Dev")
            .toolbar {
                Button {
                    showAddView = true
                } label: {
                    Label("Add Entry", systemImage: "plus")
                }
            }
            .fullScreenCover(isPresented: $showAddView) {
                if let viewModel {
                    AddEntryView(viewModel: viewModel)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = JournalViewModel(context: context)
            }
        }
    }
}
