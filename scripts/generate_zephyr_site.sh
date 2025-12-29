#!/bin/bash
# scripts/generate_zephyr_site.sh - 最终修复版
set -e

BASE_URL="https://phigros-res.l1quid.dpdns.org"
BUILD_REPO="$1"
OUTPUT_FILE="$2"

echo "开始生成Zephyr下载站..."
echo "资源目录: $BUILD_REPO"
echo "输出文件: $OUTPUT_FILE"

# 先创建输出文件
touch "$OUTPUT_FILE"

# 生成完整的HTML
{
cat << 'HTML_HEAD'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zephyr的下载站</title>
    <script src="https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js"></script>
    
    <style>
        /* 验证层 */
        #verify-layer {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: #0d1117;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            z-index: 9999;
            color: #c9d1d9;
            text-align: center;
            padding: 40px 20px;
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
        }
        
        #verify-message {
            margin: 20px 0 40px 0;
            font-size: 1.1rem;
        }
        
        .verify-bar {
            width: 300px;
            height: 8px;
            background: #30363d;
            border-radius: 4px;
            overflow: hidden;
            margin-bottom: 30px;
        }
        
        .verify-fill {
            height: 100%;
            background: #238636;
            width: 0%;
            transition: width 0.3s;
        }
        
        /* 内容层 */
        #content-layer {
            display: none;
        }
        
        /* 页面样式 */
        body {
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            background: #0d1117;
            color: #c9d1d9;
            margin: 0;
            padding: 20px;
        }
        
        .container {
            max-width: 1000px;
            margin: 0 auto;
        }
        
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        
        .title {
            color: #58a6ff;
            font-size: 2em;
            margin-bottom: 10px;
        }
        
        .search {
            width: 100%;
            padding: 15px;
            background: #161b22;
            border: 1px solid #30363d;
            color: white;
            border-radius: 8px;
            margin-bottom: 25px;
            font-size: 16px;
        }
        
        /* 歌曲卡片 */
        .song {
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 10px;
            margin-bottom: 20px;
            overflow: hidden;
        }
        
        .song-header {
            background: #21262d;
            padding: 15px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid #30363d;
        }
        
        .song-name {
            color: #58a6ff;
            font-weight: bold;
            font-size: 1.2em;
        }
        
        .song-actions {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .count {
            color: #8b949e;
            font-size: 0.9em;
        }
        
        .btn {
            background: #238636;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 6px;
            cursor: pointer;
            font-weight: bold;
        }
        
        .song-body {
            padding: 20px;
            display: flex;
            gap: 20px;
        }
        
        .preview {
            flex: 0 0 200px;
        }
        
        .preview-img {
            width: 100%;
            height: 140px;
            object-fit: cover;
            border-radius: 8px;
            border: 1px solid #30363d;
        }
        
        .file-section {
            flex: 1;
        }
        
        .select-all {
            color: #58a6ff;
            cursor: pointer;
            margin-bottom: 15px;
            padding: 8px 0;
        }
        
        .file-list {
            max-height: 300px;
            overflow-y: auto;
        }
        
        /* 文件项 */
        .file {
            display: flex;
            align-items: center;
            background: #0d1117;
            padding: 12px;
            margin-bottom: 8px;
            border-radius: 6px;
            border: 1px solid #30363d;
            cursor: pointer;
        }
        
        .checkbox {
            width: 18px;
            height: 18px;
            margin-right: 12px;
            cursor: pointer;
            accent-color: #238636;
        }
        
        .tag {
            font-size: 0.8em;
            padding: 4px 10px;
            border-radius: 4px;
            color: white;
            margin-right: 10px;
            font-weight: bold;
        }
        
        .tag-ill { background: #da3633; }
        .tag-audio { background: #1f6feb; }
        .tag-chart { background: #238636; }
        
        .filename {
            flex: 1;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
    </style>
</head>
<body>
    <!-- 验证层 -->
    <div id="verify-layer">
        <div style="font-size: 3em;">🔒</div>
        <h1 style="color:#58a6ff;">访问验证</h1>
        <p id="verify-message">检查访问权限...</p>
        <div class="verify-bar">
            <div id="verify-fill" class="verify-fill"></div>
        </div>
    </div>
    
    <!-- 内容层 -->
    <div id="content-layer">
        <div class="container">
            <div class="header">
                <h1 class="title">🎵 Zephyr的Phigros资源下载站</h1>
                <p style="color:#8b949e;">使用JSDelivr CDN，支持跨域下载</p>
            </div>
            
            <input type="text" id="search" class="search" placeholder="搜索歌曲ID...">
            
            <div id="songs-container">
HTML_HEAD
} > "$OUTPUT_FILE"

echo "查找歌曲文件..."

# 进入资源目录
cd "$BUILD_REPO"

# 查找所有歌曲ID（从chart目录）
echo "扫描 chart 目录..."
SONG_IDS=$(find chart -type d -mindepth 1 -maxdepth 1 2>/dev/null | sed 's|chart/||' | sort | head -50)

if [ -z "$SONG_IDS" ]; then
    echo "chart目录为空，尝试music目录..."
    SONG_IDS=$(find music -type f \( -name "*.mp3" -o -name "*.ogg" \) 2>/dev/null | xargs -I {} basename {} | sed 's/\.[^.]*$//' | sort -u | head -50)
fi

SONG_COUNT=0

for SONG_ID in $SONG_IDS; do
    SONG_CLEAN=$(echo "$SONG_ID" | sed 's/\.[0-9]*$//')
    [ -z "$SONG_CLEAN" ] && continue
    
    echo "处理歌曲: $SONG_CLEAN"
    
    # 查找文件
    ILL_FILE=""
    AUDIO_FILE=""
    
    # 1. 曲绘
    if [ -d "illustration" ]; then
        ILL_FILE=$(find illustration -maxdepth 1 -type f \( -name "${SONG_ID}.*" -o -name "${SONG_CLEAN}.*" \) 2>/dev/null | head -1)
    fi
    
    # 2. 音频
    if [ -d "music" ]; then
        AUDIO_FILE=$(find music -maxdepth 1 -type f \( -name "${SONG_ID}.*" -o -name "${SONG_CLEAN}.*" \) 2>/dev/null | head -1)
    fi
    
    # 3. 谱面（去重）
    CHART_FILES=""
    if [ -d "chart/$SONG_ID" ]; then
        # 按难度去重
        declare -A CHART_MAP
        find "chart/$SONG_ID" -type f -name "*.json" 2>/dev/null | while read CHART; do
            CHART_NAME=$(basename "$CHART")
            if [[ $CHART_NAME =~ EZ|Ez|ez ]]; then
                [ -z "${CHART_MAP[EZ]}" ] && CHART_MAP[EZ]="$CHART"
            elif [[ $CHART_NAME =~ HD|Hd|hd ]]; then
                [ -z "${CHART_MAP[HD]}" ] && CHART_MAP[HD]="$CHART"
            elif [[ $CHART_NAME =~ IN|In|in ]]; then
                [ -z "${CHART_MAP[IN]}" ] && CHART_MAP[IN]="$CHART"
            elif [[ $CHART_NAME =~ AT|At|at ]]; then
                [ -z "${CHART_MAP[AT]}" ] && CHART_MAP[AT]="$CHART"
            elif [[ $CHART_NAME =~ SP|Sp|sp ]]; then
                [ -z "${CHART_MAP[SP]}" ] && CHART_MAP[SP]="$CHART"
            else
                [ -z "${CHART_MAP[OTHER]}" ] && CHART_MAP[OTHER]="$CHART"
            fi
        done
        
        for KEY in "${!CHART_MAP[@]}"; do
            CHART_FILES="$CHART_FILES${CHART_MAP[$KEY]}"$'\n'
        done
    fi
    
    # 统计文件
    FILE_HTML=""
    FILE_COUNT=0
    
    # 添加曲绘
    if [ ! -z "$ILL_FILE" ] && [ -f "$ILL_FILE" ]; then
        FILE_COUNT=$((FILE_COUNT+1))
        ILL_URL="${BASE_URL}/${ILL_FILE}"
        ILL_NAME=$(basename "$ILL_FILE")
        FILE_HTML="$FILE_HTML<div class='file'><input type='checkbox' class='checkbox' checked data-url='$ILL_URL' data-name='$ILL_NAME'><span class='tag tag-ill'>曲绘</span><span class='filename'>$ILL_NAME</span></div>"
    fi
    
    # 添加音频
    if [ ! -z "$AUDIO_FILE" ] && [ -f "$AUDIO_FILE" ]; then
        FILE_COUNT=$((FILE_COUNT+1))
        AUDIO_URL="${BASE_URL}/${AUDIO_FILE}"
        AUDIO_NAME=$(basename "$AUDIO_FILE")
        FILE_HTML="$FILE_HTML<div class='file'><input type='checkbox' class='checkbox' checked data-url='$AUDIO_URL' data-name='$AUDIO_NAME'><span class='tag tag-audio'>音频</span><span class='filename'>$AUDIO_NAME</span></div>"
    fi
    
    # 添加谱面
    for CHART in $CHART_FILES; do
        [ -z "$CHART" ] && continue
        if [ -f "$CHART" ]; then
            FILE_COUNT=$((FILE_COUNT+1))
            CHART_URL="${BASE_URL}/${CHART}"
            CHART_NAME=$(basename "$CHART")
            FILE_HTML="$FILE_HTML<div class='file'><input type='checkbox' class='checkbox' checked data-url='$CHART_URL' data-name='$CHART_NAME'><span class='tag tag-chart'>谱面</span><span class='filename'>$CHART_NAME</span></div>"
        fi
    done
    
    [ $FILE_COUNT -eq 0 ] && continue
    
    SONG_COUNT=$((SONG_COUNT+1))
    
    # 生成HTML
    {
    cat << HTML_CARD
<div class="song" data-id="$SONG_CLEAN">
    <div class="song-header">
        <div class="song-name">$SONG_CLEAN</div>
        <div class="song-actions">
            <span class="count" id="count-$SONG_CLEAN">0/$FILE_COUNT选中</span>
            <button class="btn" onclick="downloadSong('$SONG_CLEAN')">📦打包</button>
        </div>
    </div>
    <div class="song-body">
        <div class="preview">
HTML_CARD
    
    if [ ! -z "$ILL_FILE" ] && [ -f "$ILL_FILE" ]; then
        echo "<img src='${BASE_URL}/${ILL_FILE}' class='preview-img'>"
    else
        echo "<div style='height:140px;background:#30363d;border-radius:8px;'></div>"
    fi
    
    cat << HTML_CARD
        </div>
        <div class="file-section">
            <div class="select-all" onclick="toggleAll('$SONG_CLEAN')">📋全选/取消</div>
            <div class="file-list" id="list-$SONG_CLEAN">
                $FILE_HTML
            </div>
        </div>
    </div>
</div>
HTML_CARD
    } >> "$OUTPUT_FILE"
done

cd -

if [ $SONG_COUNT -eq 0 ]; then
    echo "<div style='text-align:center;padding:50px;color:#8b949e;'>未找到资源文件</div>" >> "$OUTPUT_FILE"
fi

# 完成HTML
cat >> "$OUTPUT_FILE" << 'HTML_FOOT'
            </div>
        </div>
    </div>
    
    <script>
        // 验证检查
        function checkAuth() {
            const token = sessionStorage.getItem('auth_token');
            if (!token) return false;
            
            try {
                const decoded = atob(token);
                const [timestamp] = decoded.split('_');
                const age = Date.now() - parseInt(timestamp);
                return !isNaN(age) && age < 600000; // 10分钟
            } catch(e) {
                return false;
            }
        }
        
        // 验证动画
        let progress = 0;
        const fill = document.getElementById('verify-fill');
        const msg = document.getElementById('verify-message');
        
        const timer = setInterval(() => {
            progress += 10;
            fill.style.width = progress + '%';
            
            if (progress >= 100) {
                clearInterval(timer);
                
                if (checkAuth()) {
                    msg.textContent = '✅验证通过';
                    fill.style.background = '#58a6ff';
                    
                    setTimeout(() => {
                        document.getElementById('verify-layer').style.display = 'none';
                        document.getElementById('content-layer').style.display = 'block';
                        initPage();
                    }, 500);
                } else {
                    msg.textContent = '❌需要验证';
                    fill.style.background = '#da3633';
                    
                    setTimeout(() => {
                        window.location.href = 'index.html';
                    }, 2000);
                }
            }
        }, 50);
        
        // 页面功能
        function initPage() {
            // 搜索
            const search = document.getElementById('search');
            search.addEventListener('input', function() {
                const term = this.value.toLowerCase();
                document.querySelectorAll('.song').forEach(song => {
                    song.style.display = song.dataset.id.toLowerCase().includes(term) ? '' : 'none';
                });
            });
            
            // 更新计数
            updateAllCounts();
            
            // 点击文件
            document.addEventListener('click', function(e) {
                if (e.target.closest('.file') && !e.target.classList.contains('checkbox')) {
                    const file = e.target.closest('.file');
                    const cb = file.querySelector('.checkbox');
                    cb.checked = !cb.checked;
                    updateCount(cb.closest('.song').dataset.id);
                }
            });
        }
        
        function updateCount(songId) {
            const list = document.getElementById('list-' + songId);
            if (!list) return;
            
            const cbs = list.querySelectorAll('.checkbox');
            const checked = Array.from(cbs).filter(cb => cb.checked).length;
            document.getElementById('count-' + songId).textContent = checked + '/' + cbs.length + '选中';
        }
        
        function updateAllCounts() {
            document.querySelectorAll('.song').forEach(song => {
                updateCount(song.dataset.id);
            });
        }
        
        window.toggleAll = function(songId) {
            const list = document.getElementById('list-' + songId);
            if (!list) return;
            
            const cbs = list.querySelectorAll('.checkbox');
            const allChecked = Array.from(cbs).every(cb => cb.checked);
            cbs.forEach(cb => cb.checked = !allChecked);
            updateCount(songId);
        };
        
        window.downloadSong = async function(songId) {
            const list = document.getElementById('list-' + songId);
            if (!list) return;
            
            const cbs = list.querySelectorAll('.checkbox:checked');
            if (cbs.length === 0) {
                alert('请选择文件');
                return;
            }
            
            const btn = document.querySelector(`button[onclick*="${songId}"]`);
            if (btn) {
                btn.disabled = true;
                btn.textContent = '打包中...';
            }
            
            try {
                const zip = new JSZip();
                for (const cb of cbs) {
                    const res = await fetch(cb.dataset.url);
                    const blob = await res.blob();
                    zip.file(cb.dataset.name, blob);
                }
                
                const content = await zip.generateAsync({ type: 'blob' });
                const link = document.createElement('a');
                link.href = URL.createObjectURL(content);
                link.download = songId + '.zip';
                link.click();
                
                if (btn) {
                    btn.textContent = '✅完成';
                    setTimeout(() => {
                        btn.disabled = false;
                        btn.textContent = '📦打包';
                    }, 2000);
                }
            } catch(e) {
                alert('下载失败: ' + e.message);
                if (btn) {
                    btn.disabled = false;
                    btn.textContent = '📦打包';
                }
            }
        };
    </script>
</body>
</html>
HTML_FOOT

echo "✅ 生成完成！"
echo "🎵 找到 $SONG_COUNT 个歌曲"
echo "🔒 验证系统: 已启用"
echo "📁 输出: $OUTPUT_FILE"
