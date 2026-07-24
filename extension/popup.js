// 龍魂 · 浏览器史官 v2.1 — Popup
'use strict';

async function updateDefensePanel() {
    const indicator = document.getElementById('defense-indicator');
    const wallsDiv = document.getElementById('defense-walls');
    chrome.runtime.sendMessage({ action: 'checkDefenseNow' }, (status) => {
        if (!status.collectorOnline) {
            indicator.className = 'offline';
            indicator.textContent = '⚠️ 采集器未连接 (:18775)';
            wallsDiv.innerHTML = '<p class="note">安装采集器以启用四道防线</p>';
            return;
        }
        if (status.overall) { indicator.className = 'green'; indicator.textContent = '🟢 四道防线全线绿灯'; }
        else {
            indicator.className = 'red';
            const reds = Object.values(status.walls).filter(w => !w.green).length;
            indicator.textContent = `🔴 ${reds} 道防线未就绪`;
        }
        const wallNames = { 'wall_1_network_guard': '一·网络守卫', 'wall_2_malware_guard': '二·恶意过滤', 'wall_3_device_vault': '三·设备金库', 'wall_4_export_signer': '四·导出签名' };
        wallsDiv.innerHTML = Object.entries(status.walls).map(([key, wall]) => {
            const name = wallNames[key] || key;
            const icon = wall.green ? '🟢' : '🔴';
            return `<div class="wall-item ${wall.green ? 'green' : 'red'}">${icon} ${name}</div>`;
        }).join('');
    });
}

async function scanHistory(maxResults) {
    maxResults = maxResults || 5000;
    document.getElementById('scan-progress').classList.remove('hidden');
    return new Promise((resolve) => {
        chrome.history.search({ text: '', maxResults, startTime: 0 }, (items) => {
            document.getElementById('scan-progress').classList.add('hidden');
            resolve(items);
        });
    });
}

function renderCategories(historyItems) {
    const grid = document.getElementById('category-grid');
    const classifier = new BrowserClassifier();
    const categories = {};
    historyItems.forEach(item => {
        const cat = classifier.classify(item.url, item.title || '');
        if (!categories[cat]) categories[cat] = [];
        categories[cat].push(item);
    });
    grid.innerHTML = Object.entries(categories).sort((a, b) => b[1].length - a[1].length).map(([cat, items]) => {
        const pct = ((items.length / historyItems.length) * 100).toFixed(1);
        return `<div class="cat-item"><span class="cat-icon">${classifier.getCatIcon(cat)}</span><span class="cat-name">${cat}</span><span class="cat-count">${items.length}</span><span class="cat-pct">${pct}%</span></div>`;
    }).join('');
    document.getElementById('stats-summary').innerHTML = `总计 ${historyItems.length} 条 · ${Object.keys(categories).length} 个分类`;
}

document.getElementById('btn-scan').addEventListener('click', async () => {
    document.getElementById('btn-scan').disabled = true;
    const items = await scanHistory();
    renderCategories(items);
    document.getElementById('btn-scan').disabled = false;
});

document.getElementById('btn-scan-today').addEventListener('click', async () => {
    const items = await scanHistory(500);
    renderCategories(items);
});

updateDefensePanel();