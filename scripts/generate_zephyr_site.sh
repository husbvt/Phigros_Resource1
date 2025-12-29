#!/bin/bash
# scripts/generate_zephyr_site.sh - 修复空白页面问题
set -e

BASE_URL="https://phigros-res.l1quid.dpdns.org"
BUILD_REPO="$1"
OUTPUT_FILE="$2"

echo "开始生成Zephyr下载站..."

# 生成完整的HTML，不立即清空
cat > "$OUTPUT_FILE" << 'HTML_HEAD'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zephyr的下载站</title>
    <script src="https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js"></script>
    
    <style>
        /* 验证覆盖层样式 - 默认显示 */
        #verify-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
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
        
        #verify-overlay h1 {
            color: #58a6ff;
            margin: 0 0 15px 0;
            font-size: 2rem;
        }
        
        #verify-message {
            margin: 0 0 40px 0;
            font-size: 1.1rem;
            max-width: 500px;
        }
        
        .verify-progress {
            width: 300px;
            height: 8px;
            background: #30363d;
            border-radius: 4px;
            overflow: hidden;
            margin-bottom: 30px;
        }
        
        .verify-progress-bar {
            height: 100%;
            background: #238636;
            width: 0%;
            transition: width 0.3s ease;
        }
        
        /* 下载站内容 - 默认隐藏 */
        #download-content {
            display: none;
        }
        
        /* 页面样式 */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: #0d1117;
            color: #c9d1d9;
            line-height: 1.6;
        }
        
        .page-container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .page-header {
            text-align: center;
            margin-bottom: 40px;
            padding-bottom: 30px;
            border-bottom: 1px solid #30363d;
        }
        
        .page-header h1 {
            color: #58a6ff;
            font-size: 2.5rem;
            margin-bottom: 10px;
        }
        
        .page-subtitle {
            color: #8b949e;
            font-size: 1rem;
        }
        
        .search-container {
            margin-bottom: 30px;
        }
        
        .search-input {
            width: 100%;
            padding: 15px 20px;
            font-size: 1rem;
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 10px;
            color: #c9d1d9;
            transition: all 0.2s;
        }
        
        .search-input:focus {
            outline: none;
            border-color: #58a6ff;
            box-shadow: 0 0 0 2px rgba(88, 166, 255, 0.2);
        }
        
        /* 歌曲卡片样式 */
        .song-card {
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 12px;
            margin-bottom: 25px;
            overflow: hidden;
        }
        
        .song-header {
            background: #21262d;
            padding: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid #30363d;
        }
        
        .song-title {
            color: #58a6ff;
            font-size: 1.3rem;
            font-weight: 600;
        }
        
        .song-controls {
            display: flex;
            align-items: center;
            gap: 20px;
        }
        
        .file-count {
            color: #8b949e;
            font-size: 0.9rem;
            min-width: 100px;
            text-align: right;
        }
        
        .download-btn {
            background: #238636;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
            font-size: 0.95rem;
        }
        
        .song-content {
            display: flex;
            padding: 25px;
            gap: 30px;
        }
        
        .preview-area {
            flex: 0 0 250px;
        }
        
        .preview-img {
            width: 100%;
            height: 180px;
            object-fit: cover;
            border-radius: 8px;
            border: 1px solid #30363d;
        }
        
        .files-area {
            flex: 1;
        }
        
        .select-all {
            color: #58a6ff;
            cursor: pointer;
            margin-bottom: 20px;
            padding: 8px 0;
            display: inline-block;
            font-weight: 500;
        }
        
        .file-list {
            max-height: 350px;
            overflow-y: auto;
            padding-right: 10px;
        }
        
        /* 文件项样式 */
        .file-item {
            display: flex;
            align-items: center;
            background: #0d1117;
            padding: 14px 18px;
            margin-bottom: 10px;
            border-radius: 8px;
            border: 1px solid #30363d;
            cursor: pointer;
        }
        
        .file-checkbox {
            width: 20px;
            height: 20px;
            margin-right: 15px;
            cursor: pointer;
            accent-color: #238636;
        }
        
        .file-tag {
            font-size: 0.8rem;
            padding: 4px 10px;
            border-radius: 4px;
            color: white;
            margin-right: 12px;
            font-weight: 600;
            min-width: 55px;
            text-align: center;
        }
        
        .file-tag-ill { background: #da3633; }
        .file-tag-audio { background: #1f6feb; }
        .file-tag-chart { background: #238636; }
        
        .file-name {
            flex: 1;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        
        /* 响应式 */
        @media (max-width: 768px) {
            .song-content {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <!-- 验证覆盖层 - 默认显示 -->
    <div id="verify-overlay">
        <div style="font-size: 4rem; margin-bottom: 20px;">🔒</div>
        <h1>访问验证</h1>
        <p id="verify-message">正在验证访问权限...</p>
        
        <div class="verify-progress">
            <div id="verify-progress-bar" class="verify-progress-bar"></div>
        </div>
        
        <div id="verify-actions" style="display: none;">
            <button onclick="goToVerifyPage()" style="
                padding: 12px 30px;
                background: #238636;
                color: white;
                border: none;
                border-radius: 8px;
                cursor: pointer;
                font-weight: bold;
                font-size: 1rem;
            ">
                前往验证页面
            </button>
        </div>
    </div>
    
    <!-- 下载站内容 - 默认隐藏，验证后显示 -->
    <div id="download-content">
        <div class="page-container">
            <div class="page-header">
                <h1>🎵 Zephyr的Phigros资源下载站</h1>
                <p class="page-subtitle">使用JSDelivr CDN，支持跨域下载</p>
            </div>
            
            <div class="search-container">
                <input type="text" id="searchInput" class="search-input" placeholder="搜索歌曲ID...">
            </div>
            
            <div id="songsList">
HTML_HEAD

echo "生成歌曲内容..."

cd "$BUILD_REPO"

SONG_COUNT=0
SONG_CARDS=""

# 查找歌曲
if [ -d "chart" ]; then
    find chart -type d -mindepth 1 -maxdepth 1 2>/dev/null | sort | while read song_dir; do
        song_id=$(basename "$song_dir")
        song_id_clean=$(echo "$song_id" | sed 's/\.[0-9]*$//')
        
        [ -z "$song_id_clean" ] && continue
        
        # 查找文件（去重）
        ILL_FILE=$(find illustration -maxdepth 1 -type f \( -name "${song_id}.*" -o -name "${song_id_clean}.*" \) 2>/dev/null | head -1)
        AUDIO_FILE=$(find music -maxdepth 1 -type f \( -name "${song_id}.*" -o -name "${song_id_clean}.*" \) 2>/dev/null | head -1)
        
        # 谱面去重
        declare -A chart_map
        find "chart/$song_id" -type f -name "*.json" 2>/dev/null | while read chart; do
            filename=$(basename "$chart")
            difficulty=""
            [[ $filename =~ EZ ]] && difficulty="EZ"
            [[ $filename =~ HD ]] && difficulty="HD"
            [[ $filename =~ IN ]] && difficulty="IN"
            [[ $filename =~ AT ]] && difficulty="AT"
            [[ $filename =~ SP ]] && difficulty="SP"
            
            [ ! -z "$difficulty" ] && [ -z "${chart_map[$difficulty]}" ] && chart_map[$difficulty]="$chart"
        done
        
        # 统计文件
        FILE_ITEMS=""
        FILE_COUNT=0
        
        if [ ! -z "$ILL_FILE" ]; then
            FILE_COUNT=$((FILE_COUNT+1))
            ILL_URL="${BASE_URL}/${ILL_FILE}"
            ILL_NAME=$(basename "$ILL_FILE")
            FILE_ITEMS+="<div class='file-item'><input type='checkbox' class='file-checkbox' checked data-url='$ILL_URL' data-name='$ILL_NAME'><span class='file-tag file-tag-ill'>曲绘</span><span class='file-name'>$ILL_NAME</span></div>"
        fi
        
        if [ ! -z "$AUDIO_FILE" ]; then
            FILE_COUNT=$((FILE_COUNT+1))
            AUDIO_URL="${BASE_URL}/${AUDIO_FILE}"
            AUDIO_NAME=$(basename "$AUDIO_FILE")
            FILE_ITEMS+="<div class='file-item'><input type='checkbox' class='file-checkbox' checked data-url='$AUDIO_URL' data-name='$AUDIO_NAME'><span class='file-tag file-tag-audio'>音频</span><span class='file-name'>$AUDIO_NAME</span></div>"
        fi
        
        for diff in "${!chart_map[@]}"; do
            chart="${chart_map[$diff]}"
            FILE_COUNT=$((FILE_COUNT+1))
            CHART_URL="${BASE_URL}/${chart}"
            CHART_NAME=$(basename "$chart")
            FILE_ITEMS+="<div class='file-item'><input type='checkbox' class='file-checkbox' checked data-url='$CHART_URL' data-name='$CHART_NAME'><span class='file-tag file-tag-chart'>谱面</span><span class='file-name'>$CHART_NAME</span></div>"
        done
        
        [ $FILE_COUNT -eq 0 ] && continue
        
        SONG_COUNT=$((SONG_COUNT+1))
        
        # 生成卡片
        CARD="<div class='song-card' data-id='$song_id_clean'>"
        CARD+="<div class='song-header'>"
        CARD+="<div class='song-title'>$song_id_clean</div>"
        CARD+="<div class='song-controls'>"
        CARD+="<span class='file-count' id='count-$song_id_clean'>0/$FILE_COUNT选中</span>"
        CARD+="<button class='download-btn' onclick='downloadSong(\"$song_id_clean\")'>📦打包</button>"
        CARD+="</div></div>"
        CARD+="<div class='song-content'>"
        
        if [ ! -z "$ILL_FILE" ]; then
            CARD+="<div class='preview-area'><img src='${BASE_URL}/${ILL_FILE}' class='preview-img'></div>"
        else
            CARD+="<div class='preview-area'><div style='height:180px;background:#30363d;border-radius:8px;'></div></div>"
        fi
        
        CARD+="<div class='files-area'>"
        CARD+="<div class='select-all' onclick='toggleAll(\"$song_id_clean\")'>📋全选/取消</div>"
        CARD+="<div class='file-list' id='list-$song_id_clean'>$FILE_ITEMS</div>"
        CARD+="</div></div></div>"
        
        SONG_CARDS+="$CARD"
    done
fi

cd -

if [ $SONG_COUNT -eq 0 ]; then
    echo "<div style='text-align:center;padding:50px;color:#8b949e;'>无资源文件</div>" >> "$OUTPUT_FILE"
else
    echo "$SONG_CARDS" >> "$OUTPUT_FILE"
fi

# 完成HTML
cat >> "$OUTPUT_FILE" << 'HTML_FOOT'
            </div>
        </div>
    </div>
    
    <script>
        // ===== 验证逻辑 =====
        function checkAuth() {
            console.log('检查验证令牌...');
            const token = sessionStorage.getItem('auth_token');
            
            if (!token) {
                console.log('❌ 无令牌');
                return false;
            }
            
            try {
                const decoded = atob(token);
                const [timestamp] = decoded.split('_');
                const age = Date.now() - parseInt(timestamp);
                
                if (isNaN(age) || age > 10 * 60 * 1000) {
                    console.log('令牌无效或过期');
                    sessionStorage.removeItem('auth_token');
                    return false;
                }
                
                console.log('✅ 令牌有效');
                return true;
                
            } catch(e) {
                console.log('令牌错误:', e);
                return false;
            }
        }
        
        // 验证进度动画
        let progress = 0;
        const progressBar = document.getElementById('verify-progress-bar');
        const message = document.getElementById('verify-message');
        const actions = document.getElementById('verify-actions');
        
        const timer = setInterval(() => {
            progress += 10;
            progressBar.style.width = progress + '%';
            
            if (progress >= 100) {
                clearInterval(timer);
                
                const valid = checkAuth();
                
                if (valid) {
                    message.textContent = '✅ 验证通过';
                    progressBar.style.background = '#58a6ff';
                    
                    setTimeout(() => {
                        // 隐藏验证层，显示内容
                        document.getElementById('verify-overlay').style.display = 'none';
                        document.getElementById('download-content').style.display = 'block';
                        initPage();
                    }, 500);
                    
                } else {
                    message.textContent = '❌ 需要验证';
                    progressBar.style.background = '#da3633';
                    actions.style.display = 'block';
                    
                    setTimeout(() => {
                        window.location.href = 'index.html';
                    }, 3000);
                }
            }
        }, 50);
        
        function goToVerifyPage() {
            window.location.href = 'index.html';
        }
        
        // ===== 页面功能 =====
        function initPage() {
            console.log('初始化页面...');
            
            // 搜索
            const search = document.getElementById('searchInput');
            search && search.addEventListener('input', function() {
                const term = this.value.toLowerCase();
                document.querySelectorAll('.song-card').forEach(card => {
                    card.style.display = card.dataset.id.toLowerCase().includes(term) ? '' : 'none';
                });
            });
            
            // 初始化计数
            updateCounts();
            
            // 点击文件切换
            document.addEventListener('click', function(e) {
                if (e.target.closest('.file-item') && !e.target.classList.contains('file-checkbox')) {
                    const item = e.target.closest('.file-item');
                    const cb = item.querySelector('.file-checkbox');
                    cb.checked = !cb.checked;
                    updateCount(cb.closest('.song-card').dataset.id);
                }
            });
        }
        
        function updateCount(songId) {
            const list = document.getElementById('list-' + songId);
            if (!list) return;
            
            const cbs = list.querySelectorAll('.file-checkbox');
            const checked = Array.from(cbs).filter(cb => cb.checked).length;
            document.getElementById('count-' + songId).textContent = checked + '/' + cbs.length + '选中';
        }
        
        function updateCounts() {
            document.querySelectorAll('.song-card').forEach(card => {
                updateCount(card.dataset.id);
            });
        }
        
        window.toggleAll = function(songId) {
            const list = document.getElementById('list-' + songId);
            if (!list) return;
            
            const cbs = list.querySelectorAll('.file-checkbox');
            const allChecked = Array.from(cbs).every(cb => cb.checked);
            
            cbs.forEach(cb => cb.checked = !allChecked);
            updateCount(songId);
        };
        
        window.downloadSong = async function(songId) {
            const list = document.getElementById('list-' + songId);
            if (!list) return;
            
            const cbs = list.querySelectorAll('.file-checkbox:checked');
            if (cbs.length === 0) {
                alert('请选择文件');
                return;
            }
            
            const btn = document.querySelector(`[onclick*="${songId}"]`);
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
echo "📊 歌曲: $SONG_COUNT"
echo "🔒 验证: 默认显示验证层，验证后显示内容"
echo "📁 输出: $OUTPUT_FILE"
