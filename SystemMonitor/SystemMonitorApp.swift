import SwiftUI
@main struct SystemMonitorApp:App{@StateObject var model=MenuBarManager();var body:some Scene{MenuBarExtra{DashboardView(model:model)}label:{HStack{if model.showIcon{Image(systemName:"gauge.with.dots.needle.50percent")};Text(model.title).font(.system(size:model.font))}}.menuBarExtraStyle(.window);Settings{SettingsView(model:model)}}}
