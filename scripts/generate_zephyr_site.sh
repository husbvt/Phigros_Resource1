#!/bin/bash
# generate_zephyr_site.sh - 最终增强版：带去重、进度条、全选、以及灯箱图片预览
set -e

BUILD_REPO="${1:-./build_repo}"
OUTPUT_FILE="${2:-home.html}"
BASE_URL="https://phigros-res.l1quid.dpdns.org"

echo "🚀 正在生成带灯箱预览和进度条的下载站..."

# 1. HTML 头部 (新增灯箱样式)
cat > "$OUTPUT_FILE" <<'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zephyr的下载站</title>
    <script src="https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js"></script>
    <script>
        // 验证动画逻辑 (保持不变)
        (function() {
            document.write('<div id="v-over" style="position:fixed;top:0;left:0;right:0;bottom:0;background:linear-gradient(135deg,#0d1117,#161b22);display:flex;justify-content:center;align-items:center;z-index:9999;transition:0.4s;"><div style="background:#161b22;border:1px solid #30363d;padding:2.5rem;border-radius:15px;width:90%;max-width:400px;text-align:center;box-shadow:0 10px 30px rgba(0,0,0,0.5);"><h2 style="color:#58a6ff;font-family:sans-serif;">🔒 访问验证中</h2><div style="height:8px;background:#30363d;border-radius:4px;margin:20px 0;overflow:hidden;"><div id="p-bar" style="height:100%;background:linear-gradient(90deg,#238636,#2ea043);width:0%;transition:0.3s;"></div></div><p id="v-stat" style="color:#8b949e;font-size:14px;">正在初始化...</p><button id="re-btn" onclick="location.href=\'index.html\'" style="display:none;margin-top:15px;padding:10px 20px;background:#238636;color:white;border:none;border-radius:6px;cursor:pointer;">返回验证页</button></div></div>');
            let p=0;const iv=setInterval(()=>{p+=Math.random()*15;if(p>95)p=95;document.getElementById('p-bar').style.width=p+'%';},150);
            function ck(){const t=new URLSearchParams(location.search).get('verified')||sessionStorage.getItem('auth_token');if(!t)return false;try{return(Date.now()-parseInt(atob(t).split('_')[0])<600000)}catch(e){return false}}
            setTimeout(()=>{if(ck()){clearInterval(iv);document.getElementById('p-bar').style.width='100%';document.getElementById('v-stat').innerText='✅ 验证通过';setTimeout(()=>{document.getElementById('v-over').style.opacity='0';setTimeout(()=>document.getElementById('v-over').remove(),400);if(window.init)init();},400);}else{clearInterval(iv);document.getElementById('v-stat').innerText='❌ 验证失效';document.getElementById('re-btn').style.display='inline-block';}},1200);
        })();
    </script>
    <style>
        :root { --blue: #58a6ff; --bg: #0d1117; --card: #161b22; --border: #30363d; --green: #238636; }
        body { background: var(--bg); color: #c9d1d9; font-family: sans-serif; margin: 0; padding: 20px; }
        .container { max-width: 900px; margin: 0 auto; }
        .search { width: 100%; padding: 14px; background: var(--card); border: 1px solid var(--border); border-radius: 10px; color: white; margin-bottom: 25px; outline: none; box-sizing: border-box; }
        .song-card { background: var(--card); border: 1px solid var(--border); border-radius: 12px; margin-bottom: 25px; overflow: hidden; animation: fadeIn 0.5s ease; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
        .song-header { background: #21262d; padding: 12px 20px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border); }
        .song-title { color: var(--blue); font-weight: bold; font-size: 1.1em; }
        .song-body { display: flex; padding: 20px; gap: 20px; flex-wrap: wrap; }
        
        /* 修改：曲绘样式，增加点击手势 */
        .preview-img { width: 220px; height: 130px; object-fit: cover; border-radius: 8px; border: 1px solid var(--border); background: #0d1117; cursor: zoom-in; transition: 0.3s; }
        .preview-img:hover { transform: scale(1.03); border-color: var(--blue); }

        .file-list { flex: 1; min-width: 300px; }
        .file-item { display: flex; align-items: center; background: #0d1117; padding: 10px 15px; margin-bottom: 8px; border-radius: 8px; border: 1px solid var(--border); cursor: pointer; }
        .tag { font-size: 12px; padding: 2px 10px; border-radius: 4px; color: white; margin-right: 12px; font-weight: bold; min-width: 45px; text-align: center; }
        .tag-ill { background: #da3633; } .tag-audio { background: #1f6feb; } .tag-chart { background: #238636; }
        .diff { font-size: 11px; padding: 2px 8px; border-radius: 4px; font-weight: bold; margin-left: auto; color: #fff; }
        .diff-sp { background: #f9c74f; color: #000; } .diff-at { background: #6c757d; } .diff-in { background: #da3633; } .diff-hd { background: #0077b6; } .diff-ez { background: #52b788; }
        .btn-pack { background: var(--green); color: white; border: none; padding: 8px 16px; border-radius: 8px; cursor: pointer; font-weight: bold; }
        .btn-sel { background: transparent; color: var(--blue); border: 1px solid var(--blue); padding: 7px 12px; border-radius: 8px; cursor: pointer; font-size: 13px; margin-right: 10px; }

        /* === 新增：下载进度弹窗样式 === */
        #dl-modal { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.8); z-index: 10000; justify-content: center; align-items: center; backdrop-filter: blur(5px); }
        .dl-content { background: #161b22; border: 1px solid #30363d; padding: 30px; border-radius: 12px; width: 90%; max-width: 400px; text-align: center; }
        .dl-bar-bg { width: 100%; height: 10px; background: #30363d; border-radius: 5px; overflow: hidden; margin-bottom: 10px; }
        .dl-bar-fill { height: 100%; width: 0%; background: var(--green); transition: width 0.3s ease; }

        /* === 🖼️ 新增：图片灯箱样式 === */
        #lightbox { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.9); z-index: 10001; justify-content: center; align-items: center; cursor: zoom-out; animation: fadeIn 0.3s; }
        #lightbox img { max-width: 95%; max-height: 90vh; border-radius: 5px; box-shadow: 0 0 30px rgba(0,0,0,0.5); transform: scale(0.9); transition: 0.3s; }
        #lightbox.active img { transform: scale(1); }
    </style>
</head>
<body>
    <div id="lightbox" onclick="closeLightbox()">
        <img id="lb-img" src="" alt="预览图">
    </div>

    <div class="container">
        <h1 style="text-align:center; color: var(--blue);">🎵 Zephyr的下载站</h1>
        <input type="text" id="search" class="search" placeholder="🔍 输入歌曲ID搜索...">
        <div id="list"></div>
    </div>

    <div id="dl-modal">
        <div class="dl-content">
            <div class="dl-title">📦 资源打包中</div>
            <div class="dl-bar-bg"><div id="dl-progress" class="dl-bar-fill"></div></div>
            <div id="dl-text" class="dl-status">准备开始...</div>
            <button id="dl-btn-close" style="margin-top:20px;display:none" onclick="closeDlModal()">关闭</button>
        </div>
    </div>
EOF

# 2. 合并去重扫描逻辑 (保持不变)
cd "$BUILD_REPO"
SONG_IDS=$( ( \
    [ -d "chart" ] && find chart -type d -mindepth 1 -maxdepth 1 | sed 's|chart/||' ; \
    [ -d "music" ] && find music -type f \( -name "*.mp3" -o -name "*.ogg" \) | xargs -I {} basename {} | sed 's/\.[^.]*$//' \
) | sed 's/\.[0-9]*$//' | sort -u )

TMP_DATA=$(mktemp)

for id in $SONG_IDS; do
    ILL=$(find illustration -type f \( -name "${id}.*" -o -name "${id}.*.*" \) 2>/dev/null | head -1)
    AUD=$(find music -type f \( -name "${id}.*" -o -name "${id}.*.*" \) 2>/dev/null | head -1)
    CHART_DIR=""; if [ -d "chart/${id}" ]; then CHART_DIR="chart/${id}"; else POSSIBLE_DIR=$(find chart -type d -name "${id}*" | head -1); [ -n "$POSSIBLE_DIR" ] && CHART_DIR="$POSSIBLE_DIR"; fi
    CHARTS=$( [ -n "$CHART_DIR" ] && find "$CHART_DIR" -type f -name "*.json" 2>/dev/null || echo "" )
    [ -z "$ILL$AUD$CHARTS" ] && continue

    {
        echo "<div class='song-card' data-id='$id'>"
        echo "  <div class='song-header'><span class='song-title'>$id</span><div>"
        echo "    <button class='btn-sel' onclick='toggleAll(this)'>全选/取消</button>"
        echo "    <button class='btn-pack' onclick='pack(this)'>📦 打包下载</button></div></div>"
        echo "  <div class='song-body'>"
        # 修改：曲绘增加 onclick 事件触发灯箱
        echo "    <img class='preview-img' src='${BASE_URL}/$ILL' loading='lazy' onclick='openLightbox(this.src)' onerror='this.style.display=\"none\"'>"
        echo "    <div class='file-list'>"
        [ -n "$ILL" ] && echo "<div class='file-item' data-url='${BASE_URL}/$ILL' data-name='$(basename "$ILL")'><input type='checkbox' checked><span class='tag tag-ill'>曲绘</span><span class='file-name'>$(basename "$ILL")</span></div>"
        [ -n "$AUD" ] && echo "<div class='file-item' data-url='${BASE_URL}/$AUD' data-name='$(basename "$AUD")'><input type='checkbox' checked><span class='tag tag-audio'>音频</span><span class='file-name'>$(basename "$AUD")</span></div>"
        for cp in $CHARTS; do
            fn=$(basename "$cp"); d_t=""; d_c=""
            [[ "${fn^^}" == *SP* ]] && d_t="SP" && d_c="diff-sp"
            [[ "${fn^^}" == *AT* ]] && d_t="AT" && d_c="diff-at"
            [[ "${fn^^}" == *IN* ]] && d_t="IN" && d_c="diff-in"
            [[ "${fn^^}" == *HD* ]] && d_t="HD" && d_c="diff-hd"
            [[ "${fn^^}" == *EZ* ]] && d_t="EZ" && d_c="diff-ez"
            echo "<div class='file-item' data-url='${BASE_URL}/$cp' data-name='$fn'><input type='checkbox' checked><span class='tag tag-chart'>谱面</span><span class='file-name'>$fn</span>${d_t:+"<span class='diff $d_c'>$d_t</span>"}</div>"
        done
        echo "  </div></div></div>"
    } >> "$TMP_DATA"
done
cd - > /dev/null

# 3. JS 逻辑 (新增灯箱控制)
cat >> "$OUTPUT_FILE" <<EOF
    <script>
        window.init = function() {
            const rawData = \`$(cat "$TMP_DATA" | sed "s/'/\\\\'/g" | sed 's/`/\\`/g' | sed 's/\$/\\$/g')\`;
            document.getElementById('list').innerHTML = rawData;
            
            document.addEventListener('click', (e) => {
                const item = e.target.closest('.file-item');
                if (item && e.target.tagName !== 'INPUT') {
                    const cb = item.querySelector('input');
                    cb.checked = !cb.checked;
                }
            });
            document.getElementById('search').oninput = (e) => {
                const s = e.target.value.toLowerCase();
                document.querySelectorAll('.song-card').forEach(c => c.style.display = c.dataset.id.toLowerCase().includes(s) ? '' : 'none');
            };
        };

        // === 🖼️ 灯箱控制逻辑 ===
        function openLightbox(src) {
            const lb = document.getElementById('lightbox');
            const img = document.getElementById('lb-img');
            img.src = src;
            lb.style.display = 'flex';
            setTimeout(() => lb.classList.add('active'), 10);
        }
        function closeLightbox() {
            const lb = document.getElementById('lightbox');
            lb.classList.remove('active');
            setTimeout(() => lb.style.display = 'none', 300);
        }

        window.toggleAll = function(btn) {
            const cbs = btn.closest('.song-card').querySelectorAll('input[type="checkbox"]');
            const anyUn = Array.from(cbs).some(c => !c.checked);
            cbs.forEach(c => c.checked = anyUn);
        };

        function closeDlModal() { document.getElementById('dl-modal').style.display = 'none'; }

        async function pack(btn) {
            const card = btn.closest('.song-card');
            const items = Array.from(card.querySelectorAll('.file-item')).filter(i => i.querySelector('input').checked);
            if (!items.length) return alert('请先勾选文件！');

            const modal = document.getElementById('dl-modal');
            const pBar = document.getElementById('dl-progress');
            const pText = document.getElementById('dl-text');
            const closeBtn = document.getElementById('dl-btn-close');
            
            modal.style.display = 'flex';
            pBar.style.width = '0%';
            pText.innerText = '准备开始...';
            closeBtn.style.display = 'none';

            try {
                const zip = new JSZip();
                let count = 0;
                const total = items.length;
                for (const i of items) {
                    const fileName = i.dataset.name;
                    pText.innerText = \`正在下载 (\${count+1}/\${total}): \${fileName}\`;
                    const r = await fetch(i.dataset.url);
                    if (!r.ok) throw new Error('下载失败');
                    zip.file(fileName, await r.blob());
                    count++;
                    pBar.style.width = ((count / total) * 100) + '%';
                }
                pText.innerText = '正在生成压缩包...';
                const blob = await zip.generateAsync({type:'blob'});
                const a = document.createElement('a');
                a.href = URL.createObjectURL(blob);
                a.download = card.dataset.id + ".zip";
                a.click();
                pText.innerText = '✅ 打包完成！';
                closeBtn.style.display = 'inline-block';
                setTimeout(() => { if(modal.style.display !== 'none') closeDlModal(); }, 2500);
            } catch(e) { 
                pText.innerText = '❌ 错误: ' + e.message;
                closeBtn.style.display = 'inline-block';
            }
        }
    </script>
</body>
</html>
EOF
rm -f "$TMP_DATA"
echo "✅ 增强版下载站已生成！"
