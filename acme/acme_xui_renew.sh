#!/bin/bash
LOG_FILE="/root/.acme.sh/acme_xui_renew.log"
ACME_SH="/root/.acme.sh/acme.sh"

# 解析命令行选项
FORCE=""
while getopts "f" opt; do
    case $opt in
        f)
            FORCE="--force"
            ;;
        \?)
            echo "Usage: $0 [-f]" | tee -a "$LOG_FILE"
            exit 1
            ;;
    esac
done

# 确保日志文件目录存在
mkdir -p "$(dirname "$LOG_FILE")"

# 临时文件存储 acme.sh 输出
TEMP_LOG=$(mktemp)

# 执行 acme.sh 续签，捕获输出和返回码
echo "[$(date)] Starting certificate renewal check${FORCE:+ (forced)}" | tee -a "$LOG_FILE"
$ACME_SH --cron --home /root/.acme.sh $FORCE 2>&1 | tee -a "$TEMP_LOG" | tee -a "$LOG_FILE"
ACME_EXIT_CODE=${PIPESTATUS[0]}

# 检查续签是否成功
if [ $ACME_EXIT_CODE -eq 0 ]; then
    # 检查 acme.sh 输出是否包含续签成功的标志
    if grep -q -e "Cert success" -e "Renew success" -e "Your cert is updated" "$TEMP_LOG"; then
        echo "[$(date)] Certificate renewed successfully, restarting x-ui" | tee -a "$LOG_FILE"
        systemctl restart x-ui 2>&1 | tee -a "$LOG_FILE"
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            echo "[$(date)] x-ui restarted successfully" | tee -a "$LOG_FILE"
        else
            echo "[$(date)] Error: Failed to restart x-ui" | tee -a "$LOG_FILE"
        fi
    else
        echo "[$(date)] No renewal performed" | tee -a "$LOG_FILE"
    fi
else
    echo "[$(date)] Error: acme.sh renewal failed with exit code $ACME_EXIT_CODE" | tee -a "$LOG_FILE"
fi

# 清理临时文件
rm -f "$TEMP_LOG"

echo "[$(date)] Task completed" | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"
