#!/bin/bash

# 创建新工作区的脚本
# 用法: ./create-project.sh <workspace-name>

set -e

if [ $# -eq 0 ]; then
    echo "用法: $0 <workspace-name>"
    echo "示例: $0 project-a"
    exit 1
fi

WORKSPACE_NAME=$1
PROJECT_DIR="/home/packer/terraform/terraform-vsphere/environments"

echo "正在创建新的工作区: $WORKSPACE_NAME"

# 切换到environments目录
cd $PROJECT_DIR

# 初始化terraform（如果还没有初始化）
if [ ! -d ".terraform" ]; then
    echo "正在初始化Terraform..."
    terraform init
fi

# 尝试选择现有工作区，如果不存在则创建
if terraform workspace list | grep -q "^$WORKSPACE_NAME$"; then
    echo "工作区 $WORKSPACE_NAME 已存在，切换到该工作区..."
    terraform workspace select $WORKSPACE_NAME
else
    echo "创建新工作区: $WORKSPACE_NAME"
    terraform workspace new $WORKSPACE_NAME
fi

# 检查是否存在对应的工作区配置文件
CONFIG_FILE="$WORKSPACE_NAME.tfvars"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "创建配置文件: $CONFIG_FILE"
    
    # 使用示例配置创建新配置文件
    cat << EOF > "$CONFIG_FILE"
# $WORKSPACE_NAME 配置文件
# 根据需要修改虚拟机配置

virtual_machines = {
  "${WORKSPACE_NAME}-web-01" = {
    template_name = "template-ubuntu-web"
    os_type       = "linux"      # 仅允许 "linux" 或 "windows"
    cpu           = 2
    memory        = 2048
    disk_size     = 40           # 主磁盘大小
    additional_disks = {          # 额外磁盘配置，支持多个磁盘
      disk1 = {
        size = 20               # 第二块磁盘大小，单位GB
        thin_provisioned = true
        disk_mode = "independent_persistent"
      },
      disk2 = {
        size = 30               # 第三块磁盘大小，单位GB
        thin_provisioned = false
        disk_mode = "independent_persistent"
      }
    }
    folder        = "webservers"
    network       = "VM Network"
    ipv4_address  = ""
    ipv4_netmask  = 24
    ipv4_gateway  = ""
    dns_servers   = ["8.8.8.8", "1.1.1.1"]
  },
  "${WORKSPACE_NAME}-db-01" = {
    template_name = "template-ubuntu-db"
    os_type       = "linux"      # 仅允许 "linux" 或 "windows"
    cpu           = 4
    memory        = 4096
    disk_size     = 100          # 主磁盘大小
    additional_disks = {          # 额外磁盘配置，支持多个磁盘
      disk1 = {
        size = 50               # 第二块磁盘大小，单位GB
        thin_provisioned = true
        disk_mode = "independent_persistent"
      },
      disk2 = {
        size = 100              # 第三块磁盘大小，单位GB
        thin_provisioned = true
        disk_mode = "independent_persistent"
      },
      disk3 = {
        size = 200              # 第四块磁盘大小，单位GB
        thin_provisioned = false
        disk_mode = "independent_persistent"
      }
    }
    folder        = "databases"
    network       = "VM Network"
    ipv4_address  = ""
    ipv4_netmask  = 24
    ipv4_gateway  = ""
    dns_servers   = ["8.8.8.8", "114.114.114.114"]
  }
}
EOF
    
    echo "已创建配置文件: $CONFIG_FILE"
    echo "请根据实际需求编辑该文件"
else
    echo "配置文件 $CONFIG_FILE 已存在"
fi

echo ""
echo "工作区 $WORKSPACE_NAME 已准备就绪！"
echo "当前工作区: $(terraform workspace show)"
echo ""
echo "要应用配置，请运行:"
echo "  cd $PROJECT_DIR"
echo "  terraform plan -var-file=\"$CONFIG_FILE\""
echo "  terraform apply -var-file=\"$CONFIG_FILE\""