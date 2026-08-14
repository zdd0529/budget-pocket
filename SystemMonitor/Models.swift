import Foundation

/// Immutable values produced by the CPU sampler.
struct CPUSnapshot: Sendable {
    var totalUsage: Double = 0
    var coreUsages: [Double] = []
    var temperature: Double?
    var frequencyGHz: Double?
}

struct MemorySnapshot: Sendable {
    var used: UInt64 = 0
    var available: UInt64 = 0
    var cached: UInt64 = 0
    var swapUsed: UInt64 = 0
    var pressure: MemoryPressure = .normal
}

/// Memory owned by a single running process, ordered by resident size.
struct ProcessMemorySnapshot: Identifiable, Sendable {
    let pid: Int32
    let name: String
    let residentBytes: UInt64

    var id: Int32 { pid }
}

enum MemoryPressure: String, Sendable {
    case normal = "正常"
    case warning = "警告"
    case critical = "严重"
}

struct DiskSnapshot: Sendable {
    var used: UInt64 = 0
    var available: UInt64 = 0
    var readBytesPerSecond: Double = 0
    var writeBytesPerSecond: Double = 0
}

struct NetworkSnapshot: Sendable {
    var uploadBytesPerSecond: Double = 0
    var downloadBytesPerSecond: Double = 0
    var ipAddress: String = "—"
}

struct BatterySnapshot: Sendable {
    var isPresent = false
    var percentage = 0
    var isCharging = false
    var remainingMinutes: Int?
}

enum ValueFormatter {
    static let bytes: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        formatter.allowedUnits = [.useGB, .useMB]
        return formatter
    }()

    static func size(_ value: UInt64) -> String {
        bytes.string(fromByteCount: Int64(clamping: value))
    }

    static func speed(_ bytesPerSecond: Double) -> String {
        switch bytesPerSecond {
        case 1_000_000...:
            return String(format: "%.1f MB/s", bytesPerSecond / 1_000_000)
        case 1_000...:
            return String(format: "%.0f KB/s", bytesPerSecond / 1_000)
        default:
            return String(format: "%.0f B/s", max(0, bytesPerSecond))
        }
    }
}
