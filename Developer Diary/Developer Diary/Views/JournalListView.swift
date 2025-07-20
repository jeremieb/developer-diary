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
    @State private var editEntry: JournalEntry?
    
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
                            .contextMenu {
                                Button(action: {
                                    editEntry = entry
                                }){
                                    Label("Edit", systemImage: "square.and.pencil")
                                }
                                Divider()
                                Button(role: .destructive, action: {
                                    viewModel.deleteEntry(entry)
                                }){
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16) // Native 16pt margins
                    .padding(.top, 16)
                    .navigationDestination(item: $selectedJournalEntry) { entry in
                        JournalDetailView(entry: entry, viewModel: viewModel)
                            .navigationTransition(.zoom(sourceID: entry.id, in: namespace))
                    }
                    .animation(.easeInOut, value: viewModel.entries)
                }
                .navigationTitle("My Journal")
                .toolbar {
                    Button {
                        showAddView.toggle()
                    } label: {
                        Label("Add Entry", systemImage: "plus")
                    }
                }
                .onChange(of: editEntry) { _, newState in
                    if newState != nil {
                        showAddView.toggle()
                    }
                }
                .fullScreenCover(isPresented: $showAddView, onDismiss: {
                    editEntry = nil
                }) {
                    AddEntryView(viewModel: viewModel, entryToEdit: editEntry)
                }
                .overlay {
                    if viewModel.entries.count == 0 {
                        ContentUnavailableView {
                            Label("Your Journal is empty", systemImage: "append.page.fill")
                        } description: {
                            Text("Use the add button on the top of the screen to add your first entry.")
                        }
                    }
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
