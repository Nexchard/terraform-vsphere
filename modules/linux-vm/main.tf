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

  # 主硬盘配置
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


  # 添加虚拟机备注信息，包含密码信息和创建时间
  annotation = var.vm_annotation != "" ? var.vm_annotation : "Managed by Terraform\nOS Type: Linux\nCreated on: ${timestamp()}\nRoot Password: P@ssword123\nTerraform User Password: P@ssword123"

  clone {
    template_uuid = var.template_uuid
  }

  lifecycle {
    ignore_changes = [
      clone[0].template_uuid,
    ]
  }

  extra_config = {
    "guestinfo.metadata"  = base64encode(
      templatefile("${path.module}/templates/metadata-linux.yml", {
        local_hostname = var.vm_name
        ipv4_address   = var.vm_ipv4_address
        ipv4_netmask   = var.vm_ipv4_netmask
        ipv4_gateway   = var.vm_ipv4_gateway
        dns_servers    = var.vm_dns_server_list
      })
    )
    "guestinfo.metadata.encoding" = "base64"
    # 现在cloud-config-linux.yml不包含任何变量，可以直接读取
    "guestinfo.userdata"  = base64encode(
      templatefile("${path.module}/templates/cloud-config-linux.yml", {
        ssh_public_key       = var.ssh_public_key
        linux_admin_password = var.linux_admin_password
        linux_username       = var.linux_username
      })
    )
    "guestinfo.userdata.encoding" = "base64"
  }
}