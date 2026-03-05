# Terraform vSphere 多项目虚拟机管理

使用 Terraform 管理 vSphere 环境中的虚拟机，支持多项目、多操作系统和动态磁盘配置。

## 特性

- **多项目隔离**：使用 Terraform Workspaces 实现项目间资源隔离
- **多操作系统支持**：支持 Linux 和 Windows 虚拟机
- **动态磁盘配置**：支持为主机添加多个额外磁盘
- **自动扩容**：Linux 虚拟机支持自动磁盘扩容
- **统一配置**：一套代码管理多个项目和环境

## 快速开始

### 准备工作

1. 进入 environments 目录：
```bash
cd environments
```

2. 配置 vSphere 连接信息：
```bash
cp terraform.tfvars.example terraform.tfvars
# 编辑 terraform.tfvars 填入您的 vSphere 信息
```

3. 初始化 Terraform：
```bash
terraform init
```

### 创建项目

使用自动化脚本创建新项目：
```bash
cd ..
./create-project.sh my-project
```

或者手动创建：
```bash
# 创建配置文件
cp project-a.tfvars my-project.tfvars
# 编辑配置文件

# 创建工作空间
cd environments
terraform workspace new my-project
```

### 部署虚拟机

```bash
# 切换到项目工作空间
terraform workspace select my-project

# 预览变更
terraform plan -var-file="my-project.tfvars"

# 应用配置
terraform apply -var-file="my-project.tfvars"
```

## 配置说明

### 虚拟机配置

在 `.tfvars` 文件中定义虚拟机配置：

```hcl
virtual_machines = {
  "web-server-01" = {
    template_name = "rocky-linux-9.5"
    os_type       = "linux"
    cpu           = 2
    memory        = 2048
    disk_size     = 40
    additional_disks = {
      disk1 = {
        size = 20
        thin_provisioned = true
        disk_mode = "independent_persistent"
      },
      disk2 = {
        size = 30
        thin_provisioned = false
        disk_mode = "persistent"
      }
    }
    folder        = "webservers"
    network       = "VM Network"
    ipv4_address  = "192.168.1.100"
    ipv4_netmask  = 24
    ipv4_gateway  = "192.168.1.1"
    dns_servers   = ["8.8.8.8", "1.1.1.1"]
  }
}
```

### 参数说明

- `template_name`：虚拟机模板名称
- `os_type`：操作系统类型 ("linux" 或 "windows")
- `cpu/memory/disk_size`：硬件配置
- `additional_disks`：额外磁盘配置（可选）
- `folder/network`：vSphere 资源位置
- `ipv4_*`：网络配置

## 密码配置说明

### Linux虚拟机密码配置
Linux虚拟机使用`linux_admin_password`变量设置用户账户密码，该变量应为加密后的SHA-512格式密码。

### Windows虚拟机密码配置
Windows虚拟机使用`windows_admin_password`变量设置Administrator账户密码，该变量为明文密码格式。

## Linux虚拟机磁盘扩容
- 当虚拟机磁盘大小大于模板磁盘大小时，系统会在首次启动时自动扩展根分区和文件系统
- 使用`growpart`和`resize2fs`或`xfs_growfs`工具进行分区和文件系统扩展
- 自动检测根分区所在的设备和文件系统类型（ext4/xfs）

## 管理项目

### 查看工作空间
```bash
terraform workspace list
```

### 切换项目
```bash
terraform workspace select project-name
```

### 销毁项目资源
```bash
terraform destroy -var-file="project-name.tfvars"
```

## 磁盘配置

### 添加多个硬盘的方法

#### 配置说明
- 通过`additional_disks`映射（map）配置多个额外硬盘
- 每个硬盘可以单独设置大小、存储类型和磁盘模式
- 支持精简配置（thin_provisioned = true）和厚置备（thin_provisioned = false）
- 磁盘模式包括：persistent（从属）、independent_persistent（独立持久）、independent_nonpersistent（独立非持久）
- 硬盘名称必须以"disk"开头，后跟数字（如disk1, disk2），以确保unit_number正确分配

