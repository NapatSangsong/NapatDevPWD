import SwiftUI

struct ItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(VaultStore.self) private var store

    @State private var draft: VaultItem
    private let isNew: Bool

    init(item: VaultItem? = nil) {
        if let item {
            _draft = State(initialValue: item)
            isNew = false
        } else {
            _draft = State(initialValue: VaultItem(brandSeed: BrandRegistry.all.randomElement() ?? "default"))
            isNew = true
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Title", text: $draft.title)
                    TextField("Username or email", text: $draft.username)
                        .textContentType(.username)
                        #if canImport(UIKit)
                        .autocapitalization(.none)
                        #endif
                    TextField("Website", text: $draft.website)
                        .textContentType(.URL)
                        #if canImport(UIKit)
                        .autocapitalization(.none)
                        #endif
                }
                Section("Password") {
                    SecureField("Password", text: $draft.password)
                    Toggle("Favorite", isOn: $draft.isFavorite)
                }
                Section {
                    ForEach($draft.environments) { $env in
                        HStack(spacing: 8) {
                            TextField("Label", text: $env.label)
                                .frame(maxWidth: 110)
                                #if canImport(UIKit)
                                .autocapitalization(.allCharacters)
                                #endif
                            TextField("https://…", text: $env.url)
                                .textContentType(.URL)
                                #if canImport(UIKit)
                                .autocapitalization(.none)
                                #endif
                            Button(role: .destructive) {
                                draft.environments.removeAll { $0.id == env.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(Color(hex: 0xE11D48))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Button {
                        draft.environments.append(EnvironmentURL(label: "", url: ""))
                    } label: {
                        Label("Add environment", systemImage: "plus")
                            .font(.nd(12.5, weight: .medium))
                    }
                } header: {
                    HStack {
                        Text("URLs")
                        Spacer()
                        Text("label each \u{2014} PRD / DEV · Main / Backup · Mobile …")
                            .font(.nd(10.5))
                            .foregroundStyle(DesignTokens.muted2)
                            .textCase(nil)
                    }
                }
                Section {
                    TagEditor(tags: $draft.tags)
                } header: {
                    HStack {
                        Text("Tags")
                        Spacer()
                        Text("e.g. PTT · vpn · work · account")
                            .font(.nd(10.5))
                            .foregroundStyle(DesignTokens.muted2)
                            .textCase(nil)
                    }
                }
                Section("Notes") {
                    TextEditor(text: $draft.notes)
                        .frame(minHeight: 100)
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(44), spacing: 8), count: 6), spacing: 8) {
                        ForEach(BrandRegistry.all, id: \.self) { seed in
                            Button { draft.brandSeed = seed } label: {
                                BrandMark(seed: seed, size: 36, radius: 8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(DesignTokens.accent, lineWidth: draft.brandSeed == seed ? 2 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "New Item" : "Edit Item")
            #if canImport(UIKit)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.upsert(draft)
                        dismiss()
                    }
                    .disabled(draft.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
