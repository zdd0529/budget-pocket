# SystemMonitor

SystemMonitor 是一个轻量、原生的 macOS 菜单栏系统监控器，使用 Swift 和 SwiftUI 编写，最低支持 macOS 14。

## 打开与运行

1. 在 macOS 上使用最新版 Xcode 打开 `SystemMonitor.xcodeproj`。
2. 选择 **SystemMonitor** scheme 和 **My Mac** 运行目标。
3. 如需测试开机启动，请在 **Signing & Capabilities** 中选择开发团队并使用有效签名。

应用通过 `LSUIElement` 作为仅菜单栏应用运行，不显示 Dock 图标。设置使用 `UserDefaults` 保存在本机。

## 功能

- 菜单栏可组合显示 CPU、内存、网络和磁盘，并可隐藏任意项目。
- 弹出面板显示总 CPU、各核心、内存、内存占用最高的运行进程、磁盘吞吐、网络吞吐、IP 和电池详情。
- 支持 0.5、1、2、5 秒刷新间隔、字体大小、图标、数值、浅色/深色以及开机启动。
- 采样在 utility 优先级后台任务中完成，UI 仅接收小型不可变快照。
- 不使用第三方库，也不发起网络请求。

## 系统 API 与限制

| 数据 | API |
| --- | --- |
| CPU | Mach `host_processor_info` |
| 内存与 Swap | Mach `host_statistics64`、`sysctl` |
| 进程内存 | Darwin libproc `proc_listpids`、`proc_pidinfo` |
| 磁盘容量与吞吐 | Foundation Volume Resource Values、IOKit Registry |
| 网络与 IP | BSD `getifaddrs` |
| 电池 | IOKit Power Sources |
| 开机启动 | ServiceManagement `SMAppService` |

macOS 没有稳定、受支持的公开 API 用于获取 CPU 温度和瞬时频率。应用会将这两项标为“不可用”，而不是依赖私有 API 或需要管理员权限的辅助程序。部分第三方/外置磁盘驱动可能不会向 IOKit Registry 发布吞吐计数，此时相应速度为 0。

## 项目结构

所有监控器均互相独立；`MenuBarManager` 只负责调度与发布快照，SwiftUI 视图不直接调用底层系统接口。
