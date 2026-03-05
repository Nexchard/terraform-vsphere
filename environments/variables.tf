# vSphere 连接变量
variable "vsphere_server" {
  description = "vSphere 服务器地址"
  type        = string
}

variable "vsphere_user" {
  description = "vSphere 用户名"
  type        = string
}

variable "vsphere_password" {
  description = "vSphere 密码"
  type        = string
  sensitive   = true
}

variable "allow_unverified_ssl" {
  description = "是否允许未验证的 SSL 证书"
  type        = bool
  default     = true
}

# 数据中心相关变量
variable "datacenter" {
  description = "vSphere 数据中心名称"
  type        = string
  default     = "Datacenter"
}

variable "cluster" {
  description = "vSphere 集群名称"
  type        = string
  default     = "Cluster"
}

variable "datastore" {
  description = "vSphere 数据存储名称"
  type        = string
  default     = "datastore1"
}

# 内容库相关变量
variable "content_library_name" {
  description = "内容库名称，用于存储虚拟机模板"
  type        = string
  default     = "templates"
}

# 全局默认网络和文件夹
variable "default_network" {
  description = "默认网络，当虚拟机配置未指定网络时使用"
  type        = string
  default     = "VM Network"
}

variable "default_folder" {
  description = "默认文件夹，当虚拟机配置未指定文件夹时使用"
  type        = string
  default     = "terraform-vms"
}

# 虚拟机定义 - 支持根据主机名映射不同配置
variable "virtual_machines" {
  description = "虚拟机配置映射，键为虚拟机名称，值为虚拟机配置对象"
  type = map(object({
    template_name = string
    os_type       = string      # 操作系统类型，仅允许 linux 或 windows
    cpu           = number
    memory        = number
    disk_size     = number
    folder        = string      # 虚拟机所在文件夹，为空则使用默认值
    network       = string      # 虚拟机所在网络，为空则使用默认值
    ipv4_address  = string      # 个性化 IP 地址，为空则使用 DHCP
    ipv4_netmask  = number
    ipv4_gateway  = string
    dns_servers   = list(string)
    # 新增：额外磁盘配置
    additional_disks = optional(map(object({
      size             = number
      thin_provisioned = optional(bool, true)
      disk_mode        = optional(string, "persistent")  # 磁盘模式: persistent(从属), independent_persistent(独立持久), independent_nonpersistent(独立非持久)
    })), {})
  }))
  default = {}
}

# 操作系统相关变量
variable "default_username" {
  description = "默认用户名，用于创建 Linux 虚拟机时的用户账户"
  type        = string
  default     = "terraform"
}

variable "linux_admin_password" {
  description = "Linux管理员密码，用于Linux虚拟机的用户账户（应为加密后的SHA-512格式）"
  type        = string
  sensitive   = true
  default     = "$6$kOT7X9Zo$qEZ3IEe0JcN0Q/yT5Gh1tHoT/SOh/Ydw6.EVlC0dfCVXRPdWMIpGh3yF1nY6hivme.k/VK3TsLp.ILN2jJzxU1"
}

variable "windows_admin_password" {
  description = "Windows管理员密码，用于Windows虚拟机的Administrator账户"
  type        = string
  sensitive   = true
  default     = "P@ssword123"
}

variable "default_ssh_public_key" {
  description = "SSH 公钥，用于 Linux 虚拟机登录"
  type        = string
  default     = "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBADRbmWOYuGVCqryq1MITSXoOCBXiiP0kJS2qP+5QCNDyjxtG3a2+MyAi6cNGya0XP5miVkpM9BqprgYqylPQxSVBAAYvCZEkFcbmlNnWXTmh2XUwO8MkLtuduC7pKIy5RTAotuKhVIWa6l6zlO8Una6y3/B0t3akqFaOrw67naokWAtrA== <packer@example.com>"
}

# 默认网络配置（当虚拟机未指定时使用）
variable "default_ipv4_address" {
  description = "默认 IPv4 地址，当虚拟机配置未指定 IP 地址时使用"
  type        = string
  default     = ""
}

variable "default_ipv4_netmask" {
  description = "默认 IPv4 子网掩码，当虚拟机配置未指定子网掩码时使用"
  type        = number
  default     = 24
}

variable "default_ipv4_gateway" {
  description = "默认 IPv4 网关，当虚拟机配置未指定网关时使用"
  type        = string
  default     = ""
}

variable "default_dns_servers" {
  description = "默认 DNS 服务器列表，当虚拟机配置未指定 DNS 服务器时使用"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}