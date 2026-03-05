variable "vm_name" {
  description = "Virtual machine name"
  type        = string
}

variable "vm_cpus" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Memory size in MB"
  type        = number
  default     = 2048
}

variable "vm_disk_size" {
  description = "Main disk size in GB"
  type        = number
  default     = 40
}

// 新增：额外磁盘配置
variable "additional_disks" {
  description = "Additional disks to attach to the VM"
  type = map(object({
    size             = number
    thin_provisioned = optional(bool, true)
    disk_mode        = optional(string, "persistent")
  }))
  default = {}
}

variable "vm_firmware" {
  description = "VM firmware type"
  type        = string
  default     = "efi"
}

variable "vm_efi_secure_boot_enabled" {
  description = "Enable EFI secure boot"
  type        = bool
  default     = true
}

variable "datastore_id" {
  description = "Datastore ID"
  type        = string
}

variable "resource_pool_id" {
  description = "Resource pool ID"
  type        = string
}

variable "network_id" {
  description = "Network ID"
  type        = string
}

variable "template_uuid" {
  description = "UUID of the template"
  type        = string
}

variable "vm_ipv4_address" {
  description = "Static IPv4 address"
  type        = string
  default     = ""
}

variable "vm_ipv4_netmask" {
  description = "IPv4 netmask in CIDR format"
  type        = string
  default     = "24"
}

variable "vm_ipv4_gateway" {
  description = "IPv4 gateway"
  type        = string
  default     = ""
}

variable "vm_dns_server_list" {
  description = "DNS servers"
  type        = list(string)
  default     = ["8.8.8.8", "114.114.114.114"]
}

variable "ssh_public_key" {
  description = "SSH public key for cloud-init"
  type        = string
}

variable "linux_username" {
  description = "Linux username"
  type        = string
  default     = "terraform"
}

variable "linux_admin_password" {
  description = "Encrypted password for the user"
  type        = string
  default     = "$6$w755qGiV$3Yx7l5A1riJHi.qXZPvNf8m6Sw9KnBWo7TcDJvLeHDpL2RI2aHfi5U1K8E2Ug84FhoDY3fcCyH22ajjA.qMNl0"
}

variable "vm_annotation" {
  description = "Annotation for the virtual machine"
  type        = string
  default     = ""
}

variable "vsphere_folder" {
  description = "vSphere folder path for the VM"
  type        = string
}

