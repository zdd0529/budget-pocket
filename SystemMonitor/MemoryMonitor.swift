import Darwin
import Foundation

/// Samples virtual-memory counters exposed by the Mach host APIs.
final class MemoryMonitor: Sendable {
    func sample() -> MemorySnapshot {
        var statistics = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )
        let result = withUnsafeMutablePointer(to: &statistics) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return MemorySnapshot() }

        let pageSize = UInt64(vm_kernel_page_size)
        let usedPages = UInt64(statistics.active_count)
            + UInt64(statistics.wire_count)
            + UInt64(statistics.compressor_page_count)
        let availablePages = UInt64(statistics.free_count)
            + UInt64(statistics.speculative_count)
        let cachedPages = UInt64(statistics.inactive_count)
            + UInt64(statistics.purgeable_count)

        var swap = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        sysctlbyname("vm.swapusage", &swap, &swapSize, nil, 0)

        let total = ProcessInfo.processInfo.physicalMemory
        let available = availablePages * pageSize
        let availableRatio = Double(available) / Double(max(total, 1))
        let pressure: MemoryPressure = availableRatio < 0.05
            ? .critical
            : availableRatio < 0.12 ? .warning : .normal

        return MemorySnapshot(
            used: usedPages * pageSize,
            available: available,
            cached: cachedPages * pageSize,
            swapUsed: swap.xsu_used,
            pressure: pressure
        )
    }
}
