#!/bin/bash
# ============================================================
# 龍魂 · 浏览器史官 v2.1 — 统一自检脚本
# DNA: #龍芯⚡️丙午·乙未·乙未·申时·☰乾-VALIDATE-v2.1
# 创建者: 诸葛鑫 (UID9622)
# 协议: CC BY-NC-SA 4.0
# ============================================================
# 用法: bash validate.sh
# 检查采集器、Chrome 扩展、复原引擎是否就绪
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
PASS=0
FAIL=0

check() {
    local desc="$1"
    local result="$2"
    if [ "$result" = "ok" ]; then
        echo -e "  ${GREEN}✅${NC} ${desc}"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}❌${NC} ${desc} — ${result}"
        FAIL=$((FAIL + 1))
    fi
}

echo "============================================================"
echo " 龍魂 · 浏览器史官 v2.1 — 自检"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"
echo ""

# ── 第一组：采集器 ──
echo "【采集器】"

# 1.1 采集器进程
if pgrep -f "lh_base_trace_collector" > /dev/null 2>&1; then
    PID=$(pgrep -f "lh_base_trace_collector" | head -1)
    RUN_USER=$(ps -o user= -p "$PID" 2>/dev/null || echo "unknown")
    if [ "$RUN_USER" = "root" ]; then
        check "采集器运行中 (root)" "ok"
    else
        check "采集器运行中 (用户: ${RUN_USER}，非root——防线一无阻断)" "warn"
    fi
else
    check "采集器运行中" "未运行"
fi

# 1.2 采集器 API 可达
if curl -sf http://127.0.0.1:18775/defense/status > /tmp/lh_validate_status.json 2>/dev/null; then
    check "采集器 API :18775 可达" "ok"
else
    check "采集器 API :18775 可达" "端口不可达"
    # 无法继续检查防线状态
    echo ""
    echo "============================================================"
    echo " 结果: ${PASS}/${PASS+FAIL} 通过"
    echo "============================================================"
    exit $FAIL
fi

# 1.3 四道防线状态
OVERALL=$(python3 -c "import json; d=json.load(open('/tmp/lh_validate_status.json')); print(d.get('overall_green', False))" 2>/dev/null)
if [ "$OVERALL" = "True" ]; then
    check "四道防线全绿 (overall_green=true)" "ok"
else
    check "四道防线全绿" "overall_green=false"
    # 详细检查每道防线
    for i in 1 2 3 4; do
        WALL=$(python3 -c "import json; d=json.load(open('/tmp/lh_validate_status.json')); w=d['walls']['wall_${i}_network_guard' if ${i}==1 else 'wall_${i}_malware_guard' if ${i}==2 else 'wall_${i}_device_vault' if ${i}==3 else 'wall_${i}_export_bind']; print(w.get('green',False))" 2>/dev/null)
        if [ "$WALL" = "True" ]; then
            check "  防线${i}" "ok"
        else
            check "  防线${i}" "未通过"
        fi
    done
fi

# 1.4 防火墙状态
FW_INIT=$(python3 -c "import json; d=json.load(open('/tmp/lh_validate_status.json')); print(d['walls']['wall_1_network_guard'].get('firewall_initialized',False))" 2>/dev/null)
BLOCKED=$(python3 -c "import json; d=json.load(open('/tmp/lh_validate_status.json')); print(d['walls']['wall_1_network_guard'].get('firewall_blocked_ips',0))" 2>/dev/null)
check "防火墙引擎初始化" "$([ "$FW_INIT" = "True" ] && echo ok || echo false)"
check "已阻断IP数: ${BLOCKED}" "ok"

# 1.5 威胁情报
INTEL_FRESH=$(python3 -c "import json; d=json.load(open('/tmp/lh_validate_status.json')); print(d['walls']['wall_2_malware_guard'].get('threat_intel_fresh',False))" 2>/dev/null)
INTEL_HASHES=$(python3 -c "import json; d=json.load(open('/tmp/lh_validate_status.json')); print(d['walls']['wall_2_malware_guard'].get('threat_intel_hash_count',0))" 2>/dev/null)
check "威胁情报新鲜" "$([ "$INTEL_FRESH" = "True" ] && echo ok || echo false)"
check "威胁签名数: ${INTEL_HASHES}" "ok"

echo ""

# ── 第二组：Chrome 扩展文件完整性 ──
echo "【Chrome 扩展】"
EXT_DIR="$(dirname "$0")/extension"
if [ ! -d "$EXT_DIR" ]; then
    EXT_DIR="web/chrome-extensions/browser-historian"
fi

check_file() {
    local f="$1"
    local desc="$2"
    if [ -f "$EXT_DIR/$f" ]; then
        check "$desc" "ok"
    else
        check "$desc" "缺失"
    fi
}

check_file "manifest.json" "manifest.json (v2.1.0)"
check_file "background.js" "background.js"
check_file "popup.html" "popup.html"
check_file "popup.js" "popup.js"
check_file "classifier.js" "classifier.js"
check_file "styles.css" "styles.css"

echo ""

# ── 第三组：复原引擎 ──
echo "【复原引擎】"
RECON_DIR="$(dirname "$0")/reconstructor"
check_file2() {
    if [ -f "$RECON_DIR/$1" ]; then
        check "$2" "ok"
    else
        check "$2" "缺失（需部署到鲲鹏）"
    fi
}
check_file2 "lh_trace_reconstructor_api.py" "复原引擎 API 脚本"
check_file2 "deploy.sh" "鲲鹏部署脚本"

echo ""

# ── 第四组：环境兼容性 ──
echo "【运行环境】"
PYTHON_VER=$(python3 --version 2>/dev/null | head -1 || echo '未安装')
check "Python 3: ${PYTHON_VER}" "ok"
UNAME=$(uname)
check "操作系统: ${UNAME}" "ok"
if [ "$UNAME" = "Darwin" ]; then
    PFINFO=$(pfctl -s info 2>/dev/null | head -1 || echo '状态: 需要root权限查看')
    check "pfctl: ${PFINFO}" "ok"
fi

echo ""
echo "============================================================"
TOTAL=$((PASS + FAIL))
echo " 结果: ${PASS}/${TOTAL} 通过"

if [ "$FAIL" -eq 0 ]; then
    echo -e " 评级: ${GREEN}全部通过 — 浏览器史官 v2.1 已就绪${NC}"
elif [ "$FAIL" -le 2 ]; then
    echo -e " 评级: ${YELLOW}基本就绪 — ${FAIL} 项需关注${NC}"
else
    echo -e " 评级: ${RED}未就绪 — ${FAIL} 项未通过${NC}"
fi

echo "============================================================"
exit $FAIL