#### Linux虚拟机配置示例
```hcl
virtual_machines = {
  "example-vm" = {
    template_name = "linux-rocky-9.5"
    os_type       = "linux"
    cpu           = 2
    memory        = 2048
    disk_size     = 40        # 主磁盘大小
    additional_disks = {      # 额外磁盘配置，支持多个磁盘
      disk1 = {
        size = 20            # 第二块磁盘大小，单位GB
        thin_provisioned = true
        disk_mode = "independent_persistent"  # 独立持久模式
      },
      disk2 = {
        size = 30            # 第三块磁盘大小，单位GB
        thin_provisioned = false
        disk_mode = "persistent"  # 从属模式
      },
      disk3 = {
        size = 50            # 第四块磁盘大小，单位GB
        thin_provisioned = true
        disk_mode = "independent_nonpersistent"  # 独立非持久模式
      }
    }
    folder        = "web"
    network       = "v2356-172.17.80.1-24"
    ipv4_address  = "172.17.80.100"
    ipv4_netmask  = "24"
    ipv4_gateway  = "172.17.80.1"
    dns_servers   = ["8.8.8.8", "114.114.114.114"]
  }
}
```

#### Windows虚拟机配置示例
```hcl
virtual_machines = {
  "example-win-vm" = {
    template_name = "windows-server-2022-standard-dexp"
    os_type       = "windows"
    cpu           = 4
    memory        = 4096
    disk_size     = 100       # 主磁盘大小
    additional_disks = {      # 额外磁盘配置，支持多个磁盘
      disk1 = {
        size = 50            # 第二块磁盘大小，单位GB
        thin_provisioned = true
        disk_mode = "independent_persistent"  # 独立持久模式
      },
      disk2 = {
        size = 100           # 第三块磁盘大小，单位GB
        thin_provisioned = false
        disk_mode = "persistent"  # 从属模式
      }
    }
    folder        = "web"
    network       = "v2356-172.17.80.1-24"
    ipv4_address  = "172.17.80.105"
    ipv4_netmask  = "24"
    ipv4_gateway  = "172.17.80.1"
    dns_servers   = ["8.8.8.8", "114.114.114.114"]
  }
}
```

#### 关键参数说明
- `unit_number`: SCSI 总线上的设备编号（0-15）。主磁盘为0，额外磁盘从1开始递增
- `label`: 磁盘在 vSphere 中的显示名称
- `size`: 磁盘大小，单位 GB
- `thin_provisioned`: 是否启用精简置备，默认为 true
- `disk_mode`: 磁盘模式，可选值：
  - `persistent`：从属模式，磁盘会参与虚拟机快照，当还原快照时磁盘状态也会被还原
  - `independent_persistent`：独立持久模式，磁盘不参与虚拟机快照，快照操作不会影响该磁盘
  - `independent_nonpersistent`：独立非持久模式，磁盘不参与快照且每次关机后都会自动还原到之前状态

#### 在操作系统中使用额外硬盘
##### Linux系统
- 磁盘通常显示为 `/dev/sdb`, `/dev/sdc`, `/dev/sdd` 等
- 需要手动分区、格式化并挂载到所需目录
- 可以使用 `lsblk` 或 `fdisk -l` 查看磁盘

##### Windows系统
- 磁盘通常显示为 "磁盘1", "磁盘2", "磁盘3" 等
- 需要在"磁盘管理"中初始化、分区和格式化
- 分配驱动器号后即可正常使用

## 注意事项

- 添加或修改磁盘配置后，需要重建虚拟机资源才能生效
- 重建虚拟机会导致 IP 地址可能发生变化
- 额外磁盘需要在操作系统内部进行初始化和格式化

## 架构

```
Terraform Core → 调用模块 → 渲染模板 → vSphere Provider → 创建虚拟机
              ↘ 加载项目变量 → 动态设置参数
```

## 目录结构

```
.
├── environments/           # Terraform 主配置
├── modules/
│   ├── linux-vm/         # Linux 虚拟机模块
│   │   ├── templates/    # cloud-init 模板
│   │   ├── outputs.tf    # 输出定义
│   │   ├── main.tf       # 虚拟机资源定义
│   │   └── variables.tf  # 变量定义
│   └── windows-vm/       # Windows 虚拟机模块
│       ├── outputs.tf    # 输出定义
│       ├── main.tf       # 虚拟机资源定义
│       └── variables.tf  # 变量定义
├── create-project.sh   # 工作空间和项目配置创建脚本
└── README.md
```