output "vm_id" {
  description = "ID of the created VM"
  value       = vsphere_virtual_machine.vm.id
}

output "vm_ip" {
  description = "IP address of the VM"
  value       = vsphere_virtual_machine.vm.default_ip_address
}

output "vm_name" {
  description = "Name of the VM"
  value       = vsphere_virtual_machine.vm.name
}