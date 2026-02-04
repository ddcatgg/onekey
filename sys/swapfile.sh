#!/bin/bash

# 确保以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "请使用 sudo 或以 root 用户运行此脚本。"
  exit 1
fi

SWAP_PATH="/swapfile"

# 1. 获取物理内存总量 (MiB)
# 使用 free -m 并提取 Total 栏
MEM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
# 确定目标大小：如果内存 < 1024MB，则目标定为 1024MB；否则目标等于内存大小
if [ "$MEM_TOTAL" -lt 1024 ]; then
    TARGET_SWAP=1024
else
    TARGET_SWAP=$MEM_TOTAL
fi

# 2. 获取当前交换空间总量 (MiB)
SWAP_CURRENT=$(free -m | awk '/^Swap:/{print $2}')

echo "检测到物理内存: ${MEM_TOTAL}MB"
echo "当前交换空间: ${SWAP_CURRENT}MB"
echo "目标交换空间: ${TARGET_SWAP}MB"

# 3. 判断是否需要操作 (允许 32MB 的微小误差，防止单位换算差异)
DIFF=$(( TARGET_SWAP - SWAP_CURRENT ))
ABS_DIFF=${DIFF#-} # 取绝对值

if [ "$ABS_DIFF" -le 32 ]; then
    echo "当前配置已符合预期，无需修改。"
    exit 0
fi

# 4. 执行调整
echo "正在调整交换文件至 ${TARGET_SWAP}MB..."

# 禁用现有交换空间
swapoff -a 2>/dev/null

# 创建/调整文件大小
# 使用 fallocate 快速分配空间，因为它速度极快
fallocate -l "${TARGET_SWAP}M" $SWAP_PATH || dd if=/dev/zero of=$SWAP_PATH bs=1M count=$TARGET_SWAP

# 设置权限
chmod 600 $SWAP_PATH

# 格式化为交换文件
mkswap $SWAP_PATH

# 启用交换文件
swapon $SWAP_PATH

# 5. 验证结果
NEW_SWAP=$(free -h | awk '/^Swap:/{print $2}')
echo "设置完成！当前交换空间大小为: $NEW_SWAP"

# 6. 确保开机自动加载交换文件 (检查 /etc/fstab)
if ! grep -q "$SWAP_PATH" /etc/fstab; then
    echo "$SWAP_PATH none swap sw 0 0" >> /etc/fstab
    echo "已将交换文件添加到 /etc/fstab 以实现开机自启。"
fi
