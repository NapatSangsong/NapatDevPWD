import Foundation

enum ICloudStorageError: Error {
    case noURL
}

/// Handles read/write of the encrypted vault file, preferring iCloud Drive
/// (ubiquity container) and falling back to the app's local Application Support.
///
/// File name: `vault.napatvault` — an AES-GCM sealed JSON blob.
actor ICloudStorage {
    static let fileName = "vault.napatvault"

    // Metadata query has to outlive each call; retain it on the actor.
    private var metadataQuery: NSMetadataQuery?

    func fileURL() throws -> (url: URL, location: VaultLocation) {
        if let url = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            let docs = url.appendingPathComponent("Documents", isDirectory: true)
            try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
            return (docs.appendingPathComponent(Self.fileName), .iCloud)
        }
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("NapatDev", isDirectory: true)
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return (appSupport.appendingPathComponent(Self.fileName), .local)
    }

    func read() async throws -> (Data, VaultLocation) {
        let (url, location) = try fileURL()
        if location == .iCloud && !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.startDownloadingUbiquitousItem(at: url)
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
            return (Data(), location)
        }

        var readError: Error?
        var result = Data()
        var coordinatorError: NSError?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinatorError) { readURL in
            do {
                result = try Data(contentsOf: readURL)
            } catch {
                readError = error
            }
        }
        if let coordinatorError { throw coordinatorError }
        if let readError { throw readError }
        return (result, location)
    }

    func write(_ data: Data) async throws -> VaultLocation {
        let (url, location) = try fileURL()
        var writeError: Error?
        var coordinatorError: NSError?
        NSFileCoordinator().coordinate(writingItemAt: url, options: [.forReplacing], error: &coordinatorError) { writeURL in
            do {
                try data.write(to: writeURL, options: [.atomic])
            } catch {
                writeError = error
            }
        }
        if let coordinatorError { throw coordinatorError }
        if let writeError { throw writeError }
        return location
    }

    /// Register for remote change notifications. Returns an observer token;
    /// unregister with `NotificationCenter.default.removeObserver(token)`.
    func startWatching(_ callback: @Sendable @escaping () -> Void) -> NSObjectProtocol {
        if metadataQuery == nil {
            let query = NSMetadataQuery()
            query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
            query.predicate = NSPredicate(format: "%K LIKE %@", NSMetadataItemFSNameKey, Self.fileName)
            metadataQuery = query
            DispatchQueue.main.async { query.start() }
        }

        return NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidUpdate,
            object: metadataQuery,
            queue: .main
        ) { _ in callback() }
    }

    func stopWatching(_ token: NSObjectProtocol) {
        NotificationCenter.default.removeObserver(token)
        if let query = metadataQuery {
            DispatchQueue.main.async { query.stop() }
            metadataQuery = nil
        }
    }
}
