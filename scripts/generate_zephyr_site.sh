#!/bin/bash
# generate_zephyr_site.sh - 最终合并版：验证动画 + 歌曲去重合并 + 五彩标签 + 整行勾选
set -e

# 参数处理
BUILD_REPO="${1:-./build_repo}"
OUTPUT_FILE="${2:-home.html}"
BASE_URL="https://phigros-res.l1quid.dpdns.org"

echo "🚀 正在生成 Zephyr 下载站 (合并去重版)..."

# 1. 写入 HTML/CSS (包含强制验证动画)
cat > "$OUTPUT_FILE" <<'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zephyr的下载站</title>
    <script src="https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js"></script>
    <script>
        // ===== 强制验证动画 logic (严禁删除) =====
        (function() {
            document.write(`
                <div id="v-over" style="position:fixed;top:0;left:0;right:0;bottom:0;background:linear-gradient(135deg, #0d1117 0%, #161b22 100%);display:flex;justify-content:center;align-items:center;z-index:9999;color:#c9d1d9;font-family:sans-serif;transition: opacity 0.4s;">
                    <div style="background:#161b22;border:1px solid #30363d;padding:2.5rem;border-radius:15px;max-width:450px;width:90%;text-align:center;box-shadow:0 10px 30px rgba(0,0,0,0.5);">
                        <h2 style="color:#58a6ff;margin-bottom:1.5rem;">🔒 访问验证中</h2>
                        <div style="margin:2rem 0;">
                            <div style="width:100%;height:8px;background:#30363d;border-radius:4px;overflow:hidden;">
                                <div id="p-bar" style="height:100%;background:linear-gradient(90deg, #238636, #2ea043);width:0%;transition:width 0.3s ease;"></div>
                            </div>
                        </div>
                        <p id="v-stat" style="font-size:0.95rem;color:#8b949e;">正在校验令牌权限...</p>
                        <button id="re-btn" onclick="window.location.href='index.html'" style="display:none;margin-top:1.5rem;padding:10px 20px;background:#238636;color:white;border:none;border-radius:6px;cursor:pointer;font-weight:bold;">返回验证页面</button>
                    </div>
                </div>
            `);
            let p = 0;
            const iv = setInterval(() => {
                p += Math.random() * 12;
                if(p > 95) p = 95;
                const bar = document.getElementById('p-bar');
                if(bar) bar.style.width = p + '%';
            }, 100);
            function check() {
                const t = new URLSearchParams(window.location.search).get('verified') || sessionStorage.getItem('auth_token');
                if(!t) return false;
                try { const d = atob(t); return (Date.now() - parseInt(d.split('_')[0]) < 600000); } catch(e) { return false; }
            }
            setTimeout(() => {
                if(check()) {
                    clearInterval(iv);
                    document.getElementById('p-bar').style.width = '100%';
                    document.getElementById('v-stat').innerHTML = "✅ 验证成功";
                    setTimeout(() => {
                        const over = document.getElementById('v-over');
                        over.style.opacity = '0';
                        setTimeout(() => { over.remove(); if(window.init) init(); }, 400);
                    }, 500);
                } else {
                    clearInterval(iv);
                    document.getElementById('v-stat').innerHTML = "❌ 验证失效";
                    document.getElementById('re-btn').style.display = "inline-block";
                }
            }, 1200);
        })();
    </script>
    <style>
        :root { --blue: #58a6ff; --bg: #0d1117; --card: #161b22; --border: #30363d; --green: #238636; }
        body { background: var(--bg); color: #c9d1d9; font-family: -apple-system, sans-serif; margin: 0; padding: 20px; }
        .container { max-width: 900px; margin: 0 auto; }
        .search { width: 100%; padding: 14px; background: var(--card); border: 1px solid var(--border); border-radius: 10px; color: white; margin-bottom: 25px; outline: none; box-sizing: border-box; }
        .song-card { background: var(--card); border: 1px solid var(--border); border-radius: 12px; margin-bottom: 25px; overflow: hidden; }
        .song-header { background: #21262d; padding: 15px 20px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border); }
        .song-title { color: var(--blue); font-weight: bold; font-size: 1.1em; }
        .song-body { display: flex; padding: 20px; gap: 20px; flex-wrap: wrap; }
        .preview-box { flex: 0 0 220px; }
        .preview-img { width: 100%; height: 130px; object-fit: cover; border-radius: 8px; border: 1px solid var(--border); }
        .file-list { flex: 1; min-width: 300px; }
        .file-item { 
            display: flex; align-items: center; background: #0d1117; 
            padding: 10px 15px; margin-bottom: 8px; border-radius: 8px; 
            border: 1px solid var(--border); cursor: pointer; transition: 0.2s; user-select: none;
        }
        .file-item:hover { background: #1c2128; border-color: var(--blue); }
        .file-item input { margin-right: 15px; width: 18px; height: 18px; accent-color: var(--green); cursor: pointer; }
        .tag { font-size: 12px; padding: 2px 10px; border-radius: 4px; color: white; margin-right: 12px; font-weight: bold; min-width: 45px; text-align: center; }
        .tag-ill { background: #da3633; }
        .tag-audio { background: #1f6feb; }
        .tag-chart { background: #238636; }
        .file-name { flex: 1; font-size: 14px; color: #adbac7; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .diff { font-size: 11px; padding: 2px 8px; border-radius: 4px; font-weight: bold; margin-left: 10px; color: #fff; }
        .diff-sp { background: #f9c74f; color: #000; }
        .diff-at { background: #6c757d; }
        .diff-in { background: #da3633; }
        .diff-hd { background: #0077b6; }
        .diff-ez { background: #52b788; }
        .btn-pack { background: var(--green); color: white; border: none; padding: 8px 16px; border-radius: 8px; cursor: pointer; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1 style="text-align:center; color: var(--blue);">🎵 Zephyr的下载站</h1>
        <input type="text" id="search" class="search" placeholder="🔍 搜索歌曲ID...">
        <div id="list"></div>
    </div>
EOF

# 2. 逻辑核心：合并扫描结果
cd "$BUILD_REPO"
# 获取去重后的所有歌曲ID
SONG_IDS=$( ( [ -d "chart" ] && find chart -type d -mindepth 1 -maxdepth 1 | sed 's|chart/||' ; \
               [ -d "music" ] && find music -type f \( -name "*.mp3" -o -name "*.ogg" \) | xargs -I {} basename {} | sed 's/\.[^.]*$//' ) | sort -u)

TMP_DATA=$(mktemp)
for id in $SONG_IDS; do
    id_clean=$(echo "$id" | sed 's/\.[0-9]*$//')
    
    # 在不同文件夹寻找关联资源
    ILL=$(find illustration -type f \( -name "${id}.*" -o -name "${id_clean}.*" \) 2>/dev/null | head -1)
    AUD=$(find music -type f \( -name "${id}.*" -o -name "${id_clean}.*" \) 2>/dev/null | head -1)
    # 查找谱面 (对应 ID 文件夹下的所有 JSON)
    CHARTS=$( [ -d "chart/${id}" ] && find "chart/${id}" -type f -name "*.json" 2>/dev/null || echo "" )

    [ -z "$ILL$AUD$CHARTS" ] && continue

    {
        echo "<div class='song-card' data-id='$id_clean'>"
        echo "  <div class='song-header'><span class='song-title'>$id_clean</span><button class='btn-pack' onclick='pack(\"$id_clean\", this)'>📦 打包下载</button></div>"
        echo "  <div class='song-body'>"
        echo "    <div class='preview-box'><img class='preview-img' src='${BASE_URL}/$ILL' loading='lazy'></div>"
        echo "    <div class='file-list' id='f-$id_clean'>"
        
        # 曲绘行
        [ -n "$ILL" ] && echo "<div class='file-item' data-url='${BASE_URL}/$ILL' data-name='$(basename "$ILL")'><input type='checkbox' checked><span class='tag tag-ill'>曲绘</span><span class='file-name'>$(basename "$ILL")</span></div>"
        
        # 音频行
        [ -n "$AUD" ] && echo "<div class='file-item' data-url='${BASE_URL}/$AUD' data-name='$(basename "$AUD")'><input type='checkbox' checked><span class='tag tag-audio'>音频</span><span class='file-name'>$(basename "$AUD")</span></div>"
        
        # 谱面行 (带五色标签)
        for cp in $CHARTS; do
            fn=$(basename "$cp"); d_t=""; d_c=""
            [[ "${fn^^}" == *SP* ]] && d_t="SP" && d_c="diff-sp"
            [[ "${fn^^}" == *AT* ]] && d_t="AT" && d_c="diff-at"
            [[ "${fn^^}" == *IN* ]] && d_t="IN" && d_c="diff-in"
            [[ "${fn^^}" == *HD* ]] && d_t="HD" && d_c="diff-hd"
            [[ "${fn^^}" == *EZ* ]] && d_t="EZ" && d_c="diff-ez"
            echo "<div class='file-item' data-url='${BASE_URL}/$cp' data-name='$fn'><input type='checkbox' checked><span class='tag tag-chart'>谱面</span><span class='file-name'>$fn</span>${d_t:+"<span class='diff $d_c'>$d_t</span>"}</div>"
        done
        echo "    </div></div></div>"
    } >> "$TMP_DATA"
done
cd - > /dev/null

# 3. 注入 JS 逻辑 (整行点击 + 打包)
cat >> "$OUTPUT_FILE" <<EOF
    <script>
        window.init = function() {
            document.getElementById('list').innerHTML = \`$(cat "$TMP_DATA" | sed 's/`/\\`/g' | sed 's/\$/\\$/g')\`;
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
        async function pack(id, btn) {
            const files = Array.from(document.querySelectorAll('#f-'+id+' .file-item')).filter(i => i.querySelector('input').checked);
            if (!files.length) return alert('未选择文件');
            btn.disabled = true; btn.innerText = '⏳...';
            try {
                const zip = new JSZip();
                for (const f of files) {
                    const res = await fetch(f.dataset.url);
                    zip.file(f.dataset.name, await res.blob());
                }
                const b = await zip.generateAsync({type:'blob'});
                const a = document.createElement('a'); a.href = URL.createObjectURL(b); a.download = id+".zip"; a.click();
                btn.innerText = '✅ 完成';
            } catch(e) { btn.innerText = '❌ 错误'; }
            setTimeout(() => { btn.disabled = false; btn.innerText = '📦 打包下载'; }, 2000);
        }
    </script>
</body>
</html>
EOF
rm -f "$TMP_DATA"
echo "✅ 搞定！歌曲资源已合并，动画已保留。"
