import Core
import Inject
import Peripheral
import Combine
import SwiftUI
import Logging

@MainActor
class InfoViewModel: ObservableObject {
    private let logger = Logger(label: "info-vm")

    var backup: ArchiveItem
    @Published var item: ArchiveItem
    @Published var isEditMode = false
    @Published var isError = false
    var error = ""

    @Inject var rpc: RPC
    @Published var appState: AppState = .shared
    var dismissPublisher = PassthroughSubject<Void, Never>()
    var disposeBag = DisposeBag()

    @Published var isConnected = false

    init(item: ArchiveItem?) {
        self.item = item ?? .none
        self.backup = item ?? .none
        watchIsFavorite()
    }

    func watchIsFavorite() {
        $item
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.toggleFavorite()
            }
            .store(in: &disposeBag)

        appState.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isConnected = ($0 == .connected || $0 == .synchronized)
            }
            .store(in: &disposeBag)
    }

    func toggleFavorite() {
        guard backup.isFavorite != item.isFavorite else { return }
        guard !isEditMode else { return }
        Task {
            do {
                try await appState.archive.onIsFavoriteToggle(item.path)
            } catch {
                logger.error("toggling favorite: \(error)")
            }
        }
    }

    func emulate() {
        Task {
            do {
                try await rpc.startRequest(
                    item.fileType.application,
                    args: item.path.string)
            } catch {
                logger.error("emilating key: \(error)")
            }
        }
    }

    func edit() {
        withAnimation {
            isEditMode = true
        }
    }

    func share() {
        Core.share(item)
    }

    func delete() {
        Task {
            do {
                try await appState.archive.delete(item.id)
                try await appState.synchronize()
            } catch {
                logger.error("deleting item: \(error)")
            }
        }
        dismiss()
    }

    func saveChanges() {
        guard item != backup else {
            withAnimation {
                isEditMode = false
            }
            return
        }
        Task {
            do {
                if backup.name != item.name {
                    try await appState.archive.rename(backup.id, to: item.name)
                }
                try await appState.archive.upsert(item)
                backup = item
                withAnimation {
                    isEditMode = false
                }
                item.status = .synchronizing
                try await appState.synchronize()
                withAnimation {
                    item.status = appState.archive.status(for: item)
                }
            } catch {
                logger.error("saving changes: \(error)")
                item.status = .error
                showError(error)
            }
        }
    }

    func undoChanges() {
        item = backup
        withAnimation {
            isEditMode = false
        }
    }

    func showError(_ error: Swift.Error) {
        self.error = String(describing: error)
        self.isError = true
    }

    func dismiss() {
        dismissPublisher.send(())
    }
}
