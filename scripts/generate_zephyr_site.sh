#!/bin/bash
# scripts/generate_zephyr_site.sh - 修复复选框显示
set -e

BASE_URL="https://phigros-res.l1quid.dpdns.org"
BUILD_REPO="$1"
OUTPUT_FILE="$2"

echo "开始生成Zephyr下载站..."

cat > "$OUTPUT_FILE" << 'HTML_HEAD'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zephyr的下载站</title>
    <script src="https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js"></script>
    
    <script>
        (function() {
            console.log('🔐 验证检查...');
            
            const originalBody = document.body.innerHTML;
            
            document.body.innerHTML = `
                <div style="
                    position: fixed; top: 0; left: 0; right: 0; bottom: 0;
                    background: linear-gradient(135deg, #0d1117 0%, #161b22 100%);
                    display: flex; justify-content: center; align-items: center;
                    z-index: 9999;
                ">
                    <div style="
                        background: #161b22; border: 1px solid #30363d;
                        padding: 2rem; border-radius: 12px; max-width: 500px;
                        width: 90%; text-align: center; color: #c9d1d9;
                    ">
                        <h2 style="color: #58a6ff;">🔒 访问验证</h2>
                        <p id="verifyStatus">检查令牌...</p>
                        <button onclick="window.location.href='index.html'" style="
                            margin-top: 1rem; padding: 10px 20px;
                            background: #238636; color: white; border: none;
                            border-radius: 6px; cursor: pointer; font-weight: bold;
                        ">
                            前往验证
                        </button>
                    </div>
                </div>
            `;
            
            function verifyAccess() {
                const sessionToken = sessionStorage.getItem('auth_token');
                
                if (sessionToken) {
                    try {
                        const decoded = atob(sessionToken);
                        const [timestampStr] = decoded.split('_');
                        const timestamp = parseInt(timestampStr);
                        
                        if (!isNaN(timestamp) && Date.now() - timestamp < 30 * 60 * 1000) {
                            console.log('✅ 令牌有效');
                            return true;
                        }
                    } catch (e) {}
                }
                
                const lastVerified = localStorage.getItem('last_verified');
                if (lastVerified && Date.now() - parseInt(lastVerified) < 5 * 60 * 1000) {
                    console.log('⏱️ 快速验证');
                    return true;
                }
                
                return false;
            }
            
            setTimeout(() => {
                const isValid = verifyAccess();
                const statusText = document.getElementById('verifyStatus');
                
                if (isValid) {
                    statusText.textContent = '✅ 验证通过';
                    setTimeout(() => {
                        document.body.innerHTML = originalBody;
                        window.initDownloadStation();
                    }, 300);
                } else {
                    statusText.textContent = '❌ 需要验证';
                    setTimeout(() => {
                        window.location.href = 'index.html';
                    }, 1000);
                }
            }, 500);
        })();
    </script>
    
    <style>
        /* === 关键修复：复选框强制显示 === */
        .checkbox {
            display: inline-block !important;
            width: 18px !important;
            height: 18px !important;
            margin: 0 12px 0 0 !important;
            cursor: pointer !important;
            opacity: 1 !important;
            visibility: visible !important;
            position: relative;
            z-index: 2;
            flex-shrink: 0;
        }
        
        /* 文件项容器 */
        .file-item {
            display: flex !important;
            align-items: center !important;
            background: #0d1117 !important;
            padding: 12px 15px !important;
            margin-bottom: 8px !important;
            border-radius: 8px !important;
            border: 1px solid #30363d !important;
            cursor: pointer !important;
            transition: all 0.2s !important;
            min-height: 44px;
            box-sizing: border-box;
        }
        
        .file-item:hover {
            background: #21262d !important;
            border-color: #58a6ff !important;
        }
        
        /* 确保标签可见 */
        .tag {
            display: inline-block !important;
            font-size: 0.75em !important;
            padding: 4px 10px !important;
            border-radius: 4px !important;
            color: white !important;
            margin-right: 12px !important;
            min-width: 50px !important;
            text-align: center !important;
            flex-shrink: 0;
        }
        
        .tag-audio { background: #1f6feb !important; }
        .tag-chart { background: #238636 !important; }
        .tag-ill { background: #da3633 !important; }
        
        .file-name {
            flex: 1;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            color: #c9d1d9;
        }
        
        /* 基础布局 */
        body {
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            background: #0d1117;
            color: #c9d1d9;
            margin: 0;
            padding: 20px;
        }
        
        .container {
            max-width: 900px;
            margin: 0 auto;
        }
        
        h1 {
            color: #58a6ff;
            text-align: center;
            margin-bottom: 20px;
        }
        
        .search-box {
            width: 100%;
            padding: 14px;
            background: #161b22;
            border: 1px solid #30363d;
            color: white;
            border-radius: 8px;
            margin-bottom: 25px;
            font-size: 16px;
            box-sizing: border-box;
        }
        
        .song-card {
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 12px;
            margin-bottom: 25px;
            overflow: hidden;
        }
        
        .song-header {
            background: #21262d;
            padding: 18px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid #30363d;
        }
        
        .song-title {
            color: #58a6ff;
            font-weight: bold;
            font-size: 1.2em;
        }
        
        .song-actions {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .file-count {
            color: #8b949e;
            font-size: 0.9em;
            min-width: 80px;
            text-align: right;
        }
        
        .btn-download {
            background: #238636;
            color: white;
            border: none;
            padding: 10px 18px;
            border-radius: 6px;
            cursor: pointer;
            font-weight: bold;
            font-size: 0.95em;
        }
        
        .song-content {
            padding: 20px;
            display: flex;
            gap: 25px;
        }
        
        .preview {
            flex: 0 0 220px;
        }
        
        .preview img {
            width: 100%;
            height: 150px;
            object-fit: cover;
            border-radius: 8px;
            border: 1px solid #30363d;
        }
        
        .file-list {
            flex: 1;
        }
        
        .select-all {
            color: #58a6ff;
            cursor: pointer;
            margin-bottom: 15px;
            padding: 8px 0;
            display: inline-block;
            font-weight: 500;
        }
        
        .select-all:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎵 Zephyr的Phigros资源下载站</h1>
        <div style="text-align: center; margin-bottom: 25px; color: #8b949e;">
            使用JSDelivr CDN，支持跨域下载
        </div>
        <input type="text" id="search" class="search-box" placeholder="搜索歌曲ID...">
        <div id="list">
HTML_HEAD

echo "生成歌曲卡片..."

cd "$BUILD_REPO"

SONG_IDS=$(find . -type d -path "*/chart/*" -mindepth 1 -maxdepth 1 2>/dev/null | sed 's|.*/chart/||' | sort -u)

if [ -z "$SONG_IDS" ]; then
    SONG_IDS=$(find . -type f -path "*/music/*" \( -name "*.mp3" -o -name "*.ogg" \) 2>/dev/null | \
               xargs -I {} basename {} | sed 's/\.[^.]*$//' | sort -u)
fi

SONG_COUNT=0
SONG_CARDS=""

for id in $SONG_IDS; do
    id_clean=$(echo "$id" | sed 's/\.[0-9]*$//')
    [ -z "$id_clean" ] && continue
    
    ILL_FILES=$(find . -type f -path "*/illustration/*" \( -name "${id}.*" -o -name "${id_clean}.*" \) 2>/dev/null | head -5)
    AUDIO_FILES=$(find . -type f -path "*/music/*" \( -name "${id}.*" -o -name "${id_clean}.*" \) 2>/dev/null | head -5)
    CHART_FILES=$(find . -type f -path "*/chart/*" -name "*.json" 2>/dev/null | head -10)
    
    ILL_COUNT=$(echo "$ILL_FILES" | grep -c . || true)
    AUDIO_COUNT=$(echo "$AUDIO_FILES" | grep -c . || true)
    CHART_COUNT=$(echo "$CHART_FILES" | grep -c . || true)
    TOTAL=$((ILL_COUNT + AUDIO_COUNT + CHART_COUNT))
    
    if [ $TOTAL -eq 0 ]; then
        continue
    fi
    
    SONG_COUNT=$((SONG_COUNT + 1))
    
    CARD_HTML="<div class='song-card' data-name='$id_clean'>"
    CARD_HTML+="<div class='song-header'>"
    CARD_HTML+="<div class='song-title'>$id_clean</div>"
    CARD_HTML+="<div class='song-actions'>"
    CARD_HTML+="<span id='st-$id_clean' class='file-count'>0/$TOTAL选中</span>"
    CARD_HTML+="<button class='btn-download' onclick='downloadFiles(\"$id_clean\")'>📦 打包下载</button>"
    CARD_HTML+="</div></div>"
    CARD_HTML+="<div class='song-content'>"
    
    # 预览
    CARD_HTML+="<div class='preview'>"
    ILL_PREVIEW=$(echo "$ILL_FILES" | head -n1)
    if [ ! -z "$ILL_PREVIEW" ]; then
        ILL_URL="${BASE_URL}/${ILL_PREVIEW#./}"
        CARD_HTML+="<img src='$ILL_URL' loading='lazy' alt='$id_clean'>"
    else
        CARD_HTML+="<div style='width:100%;height:150px;background:#30363d;border-radius:8px;'></div>"
    fi
    CARD_HTML+="</div>"
    
    # 文件列表 - 关键：正确生成复选框
    CARD_HTML+="<div class='file-list'>"
    CARD_HTML+="<div class='select-all' onclick='toggleAll(\"$id_clean\")'>📋 全选/取消全选</div>"
    CARD_HTML+="<div id='files-$id_clean'>"
    
    # 曲绘文件
    if [ $ILL_COUNT -gt 0 ]; then
        for f in $ILL_FILES; do
            f_clean=${f#./}
            f_name=$(basename "$f")
            f_url="${BASE_URL}/${f_clean}"
            CARD_HTML+="<div class='file-item' onclick='toggleCheckbox(this)'>"
            CARD_HTML+="<input type='checkbox' class='checkbox' data-url='$f_url' data-name='$f_name' checked>"
            CARD_HTML+="<span class='tag tag-ill'>曲绘</span>"
            CARD_HTML+="<span class='file-name'>$f_name</span>"
            CARD_HTML+="</div>"
        done
    fi
    
    # 音频文件
    if [ $AUDIO_COUNT -gt 0 ]; then
        for f in $AUDIO_FILES; do
            f_clean=${f#./}
            f_name=$(basename "$f")
            f_url="${BASE_URL}/${f_clean}"
            CARD_HTML+="<div class='file-item' onclick='toggleCheckbox(this)'>"
            CARD_HTML+="<input type='checkbox' class='checkbox' data-url='$f_url' data-name='$f_name' checked>"
            CARD_HTML+="<span class='tag tag-audio'>音频</span>"
            CARD_HTML+="<span class='file-name'>$f_name</span>"
            CARD_HTML+="</div>"
        done
    fi
    
    # 谱面文件
    if [ $CHART_COUNT -gt 0 ]; then
        for f in $CHART_FILES; do
            f_clean=${f#./}
            f_name=$(basename "$f")
            f_url="${BASE_URL}/${f_clean}"
            CARD_HTML+="<div class='file-item' onclick='toggleCheckbox(this)'>"
            CARD_HTML+="<input type='checkbox' class='checkbox' data-url='$f_url' data-name='$f_name' checked>"
            CARD_HTML+="<span class='tag tag-chart'>谱面</span>"
            CARD_HTML+="<span class='file-name'>$f_name</span>"
            CARD_HTML+="</div>"
        done
    fi
    
    CARD_HTML+="</div></div></div></div>"
    SONG_CARDS+="$CARD_HTML\n"
done

cd -

if [ $SONG_COUNT -eq 0 ]; then
    echo "<div style='text-align:center;color:#8b949e;padding:50px;'>未找到资源文件</div>" >> "$OUTPUT_FILE"
else
    echo -e "$SONG_CARDS" >> "$OUTPUT_FILE"
fi

echo "</div></div>" >> "$OUTPUT_FILE"

cat >> "$OUTPUT_FILE" << 'JS_CONTENT'
</div>

<script>
    window.initDownloadStation = function() {
        console.log('初始化下载站...');
        
        // 搜索
        const searchInput = document.getElementById('search');
        if (searchInput) {
            searchInput.addEventListener('input', function() {
                const term = this.value.toLowerCase();
                document.querySelectorAll('.song-card').forEach(card => {
                    card.style.display = card.dataset.name.toLowerCase().includes(term) ? '' : 'none';
                });
            });
        }
        
        // 初始化计数
        updateAllCounts();
        
        console.log('✅ 下载站就绪');
    };
    
    function toggleCheckbox(element) {
        const checkbox = element.querySelector('.checkbox');
        if (checkbox) {
            checkbox.checked = !checkbox.checked;
            updateCount(checkbox.closest('.song-card').dataset.name);
        }
    }
    
    function updateCount(songId) {
        const container = document.getElementById('files-' + songId);
        if (!container) return;
        
        const checkboxes = container.querySelectorAll('.checkbox');
        const checked = Array.from(checkboxes).filter(cb => cb.checked).length;
        const total = checkboxes.length;
        
        const statusElem = document.getElementById('st-' + songId);
        if (statusElem) {
            statusElem.textContent = checked + '/' + total + '选中';
        }
    }
    
    function updateAllCounts() {
        document.querySelectorAll('.song-card').forEach(card => {
            updateCount(card.dataset.name);
        });
    }
    
    window.toggleAll = function(songId) {
        const container = document.getElementById('files-' + songId);
        if (!container) return;
        
        const checkboxes = container.querySelectorAll('.checkbox');
        const allChecked = Array.from(checkboxes).every(cb => cb.checked);
        
        checkboxes.forEach(cb => {
            cb.checked = !allChecked;
        });
        
        updateCount(songId);
    };
    
    window.downloadFiles = async function(songId) {
        const container = document.getElementById('files-' + songId);
        if (!container) return;
        
        const checkboxes = container.querySelectorAll('.checkbox:checked');
        if (checkboxes.length === 0) {
            alert('请选择文件');
            return;
        }
        
        const button = document.querySelector(`.song-card[data-name="${songId}"] .btn-download`);
        if (button) {
            button.disabled = true;
            button.textContent = '打包中...';
        }
        
        try {
            const zip = new JSZip();
            
            for (const cb of checkboxes) {
                const response = await fetch(cb.dataset.url);
                if (response.ok) {
                    const blob = await response.blob();
                    zip.file(cb.dataset.name, blob);
                }
            }
            
            const content = await zip.generateAsync({ type: 'blob' });
            const link = document.createElement('a');
            link.href = URL.createObjectURL(content);
            link.download = songId + '.zip';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            
            if (button) {
                button.textContent = '✅ 完成';
                setTimeout(() => {
                    button.disabled = false;
                    button.textContent = '📦 打包下载';
                }, 2000);
            }
        } catch (error) {
            alert('下载失败: ' + error.message);
            if (button) {
                button.disabled = false;
                button.textContent = '📦 打包下载';
            }
        }
    };
    
    // 页面加载
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', window.initDownloadStation);
    } else {
        window.initDownloadStation();
    }
</script>
</body>
</html>
JS_CONTENT

echo "✅ 生成完成！"
echo "📊 歌曲: $SONG_COUNT"
echo "✓ 复选框: 已修复显示"
echo "📁 输出: $OUTPUT_FILE"
