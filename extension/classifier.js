// 龍魂 · 浏览器史官 v2.1 — 智能分类器
'use strict';

class BrowserClassifier {
    constructor() {
        this.categories = {
            'AI / 技術': { icon: '🤖' },
            '開發 / 編程': { icon: '⚡' },
            '搜索引擎': { icon: '🔍' },
            '新聞資訊': { icon: '📰' },
            '社交媒體': { icon: '📱' },
            '購物消費': { icon: '🛒' },
            '視頻娛樂': { icon: '🎬' },
            '遊戲': { icon: '🎮' },
            '音樂 / 音頻': { icon: '🎵' },
            '圖片 / 設計': { icon: '🎨' },
            '文檔 / 辦公': { icon: '📄' },
            '成人內容': { icon: '🔞' },
            '金融 / 理財': { icon: '💰' },
            '教育 / 學習': { icon: '📚' },
            '旅遊 / 出行': { icon: '✈️' },
            '健康 / 醫療': { icon: '🏥' },
            '其他 / 兜底': { icon: '📌' }
        };
        this.rules = [
            { cat: 'AI / 技術', patterns: ['openai.com','chatgpt','claude.ai','gemini','deepseek','huggingface','github.com','paperswithcode','arxiv.org','ollama','langchain'] },
            { cat: '開發 / 編程', patterns: ['stackoverflow.com','github.com','npmjs.com','pypi.org','dev.to','leetcode','docker','kubernetes','rust','golang','typescript'] },
            { cat: '搜索引擎', patterns: ['google.com/search','baidu.com/s','bing.com/search','duckduckgo','?q=','?query='] },
            { cat: '社交媒體', patterns: ['twitter.com','x.com','facebook.com','instagram.com','tiktok.com','reddit.com','weibo.com','zhihu.com','linkedin.com','discord.com','telegram.org'] },
            { cat: '新聞資訊', patterns: ['/news/','bbc.com','cnn.com','reuters.com','techcrunch','theverge','hackernews','36kr.com','huxiu.com'] },
            { cat: '購物消費', patterns: ['amazon.com','taobao.com','tmall.com','jd.com','ebay.com','aliexpress','/product/','/cart','/checkout'] },
            { cat: '視頻娛樂', patterns: ['youtube.com','bilibili.com','vimeo.com','twitch.tv','netflix.com','/watch','/video/'] },
            { cat: '遊戲', patterns: ['steampowered.com','epicgames.com','roblox.com','minecraft','/game/'] },
            { cat: '音樂 / 音頻', patterns: ['spotify.com','soundcloud.com','bandcamp','/music/','podcast'] },
            { cat: '圖片 / 設計', patterns: ['pinterest.com','dribbble.com','figma.com','canva.com','/gallery/'] },
            { cat: '文檔 / 辦公', patterns: ['docs.google.com','notion.so','confluence','office.com','sharepoint','pdf'] },
            { cat: '成人內容', patterns: ['pornhub','xvideos','xnxx','onlyfans','/adult/','/nsfw/'] },
            { cat: '金融 / 理財', patterns: ['coinbase','binance','coinmarketcap','tradingview','finance.yahoo','/crypto/'] },
            { cat: '教育 / 學習', patterns: ['coursera.org','udemy.com','khanacademy','/course/','/learn/','.edu/'] },
            { cat: '旅遊 / 出行', patterns: ['booking.com','airbnb.com','tripadvisor','/hotel/','/flight/','maps.google'] },
            { cat: '健康 / 醫療', patterns: ['webmd.com','mayoclinic','nih.gov','who.int','/health/','/medical/'] },
        ];
    }
    classify(url, title) {
        title = title || '';
        const searchStr = (url + ' ' + title).toLowerCase();
        for (const rule of this.rules) {
            for (const pattern of rule.patterns) {
                if (searchStr.includes(pattern)) return rule.cat;
            }
        }
        return '其他 / 兜底';
    }
    getCatIcon(cat) { return this.categories[cat] ? this.categories[cat].icon : '📌'; }
}
if (typeof window !== 'undefined') window.BrowserClassifier = BrowserClassifier;