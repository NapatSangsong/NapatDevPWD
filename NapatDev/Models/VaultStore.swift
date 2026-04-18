import Foundation
import CryptoKit
import Observation

@Observable
@MainActor
final class VaultStore {
    private(set) var file: VaultFile = VaultFile()
    private(set) var location: VaultLocation = .local
    private(set) var lastError: String?

    private var key: SymmetricKey?
    private let storage = ICloudStorage()
    private var saveTask: Task<Void, Never>?
    private var fileWatcher: NSObjectProtocol?

    // MARK: - Public API

    var items: [VaultItem] {
        get { file.items }
        set {
            file.items = newValue
            file.updatedAt = .now
            scheduleSave()
        }
    }

    var vaults: [Vault] {
        get { file.vaults }
        set {
            file.vaults = newValue
            file.updatedAt = .now
            scheduleSave()
        }
    }

    func bind(key: SymmetricKey) async {
        self.key = key
        await load()
        startWatching()
    }

    func unbind() {
        self.key = nil
        self.file = VaultFile()
        stopWatching()
    }

    // MARK: - Mutations

    func upsert(_ item: VaultItem) {
        var next = file
        if let idx = next.items.firstIndex(where: { $0.id == item.id }) {
            var updated = item
            updated.updatedAt = .now
            next.items[idx] = updated
        } else {
            next.items.append(item)
        }
        next.updatedAt = .now
        file = next
        scheduleSave()
    }

    func delete(_ id: VaultItem.ID) {
        file.items.removeAll { $0.id == id }
        file.updatedAt = .now
        scheduleSave()
    }

    /// Wholesale replace the in-memory vault (used by restore-from-backup).
    /// Triggers a save so the new contents hit disk / iCloud.
    func replaceAll(with newFile: VaultFile) {
        file = newFile
        file.updatedAt = .now
        scheduleSave()
    }

    /// Expose the current in-memory vault file for export/backup.
    var currentFile: VaultFile { file }

    func toggleFavorite(_ id: VaultItem.ID) {
        guard let idx = file.items.firstIndex(where: { $0.id == id }) else { return }
        file.items[idx].isFavorite.toggle()
        file.items[idx].updatedAt = .now
        file.updatedAt = .now
        scheduleSave()
    }

    // MARK: - Persistence

    private func load() async {
        guard let key else { return }
        do {
            let (data, location) = try await storage.read()
            self.location = location
            if data.isEmpty {
                self.file = VaultFile()
                return
            }
            let decrypted = try Crypto.open(data, key: key)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            self.file = try decoder.decode(VaultFile.self, from: decrypted)
        } catch {
            self.lastError = "Load failed: \(error.localizedDescription)"
            self.file = VaultFile()
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await self?.save()
        }
    }

    private func save() async {
        guard let key else { return }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.sortedKeys]
            let plain = try encoder.encode(file)
            let cipher = try Crypto.seal(plain, key: key)
            let location = try await storage.write(cipher)
            self.location = location
        } catch {
            self.lastError = "Save failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Remote change watching

    private func startWatching() {
        Task { [weak self] in
            guard let self else { return }
            let token = await self.storage.startWatching {
                Task { @MainActor [weak self] in await self?.load() }
            }
            await MainActor.run { self.fileWatcher = token }
        }
    }

    private func stopWatching() {
        guard let token = fileWatcher else { return }
        fileWatcher = nil
        Task { [storage] in await storage.stopWatching(token) }
    }
}

enum VaultLocation: String {
    case iCloud
    case local
}
