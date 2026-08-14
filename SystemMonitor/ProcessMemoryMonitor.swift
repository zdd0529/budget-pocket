import Darwin
import Foundation

/// Reads public libproc process information and returns the largest memory users.
final class ProcessMemoryMonitor: Sendable {
    private let maximumProcessCount = 10

    func sample() -> [ProcessMemorySnapshot] {
        let requiredBytes = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard requiredBytes > 0 else { return [] }

        let capacity = Int(requiredBytes) / MemoryLayout<pid_t>.stride
        var processIDs = [pid_t](repeating: 0, count: capacity)
        let returnedBytes = processIDs.withUnsafeMutableBytes { buffer in
            proc_listpids(
                UInt32(PROC_ALL_PIDS),
                0,
                buffer.baseAddress,
                Int32(buffer.count)
            )
        }
        guard returnedBytes > 0 else { return [] }

        let returnedCount = min(
            Int(returnedBytes) / MemoryLayout<pid_t>.stride,
            processIDs.count
        )

        return processIDs.prefix(returnedCount)
            .filter { $0 > 0 }
            .compactMap(processSnapshot(for:))
            .sorted { $0.residentBytes > $1.residentBytes }
            .prefix(maximumProcessCount)
            .map { $0 }
    }

    private func processSnapshot(for processID: pid_t) -> ProcessMemorySnapshot? {
        var taskInfo = proc_taskinfo()
        let infoSize = MemoryLayout<proc_taskinfo>.stride
        let bytesRead = withUnsafeMutablePointer(to: &taskInfo) { pointer in
            proc_pidinfo(
                processID,
                PROC_PIDTASKINFO,
                0,
                pointer,
                Int32(infoSize)
            )
        }
        guard bytesRead == Int32(infoSize), taskInfo.pti_resident_size > 0 else {
            return nil
        }

        var nameBuffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        let nameLength = proc_name(processID, &nameBuffer, UInt32(nameBuffer.count))
        let name = nameLength > 0 ? String(cString: nameBuffer) : "PID \(processID)"

        return ProcessMemorySnapshot(
            pid: processID,
            name: name,
            residentBytes: taskInfo.pti_resident_size
        )
    }
}
