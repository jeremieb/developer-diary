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
    @Namespace var namespace
    
    @State private var showAddView = false
    @State private var viewModel: JournalViewModel?
    @State private var selectedJournalEntry: JournalEntry?
    
    var body: some View {
        NavigationStack {
            if let viewModel {
                ScrollView {
                    StaggeredGridLayout(columns: 2, spacing: 16, verticalOffset: 66) {
                        ForEach(viewModel.entries, id: \.id) { entry in
                            Button(action: {
                                self.selectedJournalEntry = entry
                            }){
                                JournalEntryCardView(entry: entry, viewModel: viewModel)
                                    .matchedTransitionSource(id: entry.id, in: namespace)
                            }
                        }
                    }
                    .padding(.horizontal, 16) // Native 16pt margins
                    .padding(.top, 16)
                    .navigationDestination(item: $selectedJournalEntry) { entry in
                        JournalDetailView(entry: entry, viewModel: viewModel)
                            .navigationTransition(.zoom(sourceID: entry.id, in: namespace))
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
