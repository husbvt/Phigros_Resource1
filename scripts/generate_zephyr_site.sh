#!/bin/bash
# generate_zephyr_site.sh - 生产环境稳健版
set -e

BUILD_REPO="${1:-./build_repo}"
OUTPUT_FILE="${2:-home.html}"
BASE_URL="https://phigros-res.l1quid.dpdns.org"

echo "🚀 正在生成修复后的 Zephyr 下载站..."

# 1. HTML 头部与动画逻辑 (严禁删除)
cat > "$OUTPUT_FILE" <<'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zephyr的下载站</title>
    <script src="https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js"></script>
    <script>
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
                        <button id="re-btn" onclick="window.location.href='index.html'" style="display:none;margin-top:1.5rem;padding:10px 20px;background:#238636;color:white;border:none;border-radius:6px;cursor:pointer;font-weight:bold;">返回验证页</button>
                    </div>
                </div>
            `);
            let p = 0; const iv = setInterval(() => { p += 10; if(p>95)p=95; document.getElementById('p-bar').style.width=p+'%'; }, 100);
            function ck(){ const t=new URLSearchParams(window.location.search).get('verified')||sessionStorage.getItem('auth_token'); if(!t)return false; try{ return (Date.now()-parseInt(atob(t).split('_')[0])<600000); }catch(e){return false;}}
            setTimeout(() => {
                if(ck()){ 
                    clearInterval(iv); document.getElementById('p-bar').style.width='100%';
                    setTimeout(() => { document.getElementById('v-over').style.opacity='0'; setTimeout(()=>document.getElementById('v-over').remove(), 400); if(window.init)init(); }, 400);
                } else { clearInterval(iv); document.getElementById('v-stat').innerText="❌ 验证失效"; document.getElementById('re-btn').style.display="inline-block"; }
            }, 1000);
        })();
    </script>
    <style>
        :root { --blue: #58a6ff; --bg: #0d1117; --card: #161b22; --border: #30363d; --green: #238636; }
        body { background: var(--bg); color: #c9d1d9; font-family: sans-serif; margin: 0; padding: 20px; }
        .container { max-width: 900px; margin: 0 auto; }
        .search { width: 100%; padding: 12px; background: var(--card); border: 1px solid var(--border); border-radius: 8px; color: white; margin-bottom: 20px; outline: none; box-sizing: border-box; }
        .song-card { background: var(--card); border: 1px solid var(--border); border-radius: 12px; margin-bottom: 25px; overflow: hidden; }
        .song-header { background: #21262d; padding: 12px 20px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border); }
        .song-title { color: var(--blue); font-weight: bold; }
        .header-btns { display: flex; gap: 10px; }
        .song-body { display: flex; padding: 15px; gap: 15px; flex-wrap: wrap; }
        .preview-box { flex: 0 0 200px; }
        .preview-img { width: 100%; height: 120px; object-fit: cover; border-radius: 6px; border: 1px solid var(--border); background: #21262d; }
        .file-list { flex: 1; min-width: 250px; }
        .file-item { display: flex; align-items: center; background: #0d1117; padding: 10px; margin-bottom: 6px; border-radius: 6px; border: 1px solid var(--border); cursor: pointer; transition: 0.2s; user-select: none; }
        .file-item:hover { border-color: var(--blue); background: #1c2128; transform: translateX(2px); }
        .file-item input { margin-right: 12px; width: 16px; height: 16px; accent-color: var(--green); }
        .tag { font-size: 11px; padding: 2px 8px; border-radius: 4px; color: white; margin-right: 10px; font-weight: bold; min-width: 40px; text-align: center; }
        .tag-ill { background: #da3633; } .tag-audio { background: #1f6feb; } .tag-chart { background: #238636; }
        .file-name { flex: 1; font-size: 13px; color: #adbac7; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
        .diff { font-size: 10px; padding: 1px 6px; border-radius: 4px; font-weight: bold; margin-left: 8px; color: #fff; }
        .diff-sp { background: #f9c74f; color: #000; }
        .diff-at { background: #6c757d; }
        .diff-in { background: #da3633; }
        .diff-hd { background: #0077b6; }
        .diff-ez { background: #52b788; }
        .btn-pack { background: var(--green); color: white; border: none; padding: 6px 14px; border-radius: 6px; cursor: pointer; font-weight: bold; }
        .btn-sel { background: transparent; color: var(--blue); border: 1px solid var(--blue); padding: 5px 10px; border-radius: 6px; cursor: pointer; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <h1 style="text-align:center; color: var(--blue);">🎵 Zephyr的下载站</h1>
        <input type="text" id="search" class="search" placeholder="🔍 搜索歌曲ID...">
        <div id="list"></div>
    </div>
EOF

# 2. 合并扫描逻辑 (修正了变量引用错误)
cd "$BUILD_REPO"
SONG_IDS=$( ( [ -d "chart" ] && find chart -type d -mindepth 1 -maxdepth 1 | sed 's|chart/||' ; \
               [ -d "music" ] && find music -type f \( -name "*.mp3" -o -name "*.ogg" \) | xargs -I {} basename {} | sed 's/\.[^.]*$//' ) | sort -u)

TMP_DATA=$(mktemp)
for id in $SONG_IDS; do
    id_clean=$(echo "$id" | sed 's/\.[0-9]*$//')
    # 修正变量引用
    ILL=$(find illustration -type f \( -name "${id}.*" -o -name "${id_clean}.*" \) 2>/dev/null | head -1)
    AUD=$(find music -type f \( -name "${id}.*" -o -name "${id_clean}.*" \) 2>/dev/null | head -1)
    CHARTS=$( [ -d "chart/${id}" ] && find "chart/${id}" -type f -name "*.json" 2>/dev/null || echo "" )
    
    [ -z "$ILL$AUD$CHARTS" ] && continue
    {
        echo "<div class='song-card' data-id='$id_clean'>"
        echo "  <div class='song-header'><span class='song-title'>$id_clean</span><div class='header-btns'>"
        echo "    <button class='btn-sel' onclick='toggleAll(this)'>全选/取消</button>"
        echo "    <button class='btn-pack' onclick='pack(this)'>📦 打包</button></div></div>"
        echo "  <div class='song-body'>"
        echo "    <div class='preview-box'><img class='preview-img' src='${BASE_URL}/$ILL' loading='lazy' onerror='this.src=\"https://placehold.co/200x120/161b22/30363d?text=No+Image\"'></div>"
        echo "    <div class='file-list'>"
        [ -n "$ILL" ] && echo "<div class='file-item' data-url='${BASE_URL}/$ILL' data-name='$(basename "$ILL")'><input type='checkbox' checked><span class='tag tag-ill'>曲绘</span><span class='file-name'>$(basename "$ILL")</span></div>"
        [ -n "$AUD" ] && echo "<div class='file-item' data-url='${BASE_URL}/$AUD' data-name='$(basename "$AUD")'><input type='checkbox' checked><span class='tag tag-audio'>音频</span><span class='file
