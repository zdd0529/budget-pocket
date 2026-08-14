import Foundation
import IOKit.ps

/// Uses the public IOKit power-source API; desktops naturally return no battery.
final class BatteryMonitor: Sendable {
    func sample() -> BatterySnapshot {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let values = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue()
                as? [String: Any] else {
            return BatterySnapshot()
        }

        let current = (values[kIOPSCurrentCapacityKey] as? NSNumber)?.doubleValue ?? 0
        let maximum = (values[kIOPSMaxCapacityKey] as? NSNumber)?.doubleValue ?? 100
        let state = values[kIOPSPowerSourceStateKey] as? String
        let rawMinutes = (values[kIOPSTimeToEmptyKey] as? NSNumber)?.intValue

        return BatterySnapshot(
            isPresent: true,
            percentage: Int((current / max(maximum, 1) * 100).rounded()),
            isCharging: state == kIOPSACPowerValue,
            remainingMinutes: rawMinutes.flatMap { $0 >= 0 ? $0 : nil }
        )
    }
}
