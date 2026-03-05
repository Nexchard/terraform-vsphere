# 获取数据中心信息
data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

# 获取集群信息
data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

# 获取数据存储信息
data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

# 获取内容库信息
data "vsphere_content_library" "library" {
  name = var.content_library_name
}

# 为每台虚拟机获取对应的网络信息
data "vsphere_network" "vm_networks" {
  for_each      = {
    for vm_name, config in var.virtual_machines : vm_name => config.network != "" ? config.network : var.default_network
  }
  name          = each.value
  datacenter_id = data.vsphere_datacenter.dc.id
}

# 为每台虚拟机获取内容库中的模板信息
data "vsphere_content_library_item" "templates" {
  for_each = {
    for vm_name, config in var.virtual_machines : vm_name => config.template_name
  }
  name      = each.value
  library_id = data.vsphere_content_library.library.id
  type      = "ovf"
}

# 创建 Linux 虚拟机（如果存在 Linux 类型）
module "linux_vms" {
  for_each = {
    for vm_name, config in var.virtual_machines : vm_name => config
    if contains(["ubuntu", "centos", "rhel", "debian", "linux"], config.os_type)
  }

  source = "../modules/linux-vm"

  vm_name                = each.key
  vsphere_folder         = each.value.folder != "" ? each.value.folder : var.default_folder
  datastore_id           = data.vsphere_datastore.datastore.id
  resource_pool_id       = data.vsphere_compute_cluster.cluster.resource_pool_id
  network_id             = data.vsphere_network.vm_networks[each.key].id
  template_uuid          = data.vsphere_content_library_item.templates[each.key].id
  vm_cpus                = each.value.cpu
  vm_memory              = each.value.memory
  vm_disk_size           = each.value.disk_size
  additional_disks       = lookup(each.value, "additional_disks", {})  # 新增：传递额外磁盘配置
  ssh_public_key         = var.default_ssh_public_key
  linux_username         = var.default_username
  linux_admin_password   = var.linux_admin_password
  vm_ipv4_address        = each.value.ipv4_address != "" ? each.value.ipv4_address : var.default_ipv4_address
  vm_ipv4_netmask        = each.value.ipv4_netmask != 0 ? each.value.ipv4_netmask : var.default_ipv4_netmask
  vm_ipv4_gateway        = each.value.ipv4_gateway != "" ? each.value.ipv4_gateway : var.default_ipv4_gateway
  vm_dns_server_list     = length(each.value.dns_servers) > 0 ? each.value.dns_servers : var.default_dns_servers
}

# 创建 Windows 虚拟机（如果存在 Windows 类型）
module "windows_vms" {
  for_each = {
    for vm_name, config in var.virtual_machines : vm_name => config
    if contains(["windows", "win"], config.os_type)
  }

  source = "../modules/windows-vm"

  vm_name                = each.key
  vsphere_folder         = each.value.folder != "" ? each.value.folder : var.default_folder
  datastore_id           = data.vsphere_datastore.datastore.id
  resource_pool_id       = data.vsphere_compute_cluster.cluster.resource_pool_id
  network_id             = data.vsphere_network.vm_networks[each.key].id
  template_uuid          = data.vsphere_content_library_item.templates[each.key].id
  vm_cpus                = each.value.cpu
  vm_memory              = each.value.memory
  vm_disk_size           = each.value.disk_size
  additional_disks       = lookup(each.value, "additional_disks", {})  # 新增：传递额外磁盘配置
  windows_admin_password = var.windows_admin_password
  vm_ipv4_address        = each.value.ipv4_address != "" ? each.value.ipv4_address : var.default_ipv4_address
  vm_ipv4_netmask        = each.value.ipv4_netmask != 0 ? each.value.ipv4_netmask : var.default_ipv4_netmask
  vm_ipv4_gateway        = each.value.ipv4_gateway != "" ? each.value.ipv4_gateway : var.default_ipv4_gateway
  vm_dns_server_list     = length(each.value.dns_servers) > 0 ? each.value.dns_servers : var.default_dns_servers
  vm_dns_suffix_list     = []  # 默认为空列表
}