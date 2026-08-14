import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings: SettingsStore
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchAtLoginError: String?

    init(manager: MenuBarManager) {
        _settings = ObservedObject(wrappedValue: manager.settings)
    }

    var body: some View {
        Form {
            Section("菜单栏项目") {
                Toggle("CPU", isOn: $settings.showCPU)
                Toggle("Memory", isOn: $settings.showMemory)
                Toggle("Network", isOn: $settings.showNetwork)
                Toggle("Disk", isOn: $settings.showDisk)
                Toggle("显示图标", isOn: $settings.showIcon)
                Toggle("显示百分比 / 数值", isOn: $settings.showValues)
            }

            Section("外观与更新") {
                Picker("外观", selection: $settings.appearance) {
                    ForEach(SettingsStore.Appearance.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("刷新频率", selection: $settings.refreshInterval) {
                    Text("0.5 秒").tag(0.5)
                    Text("1 秒").tag(1.0)
                    Text("2 秒").tag(2.0)
                    Text("5 秒").tag(5.0)
                }
                HStack {
                    Text("字体大小")
                    Slider(value: $settings.fontSize, in: 10...16, step: 1)
                    Text("\(Int(settings.fontSize)) pt").monospacedDigit().frame(width: 42)
                }
            }

            Section("系统") {
                Toggle("开机启动", isOn: Binding(
                    get: { launchAtLogin },
                    set: updateLaunchAtLogin
                ))
                if let launchAtLoginError {
                    Text(launchAtLoginError).font(.caption).foregroundStyle(.red)
                }
            }

            Section {
                Text("SystemMonitor 1.0\n数据仅在本机采样，不收集或上传任何信息。CPU 温度和实时频率因没有稳定的公开 API 而显示为不可用。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 540)
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = enabled
            launchAtLoginError = nil
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            launchAtLoginError = error.localizedDescription
        }
    }
}
