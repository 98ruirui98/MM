#!/bin/bash

LOG_FILE="/var/log/miner/custom/custom_cpu.log"
WORKER_NAME=$(hostname)
MINER_CMD="/hive/miners/xmrig-new/xmrig/6.22.0/xmrig -o4 -u 4DSQMNzzq46N1z2pZWAVdeA6JvUL9TCB2bnBiA3ZzoqEdYJnMydt5akCa3vtmapeDsbVKGPFdNkzqTcJS8M8oyK7WGkEY6XGuNRS6tPxJN.$WORKER_NAME/josfang0@gmail.com -a rx/0 -k --donate-level 1 --tls"
IDLE_THRESHOLD=5
MINER_PID=0

# 检查并创建日志文件
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    if [ $? -ne 0 ]; then
        echo "无法创建日志文件 $LOG_FILE"
        exit 1
    fi
fi

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

while true; do
    # 统计日志文件中“miner_manager] Idle period | Waiting for work”出现的次数
    CURRENT_IDLE_COUNT=$(tail -n 10 "$LOG_FILE" | grep -c "miner_manager] Idle period | Waiting for work")
    log "当前空闲计数: $CURRENT_IDLE_COUNT"

    # 如果空闲计数大于等于阈值且矿工未运行，则启动矿工
    if [ "$CURRENT_IDLE_COUNT" -ge "$IDLE_THRESHOLD" ] && [ "$MINER_PID" -eq 0 ]; then
        log "启动矿工..."
        nohup $MINER_CMD >> "$LOG_FILE" 2>&1 &
        MINER_PID=$!
        log "矿工 PID: $MINER_PID"
    fi

    # 如果空闲计数小于阈值且矿工正在运行，则停止矿工
    if [ "$CURRENT_IDLE_COUNT" -lt "$IDLE_THRESHOLD" ] && [ "$MINER_PID" -ne 0 ]; then
        log "停止矿工..."
        kill "$MINER_PID"
        if [ $? -eq 0 ]; then
            log "矿工成功停止。"
        else
            log "停止矿工失败。"
        fi
        MINER_PID=0
    fi

    # 检查日志文件的最后修改时间
    LAST_MODIFIED=$(stat -c %Y "$LOG_FILE")
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_MODIFIED))

    # 如果日志文件在2分钟内没有更新，则停止并重新启动矿工
    if [ "$TIME_DIFF" -ge 120 ]; then
        log "日志文件2分钟未更改。执行矿工停止..."
        pkill -9 -f "xmrig"
        MINER_PID=0
        sleep 20
        log "20秒后执行矿工启动..."
        nohup $MINER_CMD >> "$LOG_FILE" 2>&1 &
        MINER_PID=$!
        log "矿工 PID: $MINER_PID"
    fi

    # 每次循环后等待30秒
    sleep 30
done
