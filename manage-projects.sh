#!/bin/bash

# 项目管理脚本
# 用法：./manage-projects.sh [command] [project-name]
# 命令:
#   list                    - 列出所有项目
#   plan <project-name>     - 对指定项目执行 terraform plan
#   apply <project-name>    - 对指定项目执行 terraform apply
#   destroy <project-name>  - 销毁指定项目资源
#   show <project-name>     - 显示指定项目的详细信息

set -e

PROJECT_DIR="/home/packer/terraform/terraform-vsphere/environments"

# 显示帮助信息
show_help() {
    echo "用法：$0 [command] [project-name]"
    echo ""
    echo "命令:"
    echo "  list                    - 列出所有项目"
    echo "  plan <project-name>     - 对指定项目执行 terraform plan"
    echo "  apply <project-name>    - 对指定项目执行 terraform apply"
    echo "  destroy <project-name>  - 销毁指定项目资源"
    echo "  show <project-name>     - 显示指定项目的详细信息"
    echo ""
    echo "示例:"
    echo "  $0 list"
    echo "  $0 plan project-a"
    echo "  $0 apply project-a"
    echo "  $0 show project-a"
}

# 列出所有项目
list_projects() {
    echo "=== 所有项目列表 ==="
    echo ""
    
    # 获取所有工作区
    WORKSPACES=$(terraform workspace list | sed 's/^\*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    if [ -z "$WORKSPACES" ]; then
        echo "未找到任何项目"
        return 1
    fi
    
    echo "项目名称                          状态            配置文件"
    echo "-------------------------------------------------------------------"
    
    for ws in $WORKSPACES; do
        # 跳过 default 工作区
        if [ "$ws" = "default" ]; then
            continue
        fi
        
        # 检查是否为当前工作区
        CURRENT=$(terraform workspace show)
        if [ "$ws" = "$CURRENT" ]; then
            STATUS="● 当前项目"
        else
            STATUS="○"
        fi
        
        # 检查配置文件是否存在
        CONFIG_FILE="${ws}.tfvars"
        if [ -f "$CONFIG_FILE" ]; then
            CONFIG_STATUS="✓ $CONFIG_FILE"
        else
            CONFIG_STATUS="✗ 配置文件缺失"
        fi
        
        printf "%-32s  %-16s  %s\n" "$ws" "$STATUS" "$CONFIG_STATUS"
    done
    
    echo ""
    echo "总计：$(echo "$WORKSPACES" | grep -v "^default$" | wc -l) 个项目"
}

# 显示项目详细信息
show_project() {
    local PROJECT_NAME=$1
    
    if [ -z "$PROJECT_NAME" ]; then
        echo "错误：请指定项目名称"
        echo "用法：$0 show <project-name>"
        exit 1
    fi
    
    echo "=== 项目详情：$PROJECT_NAME ==="
    echo ""
    
    # 切换到项目工作区
    if ! terraform workspace select "$PROJECT_NAME" > /dev/null 2>&1; then
        echo "错误：项目 '$PROJECT_NAME' 不存在"
        exit 1
    fi
    
    echo "项目名称：$PROJECT_NAME"
    echo "当前状态：$(terraform workspace show)"
    echo ""
    
    # 检查配置文件
    CONFIG_FILE="${PROJECT_NAME}.tfvars"
    if [ -f "$CONFIG_FILE" ]; then
        echo "配置文件：$CONFIG_FILE ✓"
        echo ""
        echo "配置内容预览:"
        echo "----------------------------------------"
        head -20 "$CONFIG_FILE"
        if [ $(wc -l < "$CONFIG_FILE") -gt 20 ]; then
            echo "... (更多行未显示)"
        fi
        echo "----------------------------------------"
    else
        echo "配置文件：$CONFIG_FILE ✗ (不存在)"
    fi
    
    echo ""
    echo "Terraform 状态:"
    if [ -d ".terraform" ]; then
        echo "  - Terraform 已初始化"
        if [ -f "terraform.tfstate" ]; then
            echo "  - 状态文件存在"
        else
            echo "  - 状态文件不存在"
        fi
    else
        echo "  - Terraform 未初始化"
    fi
    
    echo ""
    echo "可用操作:"
    echo "  $0 plan $PROJECT_NAME   - 执行计划"
    echo "  $0 apply $PROJECT_NAME  - 应用配置"
    echo "  $0 destroy $PROJECT_NAME - 销毁资源"
}

# 验证工作区与项目是否匹配
verify_workspace_match() {
    local EXPECTED_PROJECT=$1
    
    if [ -z "$EXPECTED_PROJECT" ]; then
        echo "错误：未指定项目名称"
        return 1
    fi
    
    local CURRENT_WORKSPACE=$(terraform workspace show)
    
    if [ "$CURRENT_WORKSPACE" != "$EXPECTED_PROJECT" ]; then
        echo "⚠️  警告：当前工作区与目标项目不匹配"
        echo ""
        echo "  当前工作区：$CURRENT_WORKSPACE"
        echo "  目标项目：  $EXPECTED_PROJECT"
        echo ""
        read -p "是否切换到正确的工作区并继续？(yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "操作已取消"
            exit 0
        fi
        
        # 自动切换到正确的工作区
        echo "正在切换到工作区：$EXPECTED_PROJECT"
        if ! terraform workspace select "$EXPECTED_PROJECT" > /dev/null 2>&1; then
            echo "错误：无法切换到工作区 '$EXPECTED_PROJECT'"
            exit 1
        fi
        echo "✓ 已成功切换到工作区：$EXPECTED_PROJECT"
        echo ""
    else
        echo "✓ 工作区验证通过：当前工作区 ($CURRENT_WORKSPACE) 与项目 ($EXPECTED_PROJECT) 匹配"
        echo ""
    fi
}

# 执行 terraform plan
run_plan() {
    local PROJECT_NAME=$1
    
    if [ -z "$PROJECT_NAME" ]; then
        echo "错误：请指定项目名称"
        echo "用法：$0 plan <project-name>"
        exit 1
    fi
    
    # 切换到项目目录
    cd "$PROJECT_DIR"
    
    # 先切换到目标工作区（如果不存在会报错）
    if ! terraform workspace select "$PROJECT_NAME" > /dev/null 2>&1; then
        echo "错误：项目 '$PROJECT_NAME' 不存在"
        exit 1
    fi
    
    echo "=== 执行项目计划：$PROJECT_NAME ==="
    echo "当前工作区：$(terraform workspace show)"
    echo ""
    
    # 验证工作区匹配
    verify_workspace_match "$PROJECT_NAME"
    
    CONFIG_FILE="${PROJECT_NAME}.tfvars"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "错误：配置文件 '$CONFIG_FILE' 不存在"
        exit 1
    fi
    
    echo "使用配置文件：$CONFIG_FILE"
    echo ""
    
    terraform plan -var-file="$CONFIG_FILE"
}

# 执行 terraform apply
run_apply() {
    local PROJECT_NAME=$1
    
    if [ -z "$PROJECT_NAME" ]; then
        echo "错误：请指定项目名称"
        echo "用法：$0 apply <project-name>"
        exit 1
    fi
    
    # 切换到项目目录
    cd "$PROJECT_DIR"
    
    # 先切换到目标工作区（如果不存在会报错）
    if ! terraform workspace select "$PROJECT_NAME" > /dev/null 2>&1; then
        echo "错误：项目 '$PROJECT_NAME' 不存在"
        exit 1
    fi
    
    echo "=== 应用项目配置：$PROJECT_NAME ==="
    echo "当前工作区：$(terraform workspace show)"
    echo ""
    
    # 验证工作区匹配
    verify_workspace_match "$PROJECT_NAME"
    
    CONFIG_FILE="${PROJECT_NAME}.tfvars"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "错误：配置文件 '$CONFIG_FILE' 不存在"
        exit 1
    fi
    
    echo "使用配置文件：$CONFIG_FILE"
    echo ""
    
    read -p "确认要对项目 '$PROJECT_NAME' 执行 apply 操作吗？(yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "操作已取消"
        exit 0
    fi
    
    terraform apply -var-file="$CONFIG_FILE"
}


# 执行 terraform destroy
run_destroy() {
    local PROJECT_NAME=$1
    
    if [ -z "$PROJECT_NAME" ]; then
        echo "错误：请指定项目名称"
        echo "用法：$0 destroy <project-name>"
        exit 1
    fi
    
    # 切换到项目目录
    cd "$PROJECT_DIR"
    
    # 先切换到目标工作区（如果不存在会报错）
    if ! terraform workspace select "$PROJECT_NAME" > /dev/null 2>&1; then
        echo "错误：项目 '$PROJECT_NAME' 不存在"
        exit 1
    fi
    
    echo "=== 警告：销毁项目资源：$PROJECT_NAME ==="
    echo "当前工作区：$(terraform workspace show)"
    echo ""
    
    # 验证工作区匹配（额外的安全检查）
    verify_workspace_match "$PROJECT_NAME"
    
    CONFIG_FILE="${PROJECT_NAME}.tfvars"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "错误：配置文件 '$CONFIG_FILE' 不存在"
        exit 1
    fi
    
    echo "此操作将执行以下清理工作："
    echo "  1. 销毁项目 '$PROJECT_NAME' 的所有 Terraform 资源"
    echo "  2. 删除工作区 '$PROJECT_NAME'"
    echo "  3. 删除配置文件 '$CONFIG_FILE'"
    echo ""
    echo "这是一个不可逆的操作！"
    echo ""
    
    read -p "输入项目名称 '$PROJECT_NAME' 以确认销毁：" confirm
    if [ "$confirm" != "$PROJECT_NAME" ]; then
        echo "确认失败，操作已取消"
        exit 0
    fi
    
    echo ""
    echo "步骤 1/3: 开始销毁 Terraform 资源..."
    terraform destroy -var-file="$CONFIG_FILE" -auto-approve
    
    echo ""
    echo "步骤 2/3: 删除工作区 '$PROJECT_NAME'..."
    
    # 切换回 default 工作区后再删除
    CURRENT_WORKSPACE=$(terraform workspace show)
    if [ "$CURRENT_WORKSPACE" = "$PROJECT_NAME" ]; then
        echo "正在切换到 default 工作区..."
        terraform workspace select default > /dev/null 2>&1 || {
            echo "警告：无法切换到 default 工作区，尝试继续删除..."
        }
    fi
    
    # 删除工作区
    if terraform workspace delete "$PROJECT_NAME" > /dev/null 2>&1; then
        echo "✓ 工作区 '$PROJECT_NAME' 已删除"
    else
        echo "⚠️  警告：无法删除工作区 '$PROJECT_NAME'（可能仍包含资源）"
    fi
    
    echo ""
    echo "步骤 3/3: 删除配置文件 '$CONFIG_FILE'..."
    if rm -f "$CONFIG_FILE"; then
        echo "✓ 配置文件 '$CONFIG_FILE' 已删除"
    else
        echo "✗ 无法删除配置文件 '$CONFIG_FILE'"
        exit 1
    fi
    
    echo ""
    echo "=== 项目清理完成 ==="
    echo "项目 '$PROJECT_NAME' 已被完全移除："
    echo "  ✓ Terraform 资源已销毁"
    echo "  ✓ 工作区已删除"
    echo "  ✓ 配置文件已删除"
    echo ""
    echo "提示：如果需要删除状态文件，请手动执行:"
    echo "  rm -rf .terraform/"
}

# 主程序
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

COMMAND=$1

case $COMMAND in
    "list"|"ls"|"l")
        cd "$PROJECT_DIR"
        list_projects
        ;;
    "plan"|"p")
        run_plan "$2"
        ;;
    "apply"|"a")
        run_apply "$2"
        ;;
    "destroy"|"d")
        run_destroy "$2"
        ;;
    "show"|"s"|"info"|"i")
        cd "$PROJECT_DIR"
        show_project "$2"
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo "错误：未知命令 '$COMMAND'"
        echo ""
        show_help
        exit 1
        ;;
esac