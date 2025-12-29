#!/bin/bash
# generate_zephyr_site.sh - 整合版：包含强验证、全量扫描、点击整行勾选
set -e

# 参数设置
BUILD_REPO="${1:-./build_repo}" # 资源库所在目录
OUTPUT_FILE="${2:-home.html}"   # 生成的HTML文件名
BASE_URL="https://phigros-res.l1quid.dpdns.org"

echo "开始生成 Zephyr 下载站..."
echo "资源目录: $BUILD_REPO"
echo "输出文件: $OUTPUT_FILE"

# 1. 生成 HTML 头部
cat > "$OUTPUT_FILE" <<'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zephyr的下载站</title>
    <script src="https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js"></script>
    <script>
        // ===== 强化的访问控制验证 =====
        (function() {
            document.write(`
                <div id="verify-overlay" style="position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: linear-gradient(135deg, #0d1117 0%, #161b22 100%); display: flex; justify-content: center; align-items: center; z-index: 9999; color: #c9d1d9; font-family: sans-serif;">
                    <div style="background: #161b22; border: 1px solid #30363d; padding: 2rem; border-radius: 12px; max-width: 500px; width: 90%; text-align: center;">
                        <h2 style="color: #58a6ff; margin-bottom: 1rem;">🔒 访问验证中</h2>
                        <div style="margin: 2rem 0;">
                            <div style="width: 100%; height: 6px; background: #30363d; border-radius: 3px; overflow: hidden;">
                                <div id="verifyProgress" style="height: 100%; background: #238636; width: 0%; transition: width 0.5s ease;"></div>
                            </div>
                        </div>
                        <p id="verifyStatus">正在检查令牌有效性...</p>
                        <button onclick="window.location.href='index.html'" style="margin-top: 1rem; padding: 10px 20px; background: #238636; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: bold; display:none;" id="btn-reverify">前往验证页面</button>
                    </div>
                </div>
            `);

            let progress = 0;
            const progressInterval = setInterval(() => {
                progress += 10;
                const bar = document.getElementById('verifyProgress');
                if(bar) bar.style.width = progress + '%';
                if(progress >= 100) clearInterval(progressInterval);
            }, 50);

            function checkToken() {
                const urlParams = new URLSearchParams(window.location.search);
                const token = urlParams.get('verified') || sessionStorage.getItem('auth_token');
                if (!token) return false;
                try {
                    const decoded = atob(token);
                    const [timestamp] = decoded.split('_');
                    const age = Date.now() - parseInt(timestamp);
                    return (!isNaN(age) && age < 600000); 
                } catch(e) { return false; }
            }

            setTimeout(() => {
                if (checkToken()) {
                    const overlay = document.getElementById('verify-overlay');
                    if(overlay) overlay.remove();
                    if (typeof initStation === 'function') initStation();
                } else {
                    document.getElementById('verifyStatus').innerHTML = "❌ 验证失效";
                    document.getElementById('btn-reverify').style.display = "inline-block";
                    setTimeout(() => { window.location.href = 'index.html'; }, 2000);
                }
            }, 800);
        })();
    </script>
    <style>
        :root { --blue: #58a6ff; --bg: #0d1117; --card: #161b22; --border: #30363d; }
        body { background: var(--bg); color: #c9d1d9; font-family: -apple-system, sans-serif; margin: 0; padding: 20px; }
        .container { max-width: 900px; margin: 0 auto; }
        .search-box { width: 100%; padding: 12px; background: var(--card); border: 1px solid var(--border); border-radius: 8px; color: white; margin-bottom: 20px; font-size: 16px; outline: none; }
        .search-box:focus { border-color: var(--blue); }
        .song-card { background: var(--card); border: 1px solid var(--border); border-radius: 12px; margin-bottom: 20px; overflow: hidden; }
        .song-header { background: #21262d; padding: 15px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border); }
        .song-title { color: var(--blue); font-weight: bold; font-size: 1.1em; }
        .song-body { display: flex; padding: 15px; gap: 15px; flex-wrap: wrap; }
        .preview-box { flex: 0 0 200px; }
        .preview-img { width: 100%; height: 120px; object-fit: cover; border-radius: 8px; border: 1px solid var(--border); }
        .file-list { flex: 1; min-width: 250px; }
        
        /* 关键修改：文件项样式 */
        .file-item { 
            display: flex; 
            align-items: center; 
            background: #0d1117; 
            padding: 10px 12px; 
            margin-bottom: 8px; 
            border-radius: 6px; 
            border: 1px solid var(--border); 
            cursor: pointer; 
            font-size: 14px; 
            transition: all 0.2s;
            user-select: none; /* 防止频繁点击导致文字被选中 */
        }
        .file-item:hover { background: #21262d; border-color: var(--blue); }
        .file-item input[type="checkbox"] { 
            margin-right: 12px; 
            width: 16px; 
            height: 16px; 
            cursor: pointer; 
            accent-color: #238636;
        }
        
        .tag { font-size: 11px; padding: 2px 6px; border-radius: 4px; color: white; margin-right: 8px; font-weight: bold; min-width: 40px; text-align: center; }
        .tag-ill { background: #da3633; } .tag-audio { background: #1f6feb; } .tag-chart { background: #238636; }
        .btn-zip { background: #238636; color: white; border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer; font-weight: bold; }
        .btn-zip:hover { background: #2ea043; }
        .btn-zip:disabled { opacity: 0.5; cursor: not-allowed; }
    </style>
</head>
<body>
    <div class="container">
        <h1 style="text-align: center; color: #58a6ff;">🎵 Zephyr的下载站</h1>
        <input type="text" id="search" class="search-box" placeholder="搜索歌曲ID...">
        <div id="list-container"></div>
    </div>
EOF

# 2. 扫描文件逻辑
cd "$BUILD_REPO"
SONG_IDS=$( ( [ -d "chart" ] && find chart -type d -mindepth 1 -maxdepth 1 | sed 's|chart/||' ; \
               [ -d "music" ] && find music -type f \( -name "*.mp3" -o -name "*.ogg" \) | xargs -I {} basename {} | sed 's/\.[^.]*$//' ) | sort -u)

SONG_DATA_FILE=$(mktemp)

for id in $SONG_IDS; do
    id_clean=$(echo "$id" | sed 's/\.[0-9]*$//')
    [ -z "$id_clean" ] && continue

    ILL_PATH=$(find illustration -type f \( -name "${id}.*" -o -name "${id_clean}.*" \) 2>/dev/null | head -1)
    AUDIO_PATH=$(find music -type f \( -name "${id}.*" -o -name "${id_clean}.*" \) 2>/dev/null | head -1)
    CHART_PATHS=$( [ -d "chart/${id}" ] && find "chart/${id}" -type f -name "*.json" 2>/dev/null || echo "" )

    [ $(echo "$ILL_PATH $AUDIO_PATH $CHART_PATHS" | wc -w) -eq 0 ] && continue

    {
        echo "<div class='song-card' data-id='$id_clean'>"
        echo "  <div class='song-header'><span class='song-title'>$id_clean</span><button class='btn-zip' onclick='pack(\"$id_clean\", this)'>📦 打包下载</button></div>"
        echo "  <div class='song-body'>"
        echo "    <div class='preview-box'>"
        if [ -n "$ILL_PATH" ]; then
            echo "      <img class='preview-img' src='${BASE_URL}/${ILL_PATH}' loading='lazy'>"
        else
            echo "      <div style='height:120px;background:#333;border-radius:8px;'></div>"
        fi
        echo "    </div>"
        echo "    <div class='file-list' id='files-$id_clean'>"
        
        [ -n "$ILL_PATH" ] && echo "<label class='file-item'><input type='checkbox' checked data-url='${BASE_URL}/$ILL_PATH' data-name='$(basename "$ILL_PATH")'><span class='tag tag-ill'>曲绘</span>$(basename "$ILL_PATH")</label>"
        [ -n "$AUDIO_PATH" ] && echo "<label class='file-item'><input type='checkbox' checked data-url='${BASE_URL}/$AUDIO_PATH' data-name='$(basename "$AUDIO_PATH")'><span class='tag tag-audio'>音频</span>$(basename "$AUDIO_PATH")</label>"
        
        for cp in $CHART_PATHS; do
            echo "<label class='file-item'><input type='checkbox' checked data-url='${BASE_URL}/$cp' data-name='$(basename "$cp")'><span class='tag tag-chart'>谱面</span>$(basename "$cp")</label>"
        done
        
        echo "    </div>"
        echo "  </div>"
        echo "</div>"
    } >> "$SONG_DATA_FILE"
done
cd - > /dev/null

# 3. 注入脚本
cat >> "$OUTPUT_FILE" <<EOF
    <script>
        function initStation() {
            const container = document.getElementById('list-container');
            container.innerHTML = \`$(cat "$SONG_DATA_FILE" | sed 's/`/\\`/g' | sed 's/\$/\\$/g')\`;

            // 搜索
            document.getElementById('search').addEventListener('input', function(e) {
                const term = e.target.value.toLowerCase();
                document.querySelectorAll('.song-card').forEach(card => {
                    card.style.display = card.dataset.id.toLowerCase().includes(term) ? '' : 'none';
                });
            });

            // 关键逻辑：点击整行触发复选框
            document.addEventListener('click', function(e) {
                const item = e.target.closest('.file-item');
                if (!item) return;
                
                // 如果点击的直接就是复选框，不需要额外逻辑，浏览器会自动处理
                if (e.target.tagName === 'INPUT') return;
                
                // 如果点击的是整行的其他地方，手动切换状态
                const cb = item.querySelector('input[type="checkbox"]');
                if (cb) cb.checked = !cb.checked;
            });
        }

        async function pack(id, btn) {
            const checkboxes = document.querySelectorAll('#files-' + id + ' input:checked');
            if (checkboxes.length === 0) return alert('请选择文件');
            btn.disabled = true; btn.innerHTML = "⏳ 打包中...";
            try {
                const zip = new JSZip();
                for (const cb of checkboxes) {
                    const res = await fetch(cb.dataset.url);
                    zip.file(cb.dataset.name, await res.blob());
                }
                const content = await zip.generateAsync({ type: 'blob' });
                const a = document.createElement('a');
                a.href = URL.createObjectURL(content);
                a.download = id + ".zip";
                a.click();
                btn.innerHTML = "✅ 完成";
            } catch (e) { alert("打包失败"); btn.innerHTML = "❌ 错误"; }
            setTimeout(() => { btn.disabled = false; btn.innerHTML = "📦 打包下载"; }, 2000);
        }
    </script>
</body>
</html>
EOF

rm -f "$SONG_DATA_FILE"
echo "✅ 生成完成！"
