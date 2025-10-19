//
//  ContentView.swift
//  Eko
//
//  Created by Ryan York on 10/10/25.
//

import SwiftUI
import EkoCore
import EkoKit

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @State private var children: [Child] = []
    @State private var selectedChild: Child?
    @State private var isLoadingChildren = true
    @State private var error: Error?

    private let supabase = SupabaseService.shared

    enum Tab {
        case home
        case lyra
        case library
        case profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)

            // Lyra Tab - AI Chat
            NavigationStack {
                Group {
                    if isLoadingChildren {
                        ProgressView("Loading...")
                    } else if let error {
                        ErrorView(error: error) {
                            Task {
                                await loadChildren()
                            }
                        }
                    } else if children.isEmpty {
                        NoChildrenView {
                            Task {
                                await loadChildren()
                            }
                        }
                    } else if let child = selectedChild {
                        LyraView(childId: child.id)
                            .navigationTitle("Chat with Lyra")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) {
                                    childPickerMenu
                                }
                            }
                    } else {
                        ChildSelectionView(
                            children: children,
                            onSelectChild: { child in
                                selectedChild = child
                            }
                        )
                    }
                }
            }
            .tabItem {
                Label("Lyra", systemImage: "bubble.left.and.bubble.right.fill")
            }
            .tag(Tab.lyra)

            // Library Tab
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                .tag(Tab.library)

            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .task {
            await loadChildren()
        }
    }

    // MARK: - Child Picker Menu

    @ViewBuilder
    private var childPickerMenu: some View {
        if !children.isEmpty {
            Menu {
                ForEach(children) { child in
                    Button {
                        selectedChild = child
                    } label: {
                        HStack {
                            Text(child.name)
                            if child.id == selectedChild?.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedChild?.name ?? "Select Child")
                        .font(.ekoHeadline)
                    Image(systemName: "chevron.down")
                        .font(.ekoCaption)
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadChildren() async {
        isLoadingChildren = true
        error = nil

        do {
            let user = try await supabase.getCurrentUser()
            guard let userId = user?.id else {
                throw NSError(domain: "ContentView", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "No authenticated user"
                ])
            }

            children = try await supabase.fetchChildren(forUserId: userId)

            // Auto-select first child if available
            if selectedChild == nil && !children.isEmpty {
                selectedChild = children.first
            }

            isLoadingChildren = false
        } catch {
            self.error = error
            isLoadingChildren = false
        }
    }
}

// MARK: - Placeholder Views

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("Home")
                    .font(.ekoTitle1)
                Text("Your parenting dashboard")
                    .font(.ekoBody)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Home")
        }
    }
}

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("Library")
                    .font(.ekoTitle1)
                Text("Educational content & resources")
                    .font(.ekoBody)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Library")
        }
    }
}

struct ProfileView: View {
    @State private var showAddChild = false
    @State private var children: [Child] = []
    @State private var isLoading = true

    private let supabase = SupabaseService.shared

    var body: some View {
        NavigationStack {
            List {
                // Children Section
                Section {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if children.isEmpty {
                        Text("No children added yet")
                            .font(.ekoBody)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(children) { child in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(child.name)
                                        .font(.ekoHeadline)
                                    Text("Age \(child.age) • \(child.temperament.displayName)")
                                        .font(.ekoCaption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .onDelete(perform: deleteChild)
                    }

                    Button {
                        showAddChild = true
                    } label: {
                        Label("Add Child", systemImage: "plus.circle.fill")
                            .font(.ekoBody)
                    }
                } header: {
                    Text("Children")
                        .font(.ekoHeadline)
                } footer: {
                    Text("Add child profiles to personalize Lyra's guidance")
                        .font(.ekoCaption)
                }

                // Account Section
                Section {
                    Button("Sign Out") {
                        Task {
                            try? await supabase.signOut()
                        }
                    }
                    .font(.ekoBody)
                    .foregroundStyle(.red)
                } header: {
                    Text("Account")
                        .font(.ekoHeadline)
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showAddChild) {
                AddChildView {
                    // Refresh children list after adding
                    Task {
                        await loadChildren()
                    }
                }
            }
            .task {
                await loadChildren()
            }
        }
    }

    private func loadChildren() async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let user = try await supabase.getCurrentUser() else { return }
            children = try await supabase.fetchChildren(forUserId: user.id)
        } catch {
            print("Error loading children: \(error)")
        }
    }

    private func deleteChild(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let child = children[index]
                do {
                    try await supabase.deleteChild(id: child.id)
                    // Remove from local array
                    await MainActor.run {
                        children.remove(at: index)
                    }
                } catch {
                    print("Error deleting child: \(error)")
                    // TODO: Show error alert to user
                }
            }
        }
    }
}

// MARK: - Child Selection View

struct ChildSelectionView: View {
    let children: [Child]
    let onSelectChild: (Child) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Select a Child")
                .font(.ekoTitle1)

            Text("Choose which child you'd like to chat with Lyra about")
                .font(.ekoBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(children) { child in
                    Button {
                        onSelectChild(child)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(child.name)
                                    .font(.ekoHeadline)
                                Text("Age \(child.age) • \(child.temperament.displayName)")
                                    .font(.ekoCaption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Lyra")
    }
}

// MARK: - No Children View

struct NoChildrenView: View {
    @State private var showAddChild = false
    var onChildAdded: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Children Added")
                .font(.ekoTitle1)

            Text("Add a child profile to start using Lyra")
                .font(.ekoBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Add Child") {
                showAddChild = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Lyra")
        .sheet(isPresented: $showAddChild) {
            AddChildView {
                onChildAdded?()
            }
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let error: Error
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            Text("Something went wrong")
                .font(.ekoTitle1)

            Text(error.localizedDescription)
                .font(.ekoBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Try Again") {
                retry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
