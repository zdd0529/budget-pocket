import Foundation
import SwiftUI

/// UserDefaults-backed settings. Published properties immediately refresh both scenes.
@MainActor
final class SettingsStore: ObservableObject {
    enum Appearance: String, CaseIterable, Identifiable {
        case system = "跟随系统"
        case light = "浅色"
        case dark = "深色"
        var id: String { rawValue }
        var colorScheme: ColorScheme? { self == .light ? .light : self == .dark ? .dark : nil }
    }

    private enum Key {
        static let showCPU = "showCPU"
        static let showMemory = "showMemory"
        static let showNetwork = "showNetwork"
        static let showDisk = "showDisk"
        static let showIcon = "showIcon"
        static let showValues = "showValues"
        static let interval = "refreshInterval"
        static let fontSize = "fontSize"
        static let appearance = "appearance"
    }

    private let defaults: UserDefaults
    @Published var showCPU: Bool { didSet { defaults.set(showCPU, forKey: Key.showCPU) } }
    @Published var showMemory: Bool { didSet { defaults.set(showMemory, forKey: Key.showMemory) } }
    @Published var showNetwork: Bool { didSet { defaults.set(showNetwork, forKey: Key.showNetwork) } }
    @Published var showDisk: Bool { didSet { defaults.set(showDisk, forKey: Key.showDisk) } }
    @Published var showIcon: Bool { didSet { defaults.set(showIcon, forKey: Key.showIcon) } }
    @Published var showValues: Bool { didSet { defaults.set(showValues, forKey: Key.showValues) } }
    @Published var refreshInterval: Double { didSet { defaults.set(refreshInterval, forKey: Key.interval) } }
    @Published var fontSize: Double { didSet { defaults.set(fontSize, forKey: Key.fontSize) } }
    @Published var appearance: Appearance { didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.showCPU: true, Key.showMemory: true, Key.showNetwork: false,
            Key.showDisk: false, Key.showIcon: true, Key.showValues: true,
            Key.interval: 1.0, Key.fontSize: 12.0,
            Key.appearance: Appearance.system.rawValue
        ])
        showCPU = defaults.bool(forKey: Key.showCPU)
        showMemory = defaults.bool(forKey: Key.showMemory)
        showNetwork = defaults.bool(forKey: Key.showNetwork)
        showDisk = defaults.bool(forKey: Key.showDisk)
        showIcon = defaults.bool(forKey: Key.showIcon)
        showValues = defaults.bool(forKey: Key.showValues)
        refreshInterval = defaults.double(forKey: Key.interval)
        fontSize = defaults.double(forKey: Key.fontSize)
        appearance = Appearance(rawValue: defaults.string(forKey: Key.appearance) ?? "") ?? .system
    }
}
