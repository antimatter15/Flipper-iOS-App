import Inject
import Logging
import Peripheral

public func registerDependencies() {
    let container = Container.shared

    LoggingSystem.bootstrap(FileLogHandler.factory)
    container.register(PlainLoggerStorage.init, as: LoggerStorage.self, isSingleton: true)

    Peripheral.registerDependencies()

    // device
    container.register(PairedFlipper.init, as: PairedDevice.self, isSingleton: true)
    // archive
    container.register(MobileArchive.init, as: MobileArchiveProtocol.self, isSingleton: true)
    container.register(DeletedArchive.init, as: DeletedArchiveProtocol.self, isSingleton: true)
    container.register(FlipperArchive.init, as: FlipperArchiveProtocol.self, isSingleton: true)
    // storage
    container.register(PlainDeviceStorage.init, as: DeviceStorage.self, isSingleton: true)
    container.register(PlainMobileArchiveStorage.init, as: MobileArchiveStorage.self, isSingleton: true)
    container.register(PlainMobileNotesStorage.init, as: MobileNotesStorage.self, isSingleton: true)
    container.register(PlainDeletedArchiveStorage.init, as: DeletedArchiveStorage.self, isSingleton: true)
    // manifests
    container.register(PlainMobileManifestStorage.init, as: MobileManifestStorage.self, isSingleton: true)
    container.register(PlainDeletedManifestStorage.init, as: DeletedManifestStorage.self, isSingleton: true)
    container.register(PlainSyncedManifestStorage.init, as: SyncedManifestStorage.self, isSingleton: true)
    // favorites
    container.register(MobileFavorites.init, as: MobileFavoritesProtocol.self, isSingleton: true)
    container.register(FlipperFavorites.init, as: FlipperFavoritesProtocol.self, isSingleton: true)
    container.register(SyncedFavorites.init, as: SyncedFavoritesProtocol.self, isSingleton: true)
    // sync
    container.register(ArchiveSync.init, as: ArchiveSyncProtocol.self, isSingleton: true)
    container.register(FavoritesSync.init, as: FavoritesSyncProtocol.self, isSingleton: true)
}
