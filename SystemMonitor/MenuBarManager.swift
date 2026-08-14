import Combine
import Foundation

/// Coordinates independent samplers and publishes one coherent set of snapshots to SwiftUI.
@MainActor
final class MenuBarManager: ObservableObject {
    @Published private(set) var cpu = CPUSnapshot()
    @Published private(set) var memory = MemorySnapshot()
    @Published private(set) var disk = DiskSnapshot()
    @Published private(set) var network = NetworkSnapshot()
    @Published private(set) var battery = BatterySnapshot()
    @Published private(set) var processes: [ProcessMemorySnapshot] = []

    let settings: SettingsStore
    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()
    private let diskMonitor = DiskMonitor()
    private let networkMonitor = NetworkMonitor()
    private let batteryMonitor = BatteryMonitor()
    private let processMemoryMonitor = ProcessMemoryMonitor()
    private var refreshTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    init(settings: SettingsStore = SettingsStore()) {
        self.settings = settings
        settings.$refreshInterval
            .dropFirst()
            .sink { [weak self] _ in self?.restart() }
            .store(in: &cancellables)
        restart()
    }

    deinit { refreshTask?.cancel() }

    var menuBarText: String {
        var parts: [String] = []
        if settings.showCPU {
            parts.append(settings.showValues ? String(format: "CPU %.0f%%", cpu.totalUsage) : "CPU")
        }
        if settings.showMemory {
            parts.append(settings.showValues ? "MEM \(ValueFormatter.size(memory.used))" : "MEM")
        }
        if settings.showNetwork {
            parts.append(settings.showValues
                ? "↓\(ValueFormatter.speed(network.downloadBytesPerSecond)) ↑\(ValueFormatter.speed(network.uploadBytesPerSecond))"
                : "NET")
        }
        if settings.showDisk {
            parts.append(settings.showValues
                ? "D ↓\(ValueFormatter.speed(disk.readBytesPerSecond)) ↑\(ValueFormatter.speed(disk.writeBytesPerSecond))"
                : "DISK")
        }
        return parts.isEmpty ? "SystemMonitor" : parts.joined(separator: " | ")
    }

    private func restart() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await refresh()
                try? await Task.sleep(for: .seconds(settings.refreshInterval))
            }
        }
    }

    private func refresh() async {
        let cpuMonitor = cpuMonitor
        let memoryMonitor = memoryMonitor
        let diskMonitor = diskMonitor
        let networkMonitor = networkMonitor
        let batteryMonitor = batteryMonitor
        let processMemoryMonitor = processMemoryMonitor
        let values = await Task.detached(priority: .utility) {
            (
                cpuMonitor.sample(), memoryMonitor.sample(), diskMonitor.sample(),
                networkMonitor.sample(), batteryMonitor.sample(), processMemoryMonitor.sample()
            )
        }.value
        guard !Task.isCancelled else { return }
        (cpu, memory, disk, network, battery, processes) = values
    }
}
