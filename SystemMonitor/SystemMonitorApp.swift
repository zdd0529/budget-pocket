import SwiftUI

@main
struct SystemMonitorApp: App {
    @StateObject private var manager = MenuBarManager()

    var body: some Scene {
        MenuBarExtra {
            DashboardView(manager: manager)
                .preferredColorScheme(manager.settings.appearance.colorScheme)
        } label: {
            HStack(spacing: 4) {
                if manager.settings.showIcon {
                    Image(systemName: "gauge.with.dots.needle.50percent")
                }
                Text(manager.menuBarText)
                    .font(.system(size: manager.settings.fontSize, weight: .medium, design: .rounded))
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(manager: manager)
                .preferredColorScheme(manager.settings.appearance.colorScheme)
        }
    }
}
