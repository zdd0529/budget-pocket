import AppKit
import SwiftUI
@MainActor final class MenuBarManager: ObservableObject {
 @Published var cpu=CPUSnapshot();@Published var memory=MemorySnapshot();@Published var disk=DiskSnapshot();@Published var network=NetworkSnapshot();@Published var battery=BatterySnapshot()
 @AppStorage("cpu") var showCPU=true;@AppStorage("memory") var showMemory=true;@AppStorage("network") var showNetwork=false;@AppStorage("disk") var showDisk=false;@AppStorage("icon") var showIcon=true;@AppStorage("percent") var showPercent=true;@AppStorage("interval") var interval=1.0;@AppStorage("font") var font=12.0
 private let cm=CPUMonitor(),mm=MemoryMonitor(),dm=DiskMonitor(),nm=NetworkMonitor(),bm=BatteryMonitor();private var task:Task<Void,Never>?
 init(){start()};var title:String{var a:[String]=[];if showCPU{a.append(showPercent ? String(format:"CPU %.0f%%",cpu.total):"CPU")};if showMemory{a.append(showPercent ? "MEM \(Fmt.size(memory.used))":"MEM")};if showNetwork{a.append("↓\(Fmt.speed(network.download)) ↑\(Fmt.speed(network.upload))")};if showDisk{a.append("DISK")};return a.isEmpty ? "SystemMonitor":a.joined(separator:" | ")}
 func start(){task?.cancel();task=Task{[weak self] in while !Task.isCancelled{guard let self else{return};let v=await Task.detached(priority:.utility){[cm,mm,dm,nm,bm] in(cm.sample(),mm.sample(),dm.sample(),nm.sample(),bm.sample())}.value;cpu=v.0;memory=v.1;disk=v.2;network=v.3;battery=v.4;try? await Task.sleep(for:.seconds(interval))}}}
 func settings(){NSApp.sendAction(Selector(("showSettingsWindow:")),to:nil,from:nil);NSApp.activate(ignoringOtherApps:true)}
}
