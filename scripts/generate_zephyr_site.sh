#!/bin/bash

# 1. 基础配置
BASE_URL="https://phigros-res.l1quid.dpdns.org"

echo "开始构建下载站主页面..."

# 2. 生成 HTML 静态外壳 (使用单引号 'EOF' 严防变量解析冲突)
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
        
        /* 歌曲卡片 */
        .song-card { background: var(--card); border: 1px solid var(--border); border-radius: 12px; margin-bottom: 25px; overflow: hidden; }
        .song-header { background: #21262d; padding: 15px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; }
        .song-title { font-size: 1.1em; font-weight: bold; color: var(--blue); }
        .song-content { display: flex; flex-direction: column; padding: 15px; gap: 20px; }
        @media (min-width: 600px) { .song-content { flex-direction: row; } }
        
        /* 曲绘预览与灯箱 */
        .preview-area { flex: 0 0 240px; position: relative; cursor: zoom-in; border-radius: 8px; overflow: hidden; border: 1px solid var(--border); }
        .preview-img { width: 100%; height: 140px; object-fit: cover; }
        #lightbox { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.9); z-index: 10001; justify-content: center; align-items: center; cursor: zoom-out; }
        #lightbox img { max-width: 95%; max-height: 95vh; border-radius: 4px; box-shadow: 0 0 30px rgba(0,0,0,0.5); }

        /* 文件列表与标签 */
        .resource-list { flex: 1; }
        .file-item { display: flex; align-items: center; background: #0d1117; padding: 10px; margin-bottom: 6px; border-radius: 6px; border: 1px solid var(--border); font-size: 13px; }
        .file-item input { margin-right: 12px; accent-color: var(--green); }
        .tag { font-size: 0.75em; padding: 2px 6px; border-radius: 4px; color: #fff; margin-right: 8px; font-weight: bold; }
        .tag-ill { background: var(--red); } .tag-audio { background: #1f6feb; } .tag-chart { background: var(--green); }
        .diff { font-size: 0.7em; padding: 1px 5px; border-radius: 3px; margin-left: auto; font-weight: bold; }
        .diff-EZ { background: var(--green); } .diff-HD { background: #0077b6; } .diff-IN { background: #da3633; } .diff-AT { background: #6c757d; }
        
        /* 下载进度弹窗 */
        #dl-modal { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.8); z-index: 10000; justify-content: center; align-items: center; backdrop-filter: blur(4px); }
        .dl-box { background: #161b22; border: 1px solid var(--border); padding: 30px; border-radius: 16px; width: 320px; text-align: center; }
        .dl-bar-bg { width: 100%; height: 10px; background: #0d1117; border-radius: 5px; margin: 15px 0; overflow: hidden; border: 1px solid var(--border); }
        .dl-bar-fill { height: 100%; width: 0%; background: var(--green); transition: width 0.3s; }
        .btn-zip { background: var(--green); color: white; border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer; font-weight: bold; }
        .btn-sel { background: transparent; color: var(--blue); border: 1px solid var(--border); padding: 4px 8px; border-radius: 4px; cursor: pointer; font-size: 11px; margin-bottom: 8px; }
    </style>
</head>
<body>
    <div id="dl-modal">
        <div class="dl-box">
            <div id="dl-status" style="margin-bottom:10px">📦 准备打包...</div>
            <div class="dl-bar-bg"><div id="dl-progress" class="dl-bar-fill"></div></div>
            <button id="dl-close" style="display:none; margin-top:10px" onclick="document.getElementById('dl-modal').style.display='none'">关闭</button>
        </div>
    </div>
    <div id="lightbox" onclick="this.style.display='none'"><img id="lb-img"></div>

    <div class="container">
        <h1>🎵 Zephyr的下载站</h1>
        <input type="text" id="search" class="search-box" placeholder="🔍 搜索歌曲 ID...">
        <div id="list"></div>
    </div>
EOF

# 3. 扫描文件并生成 JS 数据 (这是为了防止文件名特殊字符导致注入失败)
cd build_repo
SONG_IDS=$( ( [ -d "chart" ] && ls chart; [ -d "music" ] && ls music | sed 's/\.[^.]*$//' ) | sort -u )

echo "const db = [" > song_data.js
for id in $SONG_IDS; do
    # 查找曲绘和音频
    ILL=$(find illustration -name "${id}.*" | head -1)
    AUD=$(find music -name "${id}.*" | head -1)
    # 查找谱面目录（兼容处理）
    C_DIR="chart/$id"; [ ! -d "$C_DIR" ] && C_DIR=$(find chart -name "${id}*" -type d | head -1)
    CHARTS=$( [ -n "$C_DIR" ] && find "$C_DIR" -name "*.json" || echo "" )

    if [ -n "$ILL" ] || [ -n "$AUD" ] || [ -n "$CHARTS" ]; then
        echo "{id:\"$id\", ill:\"$ILL\", aud:\"$AUD\", charts:[" >> song_data.js
        for c in $CHARTS; do
            echo "{path:\"$c\", name:\"$(basename "$c")\"}," >> song_data.js
        done
        echo "]}," >> song_data.js
    fi
done
echo "];" >> song_data.js
cd ..

# 4. 注入渲染逻辑与基础 URL
cat >> home.html <<EOF
<script>
EOF
cat build_repo/song_data.js >> home.html
cat >> home.html <<'EOF'
const BASE_URL = "https://phigros-res.l1quid.dpdns.org";

function render() {
    const container = document.getElementById('list');
    container.innerHTML = db.map(song => {
        let chartItems = song.charts.map(c => {
            let d = ""; const n = c.name.toUpperCase();
            if(n.includes('EZ')) d='EZ'; else if(n.includes('HD')) d='HD'; else if(n.includes('IN')) d='IN'; else if(n.includes('AT')) d='AT';
            return `<label class="file-item" data-url="${BASE_URL}/${c.path}" data-name="${c.name}"><input type="checkbox" checked><span class="tag tag-chart">谱面</span>${c.name}${d?`<span class="diff diff-${d}">${d}</span>`:''}</label>`;
        }).join('');

        return `<div class="song-card" data-id="${song.id.toLowerCase()}">
            <div class="song-header"><span class="song-title">${song.id}</span><button class="btn-zip" onclick="startDownload('${song.id}')">📦 打包下载</button></div>
            <div class="song-content">
                <div class="preview-area" onclick="openLB('${BASE_URL}/${song.ill}')">
                    <img class="preview-img" src="${BASE_URL}/${song.ill}" loading="lazy">
                </div>
                <div class="resource-list" id="files-${song.id}">
                    <div class="btn-sel" onclick="toggleSel(this)">全选/反选</div>
                    ${song.ill ? `<label class="file-item" data-url="${BASE_URL}/${song.ill}" data-name="${song.ill.split('/').pop()}"><input type="checkbox" checked><span class="tag tag-ill">曲绘</span>${song.ill.split('/').pop()}</label>` : ''}
                    ${song.aud ? `<label class="file-item" data-url="${BASE_URL}/${song.aud}" data-name="${song.aud.split('/').pop()}"><input type="checkbox" checked><span class="tag tag-audio">音频</span>${song.aud.split('/').pop()}</label>` : ''}
                    ${chartItems}
                </div>
            </div>
        </div>`;
    }).join('');
}

window.openLB = (u) => { document.getElementById('lb-img').src=u; document.getElementById('lightbox').style.display='flex'; };
window.toggleSel = (b) => { const cbs = b.parentElement.querySelectorAll('input'); const all = Array.from(cbs).every(i=>i.checked); cbs.forEach(i=>i.checked=!all); };

window.startDownload = async (id) => {
    const items = Array.from(document.getElementById('files-'+id).querySelectorAll('.file-item'))
        .filter(i => i.querySelector('input').checked)
        .map(i => ({url: i.dataset.url, name: i.dataset.name}));
    if(!items.length) return alert("请选择要下载的内容");

    const modal = document.getElementById('dl-modal');
    const pBar = document.getElementById('dl-progress');
    const pStatus = document.getElementById('dl-status');
    modal.style.display = 'flex'; pBar.style.width = '0%';

    try {
        const zip = new JSZip();
        for(let i=0; i<items.length; i++){
            pStatus.innerText = `下载中 (${i+1}/${items.length})...`;
            const res = await fetch(items[i].url);
            zip.file(items[i].name, await res.blob());
            pBar.style.width = ((i+1)/items.length * 100) + '%';
        }
        pStatus.innerText = "正在生成压缩包...";
        const content = await zip.generateAsync({type:"blob"});
        const a = document.createElement('a'); a.href = URL.createObjectURL(content); a.download = `${id}.zip`; a.click();
        pStatus.innerText = "✅ 下载完成！";
        document.getElementById('dl-close').style.display = 'inline-block';
    } catch(e) { pStatus.innerText = "❌ 发生错误"; document.getElementById('dl-close').style.display = 'inline-block'; }
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

echo "构建成功，home.html 已生成。"
