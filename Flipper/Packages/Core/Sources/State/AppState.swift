import Inject
import Peripheral
import Foundation
import Combine
import Logging

public class AppState {
    public static let shared: AppState = .init()
    private let logger = Logger(label: "appstate")

    @Published public var isFirstLaunch: Bool {
        didSet { UserDefaultsStorage.shared.isFirstLaunch = isFirstLaunch }
    }

    @Inject private var rpc: RPC
    @Inject private var pairedDevice: PairedDevice
    private var disposeBag: DisposeBag = .init()

    @Published public var flipper: Flipper? {
        didSet { updateState(oldValue?.state) }
    }
    @Published public var archive: Archive = .shared
    @Published public var status: DeviceStatus = .noDevice
    @Published public var syncProgress: Int = 0

    @Published public var importQueue: [ArchiveItem] = []

    public init() {
        logger.info("app version: \(Bundle.fullVersion)")

        isFirstLaunch = UserDefaultsStorage.shared.isFirstLaunch

        pairedDevice.flipper
            .receive(on: DispatchQueue.main)
            .assign(to: \.flipper, on: self)
            .store(in: &disposeBag)
    }

    // MARK: Status

    func updateState(_ oldValue: FlipperState?) {
        guard let flipper = flipper else {
            status = .noDevice
            return
        }
        guard flipper.state != oldValue else {
            return
        }

        if status == .unsupportedDevice && flipper.state == .disconnected {
            return
        }

        status = .init(flipper.state)
        switch status {
        case .connected: didConnect()
        case .disconnected: didDisconnect()
        default: break
        }
    }

    func didConnect() {
        status = .connected
        logger.info("connected")

        Task {
            try await waitForProtobufVersion()
            guard validateFirmwareVersion() else {
                disconnect()
                return
            }
            await getStorageInfo()
            await synchronizeDateTime()
            await synchronize()
        }
    }

    func waitForProtobufVersion() async throws {
        defer { status = .init(flipper?.state) }
        while true {
            try await Task.sleep(nanoseconds: 100 * 1_000_000)

            guard flipper?.hasProtobufVersion != nil else { continue }
            guard flipper?.hasProtobufVersion == true else { return }

            guard let info = flipper?.information else { continue }
            guard info.protobufRevision != .unknown else { continue }

            return
        }
    }

    func validateFirmwareVersion() -> Bool {
        guard let version = flipper?.information?.protobufRevision else {
            logger.error("can't validate firmware version")
            status = .disconnected
            return false
        }
        guard version >= .v0_6 else {
            logger.error("unsupported firmware version")
            status = .unsupportedDevice
            return false
        }
        return true
    }

    var reconnectOnDisconnect = true

    func didDisconnect() {
        logger.info("disconnected")
        guard reconnectOnDisconnect else {
            return
        }
        logger.debug("reconnecting")
        connect()
    }

    // MARK: Connection

    public func connect() {
        reconnectOnDisconnect = true
        pairedDevice.connect()
    }

    public func disconnect() {
        reconnectOnDisconnect = false
        pairedDevice.disconnect()
    }

    public func forgetDevice() {
        pairedDevice.forget()
    }

    // MARK: Synchronization

    public func synchronize() async {
        guard flipper?.state == .connected else { return }
        guard status != .unsupportedDevice else { return }
        guard status != .synchronizing else { return }
        status = .synchronizing
        await measure("syncing archive") {
            await archive.synchronize { progress in
                self.syncProgress = Int(progress * 100)
            }
        }
        status = .synchronized
        Task {
            try await Task.sleep(nanoseconds: 3_000 * 1_000_000)
            guard status == .synchronized else { return }
            status = .init(flipper?.state)
        }
    }

    func synchronizeDateTime() async {
        guard status == .connected else { return }
        status = .synchronizing
        await measure("syncing date") {
            try await rpc.setDate(.init())
        }
        status = .init(flipper?.state)
    }

    func getStorageInfo() async {
        status = .synchronizing
        defer { status = .init(flipper?.state) }
        var storageInfo = Flipper.StorageInfo()
        // swiftlint:disable statement_position
        do { storageInfo.internal = try await rpc.getStorageInfo(at: "/int") }
        catch { logger.error("error updating internal space") }
        do { storageInfo.external = try await rpc.getStorageInfo(at: "/ext") }
        catch { logger.error("error updating external space") }
        pairedDevice.updateStorageInfo(storageInfo)
    }

    // MARK: Sharing

    public func onOpenURL(_ url: URL) async {
        do {
            let item = try await Sharing.importKey(from: url)
            importQueue = [item]
            logger.info("key url opened")
        } catch {
            logger.error("\(error)")
        }
    }

    public var imported: SafePublisher<ArchiveItem> {
        importedSubject.eraseToAnyPublisher()
    }
    private let importedSubject = SafeSubject<ArchiveItem>()

    public func importKey(_ item: ArchiveItem) async throws {
        try await archive.importKey(item)
        logger.info("key imported")
        importedSubject.send(item)
        await synchronize()
    }

    // MARK: Debug

    func measure(_ label: String, _ task: () async throws -> Void) async {
        do {
            logger.info("\(label)")
            let start = Date()
            try await task()
            let time = (Date().timeIntervalSince(start) * 1000).rounded() / 1000
            logger.info("\(label): \(time)s")
        } catch {
            logger.error("\(error)")
        }
    }

    // MARK: App Reset

    public func reset() {
        AppReset().reset()
    }
}
