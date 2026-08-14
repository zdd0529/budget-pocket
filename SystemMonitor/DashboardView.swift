import AppKit
import SwiftUI

struct DashboardView: View {
    @ObservedObject var manager: MenuBarManager

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                LazyVStack(spacing: 12) {
                    cpuCard
                    memoryCard
                    diskCard
                    networkCard
                    if manager.battery.isPresent { batteryCard }
                }
                .padding(14)
            }
            Divider()
            footer
        }
        .frame(width: 350, height: 650)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "gauge.with.dots.needle.50percent")
                .font(.title2).foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text("SystemMonitor").font(.headline)
                Text("实时系统状态").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Circle().fill(.green).frame(width: 7, height: 7)
        }
        .padding(14)
        .background(.regularMaterial)
    }

    private var cpuCard: some View {
        MonitorCard(title: "CPU", icon: "cpu", tint: .blue) {
            MetricRow(title: "总占用率", value: String(format: "%.1f%%", manager.cpu.totalUsage))
            HStack(spacing: 5) {
                ForEach(Array(manager.cpu.coreUsages.enumerated()), id: \.offset) { _, usage in
                    Capsule().fill(.blue.opacity(0.15)).overlay(alignment: .bottom) {
                        Capsule().fill(.blue).frame(height: max(2, 40 * usage / 100))
                    }
                    .frame(height: 40)
                    .help(String(format: "%.1f%%", usage))
                }
            }
            .accessibilityLabel("各核心占用率")
            MetricRow(title: "温度", value: manager.cpu.temperature.map { String(format: "%.0f °C", $0) } ?? "不可用")
            MetricRow(title: "频率", value: manager.cpu.frequencyGHz.map { String(format: "%.2f GHz", $0) } ?? "不可用")
        }
    }

    private var memoryCard: some View {
        MonitorCard(title: "内存", icon: "memorychip", tint: .purple) {
            MetricRow(title: "已使用", value: ValueFormatter.size(manager.memory.used))
            MetricRow(title: "剩余", value: ValueFormatter.size(manager.memory.available))
            MetricRow(title: "Cache", value: ValueFormatter.size(manager.memory.cached))
            MetricRow(title: "Swap", value: ValueFormatter.size(manager.memory.swapUsed))
            MetricRow(title: "内存压力", value: manager.memory.pressure.rawValue)
            Divider()
            Text("软件内存占用")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if manager.processes.isEmpty {
                Text("暂无进程数据")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(manager.processes) { process in
                    ProcessMemoryRow(process: process)
                }
            }
        }
    }

    private var diskCard: some View {
        MonitorCard(title: "磁盘", icon: "internaldrive", tint: .orange) {
            MetricRow(title: "已使用", value: ValueFormatter.size(manager.disk.used))
            MetricRow(title: "剩余空间", value: ValueFormatter.size(manager.disk.available))
            MetricRow(title: "读取速度", value: ValueFormatter.speed(manager.disk.readBytesPerSecond))
            MetricRow(title: "写入速度", value: ValueFormatter.speed(manager.disk.writeBytesPerSecond))
        }
    }

    private var networkCard: some View {
        MonitorCard(title: "网络", icon: "network", tint: .green) {
            MetricRow(title: "下载", value: ValueFormatter.speed(manager.network.downloadBytesPerSecond))
            MetricRow(title: "上传", value: ValueFormatter.speed(manager.network.uploadBytesPerSecond))
            MetricRow(title: "当前 IP", value: manager.network.ipAddress)
        }
    }

    private var batteryCard: some View {
        MonitorCard(title: "电池", icon: "battery.75percent", tint: .mint) {
            MetricRow(title: "电量", value: "\(manager.battery.percentage)%")
            MetricRow(title: "状态", value: manager.battery.isCharging ? "正在充电" : "使用电池")
            MetricRow(title: "剩余时间", value: manager.battery.remainingMinutes.map {
                "\($0 / 60) 小时 \($0 % 60) 分"
            } ?? "正在计算")
        }
    }

    private var footer: some View {
        HStack {
            SettingsLink { Text("设置…") }
            Spacer()
            Button("关于") { NSApp.orderFrontStandardAboutPanel(nil) }
            Button("退出") { NSApp.terminate(nil) }
        }
        .buttonStyle(.plain)
        .padding(14)
    }
}

private struct ProcessMemoryRow: View {
    let process: ProcessMemorySnapshot

    var body: some View {
        HStack(spacing: 8) {
            Text(process.name)
                .lineLimit(1)
                .help("\(process.name) (PID \(process.pid))")
            Spacer(minLength: 8)
            Text(ValueFormatter.size(process.residentBytes))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .font(.callout)
    }
}

private struct MonitorCard<Content: View>: View {
    let title: String
    let icon: String
    let tint: Color
    let content: Content

    init(title: String, icon: String, tint: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 9) {
            HStack { Label(title, systemImage: icon).font(.headline).foregroundStyle(tint); Spacer() }
            Divider()
            content
        }
        .padding(12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct MetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack { Text(title).foregroundStyle(.secondary); Spacer(); Text(value).monospacedDigit() }
            .font(.callout)
    }
}
