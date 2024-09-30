
# 日志文件路径
LOG_FILE="/var/log/miner/custom/custom_cpu.log"
# 获取当前主机名作为矿工名称
WORKER_NAME=$(hostname)
# 矿机启动命令
MINER_CMD="/hive/miners/custom/OreMinePoolWorker_hiveos/ore-mine-pool-linux worker --route-server-url http://route.oreminepool.top:8080/ --server-url public --worker-wallet-address XzuEvwWvGLNWjfbkJzCoaKTZTzVj43eym1JrTQDwkH3"
# 空闲阈值
IDLE_THRESHOLD=5
# 矿机进程ID初始化
MINER_PID=0

while true; do
    # 统计日志文件中“rqiner_manager] Idle period | Waiting for work”出现的次数
    CURRENT_IDLE_COUNT=$(tail -n 10 "$LOG_FILE" | grep -c "rqiner_manager] Idle period | Waiting for work")
    echo "当前空闲计数: $CURRENT_IDLE_COUNT"

    # 如果空闲计数大于等于阈值且矿机未运行，则启动矿机
    if [ "$CURRENT_IDLE_COUNT" -ge "$IDLE_THRESHOLD" ] && [ "$MINER_PID" -eq 0 ]; then
        echo "启动矿机..."
        nohup $MINER_CMD &
        MINER_PID=$!
        echo "矿机PID: $MINER_PID"
    fi

    # 如果空闲计数小于阈值且矿机正在运行，则停止矿机
    if [ "$CURRENT_IDLE_COUNT" -lt "$IDLE_THRESHOLD" ] && [ "$MINER_PID" -ne 0 ]; then
        echo "停止矿机..."
        pkill -9 -f "ore-mine-pool-linux worker"
        MINER_PID=0
    fi

    # 检查日志文件的最后修改时间
    LAST_MODIFIED=$(stat -c %Y "$LOG_FILE")
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_MODIFIED))

    # 如果日志文件在3分钟内没有更新，则停止并重新启动矿机
    if [ "$TIME_DIFF" -ge 180 ]; then
        echo "日志文件3分钟内未更新。执行矿机停止..."
        miner stop
        sleep 25
        echo "25秒后重新启动矿机..."
        miner start
    fi

    # 每次循环后等待30秒
    sleep 30
done
