#!/bin/bash

LOG_FILE="/var/log/miner/custom/custom_cpu.log"
WORKER_NAME=$(hostname)
MINER_CMD="/hive/miners/xmrig-new/xmrig/6.22.0/xmrig -o pool.supportxmr.com:5555 -u 4DSQMNzzq46N1z2pZWAVdeA6JvUL9TCB2bnBiA3ZzoqEdYJnMydt5akCa3vtmapeDsbVKGPFdNkzqTcJS8M8oyK7WGkEY6XGuNRS6tPxJN -p $WORKER_NAME -a rx/0 -k --donate-level 1"
IDLE_THRESHOLD=5
MINER_PID=0
LOCK_FILE="/tmp/miner_script.lock"

# 检查锁文件是否存在
if [ -e "$LOCK_FILE" ]; then
    echo "脚本已经在运行。"
    exit 1
fi

# 创建锁文件
touch "$LOCK_FILE"

# 确保脚本退出时删除锁文件
trap "rm -f $LOCK_FILE" EXIT

while true; do
    CURRENT_IDLE_COUNT=$(tail -n 10 "$LOG_FILE" | grep -c "rqiner_manager] Idle period | Waiting for work")
    echo "当前空闲计数: $CURRENT_IDLE_COUNT"

    if [ "$CURRENT_IDLE_COUNT" -ge "$IDLE_THRESHOLD" ] && [ "$MINER_PID" -eq 0 ]; then
        echo "启动矿工..."
        nohup $MINER_CMD >> "$LOG_FILE" 2>&1 &
        MINER_PID=$!
        echo "矿工PID: $MINER_PID"
    fi

    if [ "$CURRENT_IDLE_COUNT" -lt "$IDLE_THRESHOLD" ] && [ "$MINER_PID" -ne 0 ]; then
        echo "停止矿工..."
        kill "$MINER_PID"
        MINER_PID=0
    fi

    # 检查日志文件的修改时间
    LAST_MODIFIED=$(stat -c %Y "$LOG_FILE")
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_MODIFIED))

    if [ "$TIME_DIFF" -ge 180 ]; then
        echo "日志文件已3分钟未修改。执行矿工停止..."
        miner stop
        sleep 20
        echo "20秒后执行矿工启动..."
        miner start
    fi

    sleep 30
done

