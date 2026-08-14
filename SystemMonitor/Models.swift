import Foundation
struct CPUSnapshot { var total = 0.0; var cores: [Double] = [] }
struct MemorySnapshot { var used: UInt64 = 0; var available: UInt64 = 0; var cached: UInt64 = 0; var swap: UInt64 = 0; var pressure = "正常" }
struct DiskSnapshot { var used: UInt64 = 0; var available: UInt64 = 0; var read = 0.0; var write = 0.0 }
struct NetworkSnapshot { var upload = 0.0; var download = 0.0; var ip = "—" }
struct BatterySnapshot { var present = false; var percent = 0; var charging = false; var minutes: Int? }
enum Fmt { static let f: ByteCountFormatter = { let x=ByteCountFormatter(); x.countStyle = .memory; return x }(); static func size(_ n: UInt64)->String { f.string(fromByteCount:Int64(clamping:n)) }; static func speed(_ n:Double)->String { n >= 1e6 ? String(format:"%.1f MB/s",n/1e6) : String(format:"%.0f KB/s",n/1e3) } }
