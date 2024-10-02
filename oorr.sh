LOG_FILE="/var/log/miner/custom/custom_cpu.log"
WORKER_NAME=$(hostname)
MINER_CMD="/hive/miners/custom/OreMinePoolWorker_hiveos/ore-mine-pool-linux worker --route-server-url http://47.254.182.83:8080/ --server-url direct --worker-wallet-address XzuEvwWvGLNWjfbkJzCoaKTZTzVj43eym1JrTQDwkH3"
IDLE_THRESHOLD=5
MINER_PID=0

while true; do
    CURRENT_IDLE_COUNT=$(tail -n 10 "$LOG_FILE" | grep -c "rqiner_manager] Idle period | Waiting for work")
    echo "当前空闲计数: $CURRENT_IDLE_COUNT"

    if [ "$CURRENT_IDLE_COUNT" -ge "$IDLE_THRESHOLD" ] && [ "$MINER_PID" -eq 0 ]; then
        echo "启动矿机..."
        nohup $MINER_CMD > /var/log/miner/custom/custom.log 2>&1 &
        MINER_PID=$!
        echo "矿机PID: $MINER_PID"
    fi

    if [ "$CURRENT_IDLE_COUNT" -lt "$IDLE_THRESHOLD" ] && [ "$MINER_PID" -ne 0 ]; then
        echo "停止矿机..."
        pkill -9 -f "ore-mine-pool-linux worker"
        MINER_PID=0
    fi

    LAST_MODIFIED=$(stat -c %Y "$LOG_FILE")
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_MODIFIED))

    if [ "$TIME_DIFF" -ge 180 ]; then
        echo "日志文件3分钟内未更新。执行矿机停止..."
        miner stop
        sleep 25
        echo "25秒后重新启动矿机..."
        miner start
    fi

    sleep 30
done
