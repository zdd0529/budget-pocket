import Foundation
import IOKit

/// Reads volume capacity and cumulative block-storage counters from the I/O Registry.
final class DiskMonitor: @unchecked Sendable {
    private var previousReadBytes: UInt64?
    private var previousWriteBytes: UInt64?
    private var previousDate: Date?

    func sample() -> DiskSnapshot {
        let volume = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ])
        let total = UInt64(max(volume?.volumeTotalCapacity ?? 0, 0))
        let available = UInt64(max(volume?.volumeAvailableCapacityForImportantUsage ?? 0, 0))
        let counters = storageCounters()
        let now = Date()

        var readRate = 0.0
        var writeRate = 0.0
        if let oldRead = previousReadBytes,
           let oldWrite = previousWriteBytes,
           let oldDate = previousDate {
            let interval = max(now.timeIntervalSince(oldDate), 0.001)
            readRate = Double(counters.read &- oldRead) / interval
            writeRate = Double(counters.write &- oldWrite) / interval
        }

        previousReadBytes = counters.read
        previousWriteBytes = counters.write
        previousDate = now
        return DiskSnapshot(
            used: total >= available ? total - available : 0,
            available: available,
            readBytesPerSecond: readRate,
            writeBytesPerSecond: writeRate
        )
    }

    private func storageCounters() -> (read: UInt64, write: UInt64) {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOBlockStorageDriver"),
            &iterator
        ) == KERN_SUCCESS else { return (0, 0) }
        defer { IOObjectRelease(iterator) }

        var read: UInt64 = 0
        var write: UInt64 = 0
        while true {
            let service = IOIteratorNext(iterator)
            guard service != 0 else { break }
            defer { IOObjectRelease(service) }

            guard let raw = IORegistryEntryCreateCFProperty(
                service,
                "Statistics" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue(),
                  let statistics = raw as? [String: Any] else { continue }
            read += (statistics["Bytes (Read)"] as? NSNumber)?.uint64Value ?? 0
            write += (statistics["Bytes (Write)"] as? NSNumber)?.uint64Value ?? 0
        }
        return (read, write)
    }
}
