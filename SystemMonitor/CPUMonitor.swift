import Darwin
final class CPUMonitor: @unchecked Sendable {
 private var old:[[UInt32]]=[]
 func sample()->CPUSnapshot { var n:natural_t=0; var p:processor_info_array_t?; var c:mach_msg_type_number_t=0
  guard host_processor_info(mach_host_self(),PROCESSOR_CPU_LOAD_INFO,&n,&p,&c)==KERN_SUCCESS, let p else{return .init()}
  defer{vm_deallocate(mach_task_self_,vm_address_t(bitPattern:p),vm_size_t(c)*vm_size_t(MemoryLayout<integer_t>.size))}
  var now:[[UInt32]]=[], use:[Double]=[]
  for i in 0..<Int(n){let a=(0..<Int(CPU_STATE_MAX)).map{UInt32(bitPattern:p[i*Int(CPU_STATE_MAX)+$0])};now.append(a);if old.indices.contains(i){let d=zip(a,old[i]).map{Double($0 &- $1)},t=d.reduce(0,+);use.append(t>0 ? (t-d[Int(CPU_STATE_IDLE)])/t*100:0)}else{use.append(0)}}
  old=now;return .init(total:use.isEmpty ? 0:use.reduce(0,+)/Double(use.count),cores:use)
 }
}
