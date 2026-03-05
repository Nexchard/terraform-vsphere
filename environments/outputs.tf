output "datacenter" {
  description = "使用的 vSphere 数据中心"
  value       = var.datacenter
}

output "virtual_machines" {
  description = "创建的虚拟机信息"
  value = merge([
    for vms in [module.linux_vms, module.windows_vms] : {
      for vm_name, vm in vms : vm_name => {
        name = vm.vm_name
        ip   = vm.vm_ip
        id   = vm.vm_id
      }
    }
  ]...)
}