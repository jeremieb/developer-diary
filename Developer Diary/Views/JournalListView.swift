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
    @State private var selectedMemory: Memory?
    @State private var editMemory: Memory?
    
    var body: some View {
        NavigationStack {
            if let viewModel {
                ScrollView {
                    StaggeredGridLayout(columns: 2, spacing: 16, verticalOffset: 66) {
                        ForEach(viewModel.memories, id: \.id) { memory in
                            Button(action: {
                                self.selectedMemory = memory
                            }){
                                JournalEntryCardView(memory: memory, viewModel: viewModel)
                                    .matchedTransitionSource(id: memory.id, in: namespace)
                            }
                            .contextMenu {
                                Button(action: {
                                    editMemory = memory
                                }){
                                    Label("Edit", systemImage: "square.and.pencil")
                                }
                                Divider()
                                Button(role: .destructive, action: {
                                    viewModel.deleteEntry(memory)
                                }){
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal).padding(.top)
                    .navigationDestination(item: $selectedMemory) { memory in
                        MemoryView(memory: memory, viewModel: viewModel)
                            .navigationTransition(.zoom(sourceID: memory.id, in: namespace))
                    }
                    .animation(.easeInOut, value: viewModel.memories)
                }
                .navigationTitle("My Journal")
                .toolbar {
                    Button {
                        showAddView.toggle()
                    } label: {
                        Label("Add Entry", systemImage: "plus")
                    }
                }
                .onChange(of: editMemory) { _, newState in
                    if newState != nil {
                        showAddView.toggle()
                    }
                }
                .fullScreenCover(isPresented: $showAddView, onDismiss: {
                    editMemory = nil
                }) {
                    AddMemoryView(viewModel: viewModel, memoryToEdit: editMemory)
                }
                .overlay {
                    if viewModel.memories.count == 0 {
                        ContentUnavailableView {
                            Label("Your Journal is empty", systemImage: "append.page.fill")
                        } description: {
                            Text("Use the add button on the top of the screen to add your first memory.")
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
