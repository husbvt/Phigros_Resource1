#!/bin/bash

# 1. 基础配置
BASE_URL="https://phigros-res.l1quid.dpdns.org"

echo "正在生成合并版下载站 (含完整交互动画)..."

# 2. 写入 HTML 静态结构 (包含 CSS 动画与 JSZip 逻辑)
cat > home.html <<'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zephyr的下载站</title>
    <script src="https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js"></script>
    <style>
        :root { --blue: #58a6ff; --bg: #0d1117; --card: #161b22; --border: #30363d; --green: #238636; --red: #da3633; }
        body { font-family: -apple-system, system-ui, sans-serif; background: var(--bg); color: #c9d1d9; margin: 0; padding: 15px; }
        .container { max-width: 900px; margin: auto; }
        h1 { color: var(--blue); text-align: center; }
        .search-box { width: 100%; padding: 12px; background: var(--card); border: 1px solid var(--border); color: #fff; border-radius: 8px; margin-bottom: 20px; box-sizing: border-box; }
        
        /* 歌曲卡片合并样式 */
        .song-card { background: var(--card); border: 1px solid var(--border); border-radius: 12px; margin-bottom: 25px; overflow: hidden; animation: fadeIn 0.4s ease; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
        
        .song-header { background: #21262d; padding: 15px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; }
        .song-title { font-size: 1.1em; font-weight: bold; color: var(--blue); }
        .song-content { display: flex; flex-direction: column; padding: 15px; gap: 20px; }
        @media (min-width: 600px) { .song-content { flex-direction: row; } }
        
        .preview-area { flex: 0 0 240px; border-radius: 8px; overflow: hidden; border: 1px solid var(--border); background: #000; height: 140px; }
        .preview-img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.3s; }
        .preview-img:hover { transform: scale(1.05); }

        .resource-list { flex: 1; }
        .file-item { display: flex; align-items: center; background: #0d1117; padding: 10px; margin-bottom: 6px; border-radius: 6px; border: 1px solid var(--border); font-size: 13px; transition: 0.2s; }
        .file-item:hover { background: #1c2128; border-color: var(--blue); }
        .tag { font-size: 0.75em; padding: 2px 6px; border-radius: 4px; color: #fff; margin-right: 8px; font-weight: bold; }
        .tag-ill { background: var(--red); } .tag-audio { background: #1f6feb; } .tag-chart { background: var(--green); }
        .diff { font-size: 0.7em; padding: 1px 5px; border-radius: 3px; margin-left: auto; font-weight: bold; }
        .diff-EZ { background: var(--green); } .diff-HD { background: #0077b6; } .diff-IN { background: var(--red); } .diff-AT { background: #6c757d; }
        
        .btn-zip { background: var(--green); color: white; border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer; font-weight: bold; transition: 0.2s; }
        .btn-zip:hover { opacity: 0.8; }
        .btn-sel { color: var(--blue); cursor: pointer; font-size: 12px; margin-bottom: 10px; display: inline-block; }

        /* 下载进度弹窗动画 */
        #dl-modal { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.85); z-index: 10000; justify-content: center; align-items: center; backdrop-filter: blur(5px); }
        .dl-box { background: #161b22; border: 1px solid var(--border); padding: 30px; border-radius: 16px; width: 320px; text-align: center; box-shadow: 0 10px 40px rgba(0,0,0,0.5); }
        .dl-bar-bg { width: 100%; height: 10px; background: #0d1117; border-radius: 5px; margin: 15px 0; overflow: hidden; }
        .dl-bar-fill { height: 100%; width: 0%; background: var(--green); transition: width 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
    </style>
</head>
<body>
    <div id="dl-modal">
        <div class="dl-box">
            <div id="dl-status" style="font-weight:bold">📦 准备打包资源...</div>
            <div class="dl-bar-bg"><div id="dl-progress" class="dl-bar-fill"></div></div>
            <button id="dl-close" style="display:none; background:var(--blue); color:#fff; border:none; padding:8px 20px; border-radius:6px; cursor:pointer" onclick="location.reload()">完成并刷新</button>
        </div>
    </div>
    <div class="container">
        <h1>🎵 Zephyr的下载站</h1>
        <input type="text" id="search" class="search-box" placeholder="🔍 输入歌曲名称或 ID 搜索...">
        <div id="list">正在加载资源列表...</div>
    </div>
EOF

# 3. 核心归并逻辑：生成唯一 ID 数据集
cd build_repo
# 提取所有文件夹和文件中的唯一歌曲 ID
SONG_IDS=$( ( [ -d "chart" ] && ls chart; [ -d "music" ] && ls music | sed 's/\.[^.]*$//' ) | sort -u )

echo "const db = [" > data.js
for id in $SONG_IDS; do
    # 查找资源，优先匹配带后缀的资源
    ILL=$(find illustration -name "${id}.*" | head -1)
    AUD=$(find music -name "${id}.*" | head -1)
    
    # 获取该 ID 下的所有谱面
    CHARTS_JSON=""
    if [ -d "chart/${id}" ]; then
        for c in $(ls "chart/${id}"/*.json 2>/dev/null); do
            fn=$(basename "$c")
            CHARTS_JSON="$CHARTS_JSON{\"path\":\"$c\",\"name\":\"$fn\"},"
        done
    fi

    # 只有当存在任何一种资源时才写入，避免生成空卡片
    if [ -n "$ILL" ] || [ -n "$AUD" ] || [ -n "$CHARTS_JSON" ]; then
        echo "{id:\"$id\", ill:\"$ILL\", aud:\"$AUD\", charts:[${CHARTS_JSON%,}]}," >> data.js
    fi
done
echo "];" >> data.js
cd ..

# 4. 注入渲染逻辑与交互代码
cat >> home.html <<EOF
<script>
$(cat build_repo/data.js)
const BASE_URL = "$BASE_URL";

function render() {
    const list = document.getElementById('list');
    list.innerHTML = db.map(song => {
        let chartsHtml = song.charts.map(c => {
            let d = ""; const n = c.name.toUpperCase();
            if(n.includes('EZ')) d='EZ'; else if(n.includes('HD')) d='HD'; else if(n.includes('IN')) d='IN'; else if(n.includes('AT')) d='AT';
            return \`<label class="file-item" data-url="\${BASE_URL}/\${c.path}" data-name="\${c.name}"><input type="checkbox" checked><span class="tag tag-chart">谱面</span>\${c.name}\${d?\`<span class="diff diff-\${d}">\${d}</span>\`:''}</label>\`;
        }).join('');

        return \`<div class="song-card" data-id="\${song.id.toLowerCase()}">
            <div class="song-header">
                <span class="song-title">\${song.id}</span>
                <button class="btn-zip" onclick="packDownload('\${song.id}')">📦 打包下载</button>
            </div>
            <div class="song-content">
                <div class="preview-area">\${song.ill ? \`<img class="preview-img" src="\${BASE_URL}/\${song.ill}" loading="lazy">\` : ''}</div>
                <div class="resource-list" id="files-\${song.id}">
                    <div class="btn-sel" onclick="toggleSel('\${song.id}')">☑️ 全选/取消反选</div>
                    \${song.ill ? \`<label class="file-item" data-url="\${BASE_URL}/\${song.ill}" data-name="\${song.ill.split('/').pop()}"><input type="checkbox" checked><span class="tag tag-ill">曲绘</span>\${song.ill.split('/').pop()}</label>\` : ''}
                    \${song.aud ? \`<label class="file-item" data-url="\${BASE_URL}/\${song.aud}" data-name="\${song.aud.split('/').pop()}"><input type="checkbox" checked><span class="tag tag-audio">音频</span>\${song.aud.split('/').pop()}</label>\` : ''}
                    \${chartsHtml}
                </div>
            </div>
        </div>\`;
    }).join('');
}

window.toggleSel = (id) => {
    const cbs = document.getElementById('files-'+id).querySelectorAll('input');
    const all = Array.from(cbs).every(i => i.checked);
    cbs.forEach(i => i.checked = !all);
};

window.packDownload = async (id) => {
    const items = Array.from(document.getElementById('files-'+id).querySelectorAll('.file-item'))
        .filter(i => i.querySelector('input').checked)
        .map(i => ({url: i.dataset.url, name: i.dataset.name}));
    
    if(!items.length) return alert("请至少选择一个文件！");

    const modal = document.getElementById('dl-modal');
    const pBar = document.getElementById('dl-progress');
    const pStatus = document.getElementById('dl-status');
    modal.style.display = 'flex';

    try {
        const zip = new JSZip();
        for(let i=0; i<items.length; i++) {
            pStatus.innerText = \`正在抓取资源 (\${i+1}/\${items.length})...\`;
            const res = await fetch(items[i].url);
            zip.file(items[i].name, await res.blob());
            pBar.style.width = ((i+1)/items.length * 100) + '%';
        }
        pStatus.innerText = "⚡ 正在生成 ZIP 压缩包...";
        const blob = await zip.generateAsync({type:"blob"});
        const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = \`\${id}.zip\`; a.click();
        pStatus.innerText = "✅ 打包下载完成！";
        document.getElementById('dl-close').style.display = 'inline-block';
    } catch(e) {
        pStatus.innerText = "❌ 下载失败: " + e.message;
        document.getElementById('dl-close').style.display = 'inline-block';
    }
};

document.getElementById('search').oninput = (e) => {
    const v = e.target.value.toLowerCase();
    document.querySelectorAll('.song-card').forEach(c => c.style.display = c.dataset.id.includes(v) ? '' : 'none');
};

render();
</script>
</body>
</html>
EOF

echo "✅ home.html 已修复！卡片已合并，动画已恢复。"
