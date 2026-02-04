#!/bin/bash

# 确保以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "请使用 sudo 或以 root 用户运行此脚本。"
  exit 1
fi

SWAP_PATH="/swapfile"

# 1. 获取物理内存总量 (单位: M)
# 使用 free -m 并提取 Total 栏
MEM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
# 获取当前交换空间总量 (单位: M)
SWAP_TOTAL=$(free -m | awk '/^Swap:/{print $2}')

echo "检测到物理内存: ${MEM_TOTAL}MB"
echo "当前交换空间: ${SWAP_TOTAL}MB"

# 2. 智能判断逻辑
# 如果交换空间大小等于内存大小（允许 10MB 以内的误差，防止单位换算差异）
DIFF=$(( MEM_TOTAL - SWAP_TOTAL ))
ABS_DIFF=${DIFF#-} # 取绝对值

if [ "$SWAP_TOTAL" -gt 0 ] && [ "$ABS_DIFF" -le 10 ]; then
    echo "当前交换文件大小已等于内存大小，无需操作。"
    exit 0
fi

echo "正在调整交换文件至 ${MEM_TOTAL}MB..."

# 3. 执行调整步骤
# 禁用现有交换空间
swapoff -a 2>/dev/null

# 创建/调整文件大小
# 这里使用 fallocate，因为它速度极快
fallocate -l "${MEM_TOTAL}M" $SWAP_PATH || dd if=/dev/zero of=$SWAP_PATH bs=1M count=$MEM_TOTAL

# 设置权限
chmod 600 $SWAP_PATH

# 格式化为交换文件
mkswap $SWAP_PATH

# 启用交换文件
swapon $SWAP_PATH

# 4. 验证结果
NEW_SWAP=$(free -h | awk '/^Swap:/{print $2}')
echo "设置完成！当前交换空间大小为: $NEW_SWAP"

# 5. 确保开机自启 (检查 /etc/fstab)
if ! grep -q "$SWAP_PATH" /etc/fstab; then
    echo "$SWAP_PATH none swap sw 0 0" >> /etc/fstab
    echo "已将交换文件添加到 /etc/fstab 以实现开机自启。"
fi