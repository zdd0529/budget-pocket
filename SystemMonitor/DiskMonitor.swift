import Foundation
final class DiskMonitor: Sendable { func sample()->DiskSnapshot { let v=try? URL(fileURLWithPath:"/").resourceValues(forKeys:[.volumeTotalCapacityKey,.volumeAvailableCapacityForImportantUsageKey]);let t=UInt64(max(v?.volumeTotalCapacity ?? 0,0)),a=UInt64(max(v?.volumeAvailableCapacityForImportantUsage ?? 0,0));return .init(used:t>a ? t-a:0,available:a) } }
