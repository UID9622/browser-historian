#!/bin/bash
# ============================================================
# 龍魂 · 浏览器史官 v2.1 — 采集器一键安装脚本
# DNA: #龍芯⚡️丙午·乙未·乙未·申时·☰乾-COLLECTOR-INSTALL-v2.1
# 创建者: 诸葛鑫 (UID9622)
# 协议: CC BY-NC-SA 4.0
# ============================================================
# 用法: sudo bash install.sh
# 以 root 运行采集器才能启用防线一（pfctl 强制阻断）
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LONGHUN_HOME="${LONGHUN_HOME:-$HOME/longhun-system}"
COLLECTOR_SCRIPT="bin/lh_base_trace_collector.py"
PLIST_NAME="com.longhun.trace-collector"
DAEMON_PLIST="/Library/LaunchDaemons/${PLIST_NAME}.plist"

echo "============================================================"
echo " 龍魂 · 浏览器史官 v2.1 — 采集器安装"
echo "============================================================"
echo ""

# 检查 root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}[错误] 必须以 root 运行。请用: sudo bash install.sh${NC}"
    exit 1
fi

# 1. 检查采集器脚本
if [ ! -f "${COLLECTOR_SCRIPT}" ]; then
    COLLECTOR_SCRIPT="${LONGHUN_HOME}/${COLLECTOR_SCRIPT}"
fi
if [ ! -f "${COLLECTOR_SCRIPT}" ]; then
    COLLECTOR_SCRIPT="$(dirname "$0")/lh_base_trace_collector.py"
fi
if [ ! -f "${COLLECTOR_SCRIPT}" ]; then
    echo -e "${RED}[错误] 找不到 lh_base_trace_collector.py${NC}"
    exit 1
fi
echo -e "${GREEN}[1/5] 采集器脚本: ${COLLECTOR_SCRIPT}${NC}"

# 2. 停止旧服务
echo -n "[2/5] 停止旧采集器... "
launchctl unload "${DAEMON_PLIST}" 2>/dev/null || true
# 也检查用户级的
su - "$SUDO_USER" -c "launchctl unload ~/Library/LaunchAgents/${PLIST_NAME}.plist" 2>/dev/null || true
sleep 1
echo "完成"

# 3. 安装 LaunchDaemon plist
echo -n "[3/5] 安装 root 级守护配置... "
PLIST_SRC="$(dirname "$0")/com.longhun.trace-collector-daemon.plist"
if [ ! -f "${PLIST_SRC}" ]; then
    PLIST_SRC="${LONGHUN_HOME}/deploy/com.longhun.trace-collector-daemon.plist"
fi

if [ -f "${PLIST_SRC}" ]; then
    cp "${PLIST_SRC}" "${DAEMON_PLIST}"
else
    # 动态生成 plist
    PYTHON_PATH=$(which python3 2>/dev/null || echo "/usr/bin/python3")
    WORK_DIR=$(dirname "$(dirname "$(realpath "${COLLECTOR_SCRIPT}")")")
    
    cat > "${DAEMON_PLIST}" << PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${PYTHON_PATH}</string>
        <string>${COLLECTOR_SCRIPT}</string>
        <string>start</string>
    </array>
    <key>WorkingDirectory</key>
    <string>${WORK_DIR}</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>5</integer>
    <key>StandardOutPath</key>
    <string>/tmp/longhun-collector.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/longhun-collector.err</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin</string>
        <key>HOME</key>
        <string>${HOME}</string>
    </dict>
</dict>
</plist>
PLISTEOF
fi
echo "完成"

# 4. 加载服务
echo -n "[4/5] 启动采集器守护进程... "
launchctl load "${DAEMON_PLIST}"
sleep 2
echo "完成"

# 5. 验证
echo -n "[5/5] 验证采集器状态... "
sleep 1
if curl -sf http://127.0.0.1:18775/defense/status > /dev/null 2>&1; then
    echo -e "${GREEN}运行中${NC}"
    echo ""
    echo "============================================================"
    echo " 防线状态:"
    curl -s http://127.0.0.1:18775/defense/status | python3 -m json.tool
    echo "============================================================"
else
    echo -e "${YELLOW}采集器可能尚未就绪，请检查日志:${NC}"
    echo "  tail -f /tmp/longhun-collector.log"
fi

echo ""
echo -e "${GREEN}[安装完成] 采集器已以 root 身份运行，四道防线已激活。${NC}"
echo ""
echo "管理命令:"
echo "  停止: sudo launchctl unload ${DAEMON_PLIST}"
echo "  重启: sudo launchctl unload ${DAEMON_PLIST} && sudo launchctl load ${DAEMON_PLIST}"
echo "  日志: tail -f /tmp/longhun-collector.log"
