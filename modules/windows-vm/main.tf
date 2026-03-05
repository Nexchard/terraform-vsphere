resource "vsphere_virtual_machine" "vm" {
  name                    = var.vm_name
  folder                  = var.vsphere_folder
  num_cpus                = var.vm_cpus
  memory                  = var.vm_memory
  firmware                = var.vm_firmware
  efi_secure_boot_enabled = var.vm_efi_secure_boot_enabled
  datastore_id            = var.datastore_id
  resource_pool_id        = var.resource_pool_id
  
  // 启用CPU和内存热插拔
  cpu_hot_add_enabled  = true
  cpu_hot_remove_enabled = true
  memory_hot_add_enabled = true

  network_interface {
    network_id = var.network_id
  }

  disk {
    label            = "disk0"
    size             = var.vm_disk_size
    thin_provisioned = true
    unit_number      = 0
    disk_mode        = "persistent"
  }

  # 动态添加额外磁盘
  dynamic "disk" {
    for_each = var.additional_disks
    content {
      label            = disk.key
      size             = disk.value.size
      thin_provisioned = lookup(disk.value, "thin_provisioned", true)
      disk_mode        = lookup(disk.value, "disk_mode", "persistent")
      unit_number      = startswith(disk.key, "disk") ? tonumber(replace(disk.key, "disk", "")) : 0
    }
  }

  # 添加虚拟机备注信息，包含管理员密码和创建时间
  annotation = var.vm_annotation != "" ? var.vm_annotation : "Managed by Terraform\nOS Type: Windows\nCreated on: ${timestamp()}\nAdministrator Password: ${var.windows_admin_password}"

  clone {
    template_uuid = var.template_uuid
    customize {
      windows_options {
        computer_name  = var.vm_name
        admin_password = var.windows_admin_password
      }

      dynamic "network_interface" {
        for_each = var.vm_ipv4_address != "" ? [1] : []
        content {
          ipv4_address = var.vm_ipv4_address
          ipv4_netmask = var.vm_ipv4_netmask
        }
      }

      ipv4_gateway    = var.vm_ipv4_gateway != "" ? var.vm_ipv4_gateway : null
      dns_suffix_list = var.vm_dns_suffix_list
      dns_server_list = var.vm_dns_server_list
    }
  }

  lifecycle {
    ignore_changes = [
      clone[0].template_uuid,
    ]
  }
}