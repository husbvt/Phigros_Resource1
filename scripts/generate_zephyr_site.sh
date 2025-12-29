#!/bin/bash
# generate_zephyr_site.sh - 深度还原版：验证动画 + 五彩标签 + 整行勾选交互
set -e

# 参数处理
BUILD_REPO="${1:-./build_repo}"
OUTPUT_FILE="${2:-home.html}"
BASE_URL="https://phigros-res.l1quid.dpdns.org"

echo "🚀 正在生成 Zephyr 下载站 (完整动画版)..."

# 1. 写入 HTML/CSS (包含完整的验证遮罩动画)
cat > "$OUTPUT_FILE" <<'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zephyr的下载站</title>
    <script src="https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js"></script>
    <script>
        // ===== 强制验证动画逻辑 - 绝对保留 =====
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
                        <p id="v-stat" style="font-size:0.95rem;color:#8b949e;">正在校验安全令牌...</p>
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
                try {
                    const d = atob(t);
                    return (Date.now() - parseInt(d.split('_')[0]) < 600000);
                } catch(e) { return false; }
            }

            setTimeout(() => {
                if(check()) {
                    clearInterval(iv);
                    document.getElementById('p-bar').style.width = '100%';
                    document.getElementById('v-stat').innerHTML = "✅ 验证通过，正在进入站点...";
                    setTimeout(() => {
                        const over = document.getElementById('v-over');
                        over.style.opacity = '0';
                        setTimeout(() => { over.remove(); if(window.init) init(); }, 400);
                    }, 500);
                } else {
                    clearInterval(iv);
                    document.getElementById('v-stat').innerHTML = "❌ 验证失效或令牌错误";
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
        .search:focus { border-color: var(--blue); }
        .song-card { background: var(--card); border: 1px solid var(--border); border-radius: 12px; margin-bottom: 25px; overflow: hidden; }
        .song-header { background: #21262d; padding: 15px 20px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border); }
        .song-title { color: var(--blue); font-weight: bold; font-size: 1.1em; }
        .song-body { display: flex; padding: 20px; gap: 20px; flex-wrap: wrap; }
        .preview-box { flex: 0 0 220px; }
        .preview-img { width: 100%; height: 130px; object-fit: cover; border-radius: 8px; border: 1px solid var(--border); }
        .file-list { flex: 1; min-width: 300px; }
        
        /* 文件项点击整行勾选样式 */
        .file-item { 
            display: flex; align-items: center; background: #0d1117; 
            padding: 12px 15px; margin-bottom: 10px; border-radius: 8px; 
            border: 1px solid var(--border); cursor: pointer; 
            transition: all 0.2s; user-select: none;
        }
        .file-item:hover { background: #1c2128; border-color: var(--blue); transform: translateX(5px); }
        .file-item input[type="checkbox"] { margin-right: 15px; width: 18px; height: 18px; accent-color: var(--green); cursor: pointer; }
        
        .tag { font-size: 12px; padding: 2px 10px; border-radius: 4px; color: white; margin-right: 12px; font-weight: bold; min-width: 45px; text-align: center; }
        .tag-ill { background: #da3633; }
        .tag-audio { background: #1f6feb; }
        .tag-chart { background: #238636; }
        
        .file-name { flex: 1; font-size: 14px; color: #adbac7; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        
        /* 难度标签样式 */
        .diff { font-size: 11px; padding: 2px 8px; border-radius: 4px; font-weight: bold; margin-left: 10px; color: #fff; }
        .diff-sp { background: #f9c74f; color: #000; } /* 黄色 */
        .diff-at { background: #6c757d; }             /* 灰色 */
        .diff-in { background: #da3633; }             /* 红色 */
        .diff-hd { background: #0077b6; }             /* 蓝色 */
        .diff-ez { background: #52b788; }             /* 绿色 */

        .btn-pack { background: var(--green); color: white; border: none; padding: 10px 20px; border-radius: 8px; cursor: pointer; font-weight: bold; }
        .btn-pack:disabled { opacity: 0.5; }
    </style>
</head>
<body>
    <div class="container">
        <h1 style="text-align:center; color: var(--blue); margin-bottom: 30px;">🎵 Zephyr的下载站</h1>
        <input type="text" id="search" class="search" placeholder="🔍 搜索歌曲ID...">
        <div id="list"></div>
    </div>
EOF

# 2. 扫描文件并生成歌曲数据
cd "$BUILD_REPO"
SONG_IDS=$( ( [ -d "chart" ] && find chart -type d -mindepth 1 -maxdepth 1 | sed 's|chart/||' ; \
               [ -d "music" ] && find music -type f \( -name "*.mp3" -o -name "*.ogg" \) | xargs -I {} basename {} | sed 's/\.[^.]*$//' ) | sort -u)

TMP_DATA=$(mktemp)
for id in $SONG_IDS; do
    id_c=$(echo "$id" | sed 's/\.[0-9]*$//')
    ILL=$(find illustration -type f \( -name "${id}.*" -o -name "${id_clean}.*" \) 2>/dev/null | head -1)
    AUD=$(find music -type f \( -name "${id}.*" -o -name "${id_clean}.*" \) 2>/dev/null | head -1)
    CHARTS=$( [ -d "chart/${id}" ] && find "chart/${id}" -type f -name "*.json" 2>/dev/null || echo "" )

    [ -z "$ILL$AUD$CHARTS" ] && continue

    {
        echo "<div class='song-card' data-id='$id_c'>"
        echo "  <div class='song-header'><span class='song-title'>$id_c</span><button class='btn-pack' onclick='pack(\"$id_c\", this)'>📦 打包下载</button></div>"
        echo "  <div class='song-body'>"
        echo "    <div class='preview-box'><img class='preview-img' src='${BASE_URL}/$ILL' loading='lazy'></div>"
        echo "    <div class='file-list' id='f-$id_c'>"
        
        [ -n "$ILL" ] && echo "<div class='file-item' data-url='${BASE_URL}/$ILL' data-name='$(basename "$ILL")'><input type='checkbox' checked><span class='tag tag-ill'>曲绘</span><span class='file-name'>$(basename "$ILL")</span></div>"
        [ -n "$AUD" ] && echo "<div class='file-item' data-url='${BASE_URL}/$AUD' data-name='$(basename "$AUD")'><input type='checkbox' checked><span class='tag tag-audio'>音频</span><span class='file-name'>$(basename "$AUD")</span></div>"
        
        for cp in $CHARTS; do
            fn=$(basename "$cp"); d_text=""; d_class=""
            [[ "${fn^^}" == *SP* ]] && d_text="SP" && d_class="diff-sp"
            [[ "${fn^^}" == *AT* ]] && d_text="AT" && d_class="diff-at"
            [[ "${fn^^}" == *IN* ]] && d_text="IN" && d_class="diff-in"
            [[ "${fn^^}" == *HD* ]] && d_text="HD" && d_class="diff-hd"
            [[ "${fn^^}" == *EZ* ]] && d_text="EZ" && d_class="diff-ez"
            echo "<div class='file-item' data-url='${BASE_URL}/$cp' data-name='$fn'><input type='checkbox' checked><span class='tag tag-chart'>谱面</span><span class='file-name'>$fn</span>${d_text:+"<span class='diff $d_class'>$d_text</span>"}</div>"
        done
        echo "    </div></div></div>"
    } >> "$TMP_DATA"
done
cd - > /dev/null

# 3. 注入 JS 交互 (包含整行点击逻辑)
cat >> "$OUTPUT_FILE" <<EOF
    <script>
        window.init = function() {
            document.getElementById('list').innerHTML = \`$(cat "$TMP_DATA" | sed 's/`/\\`/g' | sed 's/\$/\\$/g')\`;
            
            // 点击整行勾选
            document.addEventListener('click', (e) => {
                const item = e.target.closest('.file-item');
                if (item && e.target.tagName !== 'INPUT') {
                    const cb = item.querySelector('input');
                    cb.checked = !cb.checked;
                }
            });

            // 搜索过滤
            document.getElementById('search').oninput = (e) => {
                const s = e.target.value.toLowerCase();
                document.querySelectorAll('.song-card').forEach(c => {
                    c.style.display = c.dataset.id.toLowerCase().includes(s) ? '' : 'none';
                });
            };
        };

        async function pack(id, btn) {
            const selected = Array.from(document.querySelectorAll('#f-'+id+' .file-item')).filter(i => i.querySelector('input').checked);
            if (!selected.length) return alert('未选择任何文件！');
            btn.disabled = true; btn.innerText = '⏳ 打包中...';
            try {
                const zip = new JSZip();
                for (const i of selected) {
                    const res = await fetch(i.dataset.url);
                    zip.file(i.dataset.name, await res.blob());
                }
                const b = await zip.generateAsync({type: 'blob'});
                const a = document.createElement('a'); a.href = URL.createObjectURL(b); a.download = id + ".zip"; a.click();
                btn.innerText = '✅ 下载成功';
            } catch(e) { btn.innerText = '❌ 失败'; }
            setTimeout(() => { btn.disabled = false; btn.innerText = '📦 打包下载'; }, 2000);
        }
    </script>
</body>
</html>
EOF
rm -f "$TMP_DATA"
echo "✅ 生成完成！"
