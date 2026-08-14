import Darwin
import Foundation

/// Aggregates byte counters for active, non-loopback interfaces and finds a local IPv4 address.
final class NetworkMonitor: @unchecked Sendable {
    private var previousInputBytes: UInt64?
    private var previousOutputBytes: UInt64?
    private var previousDate: Date?

    func sample() -> NetworkSnapshot {
        var addressList: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addressList) == 0, let first = addressList else {
            return NetworkSnapshot()
        }
        defer { freeifaddrs(addressList) }

        var inputBytes: UInt64 = 0
        var outputBytes: UInt64 = 0
        var ipAddress = "—"
        var cursor: UnsafeMutablePointer<ifaddrs>? = first

        while let interface = cursor?.pointee {
            let flags = Int32(interface.ifa_flags)
            let isActive = (flags & IFF_UP) != 0 && (flags & IFF_LOOPBACK) == 0
            let family = interface.ifa_addr.map { Int32($0.pointee.sa_family) }

            if isActive, family == AF_LINK,
               let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self) {
                inputBytes += UInt64(data.pointee.ifi_ibytes)
                outputBytes += UInt64(data.pointee.ifi_obytes)
            }

            if isActive, ipAddress == "—", family == AF_INET, let address = interface.ifa_addr {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(
                    address,
                    socklen_t(address.pointee.sa_len),
                    &host,
                    socklen_t(host.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                ) == 0 {
                    ipAddress = String(cString: host)
                }
            }
            cursor = interface.ifa_next
        }

        let now = Date()
        var downloadRate = 0.0
        var uploadRate = 0.0
        if let oldInput = previousInputBytes,
           let oldOutput = previousOutputBytes,
           let oldDate = previousDate {
            let interval = max(now.timeIntervalSince(oldDate), 0.001)
            downloadRate = Double(inputBytes &- oldInput) / interval
            uploadRate = Double(outputBytes &- oldOutput) / interval
        }
        previousInputBytes = inputBytes
        previousOutputBytes = outputBytes
        previousDate = now

        return NetworkSnapshot(
            uploadBytesPerSecond: uploadRate,
            downloadBytesPerSecond: downloadRate,
            ipAddress: ipAddress
        )
    }
}
