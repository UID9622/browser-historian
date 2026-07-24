// 龍魂 · 浏览器史官 v2.1 — Background Service Worker
'use strict';

let defenseStatus = { overall: false, walls: {}, lastCheck: 0, collectorOnline: false };

async function checkDefenseStatus() {
    try {
        const resp = await fetch('http://127.0.0.1:18775/defense/status', {
            method: 'GET', signal: AbortSignal.timeout(2000)
        });
        if (resp.ok) {
            const data = await resp.json();
            defenseStatus = { overall: data.overall_green || false, walls: data.walls || {}, lastCheck: Date.now(), collectorOnline: true };
            if (data.overall_green) {
                chrome.action.setBadgeText({ text: 'GUARD' });
                chrome.action.setBadgeBackgroundColor({ color: '#4CAF50' });
            } else {
                const reds = Object.values(data.walls || {}).filter(w => w.green === false).length;
                chrome.action.setBadgeText({ text: reds > 0 ? String(reds) : '?' });
                chrome.action.setBadgeBackgroundColor({ color: '#E53935' });
            }
        }
    } catch (e) {
        defenseStatus.collectorOnline = false;
        defenseStatus.lastCheck = Date.now();
        chrome.action.setBadgeText({ text: '!' });
        chrome.action.setBadgeBackgroundColor({ color: '#FF9800' });
    }
}

chrome.runtime.onInstalled.addListener(() => { console.log('[史官 v2.1] 四道防线就绪'); checkDefenseStatus(); });
chrome.runtime.onStartup.addListener(() => checkDefenseStatus());
chrome.alarms.create('defense-check', { periodInMinutes: 0.5 });
chrome.alarms.onAlarm.addListener((alarm) => { if (alarm.name === 'defense-check') checkDefenseStatus(); });
chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
    if (msg.action === 'getDefenseStatus') sendResponse(defenseStatus);
    else if (msg.action === 'checkDefenseNow') { checkDefenseStatus().then(() => sendResponse(defenseStatus)); return true; }
});
checkDefenseStatus();