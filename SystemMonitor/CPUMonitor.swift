import Darwin
import Foundation

/// Reads cumulative CPU ticks from Mach and derives utilization from consecutive samples.
final class CPUMonitor: @unchecked Sendable {
    private var previousTicks: [[UInt32]] = []

    func sample() -> CPUSnapshot {
        var processorCount: natural_t = 0
        var processorInfo: processor_info_array_t?
        var processorInfoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &processorInfo,
            &processorInfoCount
        )
        guard result == KERN_SUCCESS, let processorInfo else {
            return CPUSnapshot()
        }

        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: processorInfo),
                vm_size_t(processorInfoCount) * vm_size_t(MemoryLayout<integer_t>.size)
            )
        }

        var currentTicks: [[UInt32]] = []
        var usages: [Double] = []

        for core in 0..<Int(processorCount) {
            let offset = core * Int(CPU_STATE_MAX)
            let ticks = (0..<Int(CPU_STATE_MAX)).map {
                UInt32(bitPattern: processorInfo[offset + $0])
            }
            currentTicks.append(ticks)

            guard previousTicks.indices.contains(core) else {
                usages.append(0)
                continue
            }

            // Wrapping subtraction also handles the 32-bit Mach tick counter rolling over.
            let deltas = zip(ticks, previousTicks[core]).map { Double($0 &- $1) }
            let total = deltas.reduce(0, +)
            let idle = deltas[Int(CPU_STATE_IDLE)]
            usages.append(total > 0 ? (total - idle) / total * 100 : 0)
        }

        previousTicks = currentTicks
        let average = usages.isEmpty ? 0 : usages.reduce(0, +) / Double(usages.count)

        // Apple provides no supported public API for temperature or instantaneous frequency.
        return CPUSnapshot(
            totalUsage: average,
            coreUsages: usages,
            temperature: nil,
            frequencyGHz: nil
        )
    }
}
