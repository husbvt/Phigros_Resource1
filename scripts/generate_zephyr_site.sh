# 在脚本的歌曲卡片生成部分添加去重逻辑
echo "生成歌曲卡片（去重处理）..."

cd "$BUILD_REPO"

SONG_COUNT=0
SONG_CARDS=""

# 查找所有歌曲目录
find chart -type d -mindepth 1 -maxdepth 1 2>/dev/null | while read song_dir; do
    song_id=$(basename "$song_dir")
    song_id_clean=$(echo "$song_id" | sed 's/\.[0-9]*$//')
    
    if [ -z "$song_id_clean" ]; then
        continue
    fi
    
    echo "处理歌曲: $song_id_clean"
    
    # === 修复1：去重文件查找 ===
    # 曲绘文件（只取第一个）
    ILL_FILE=$(find illustration -type f -maxdepth 1 \( -name "${song_id}.*" -o -name "${song_id_clean}.*" \) 2>/dev/null | head -1)
    
    # 音频文件（只取第一个）
    AUDIO_FILE=$(find music -type f -maxdepth 1 \( -name "${song_id}.*" -o -name "${song_id_clean}.*" \) 2>/dev/null | head -1)
    
    # 谱面文件（按难度去重）
    CHART_FILES=$(find "chart/$song_id" -type f -name "*.json" 2>/dev/null | grep -E "(EZ|HD|IN|AT|SP)\.json$" | sort -u | head -5)
    
    # 统计实际文件
    FILES_COUNT=0
    FILE_ITEMS=""
    
    # 曲绘
    if [ ! -z "$ILL_FILE" ] && [ -f "$ILL_FILE" ]; then
        FILES_COUNT=$((FILES_COUNT + 1))
        f_url="${BASE_URL}/${ILL_FILE}"
        f_name=$(basename "$ILL_FILE")
        FILE_ITEMS+="<div class='file-item'><input type='checkbox' class='checkbox' checked data-url='$f_url' data-name='$f_name'><span class='tag tag-ill'>曲绘</span><span class='file-name'>$f_name</span></div>"
    fi
    
    # 音频
    if [ ! -z "$AUDIO_FILE" ] && [ -f "$AUDIO_FILE" ]; then
        FILES_COUNT=$((FILES_COUNT + 1))
        f_url="${BASE_URL}/${AUDIO_FILE}"
        f_name=$(basename "$AUDIO_FILE")
        FILE_ITEMS+="<div class='file-item'><input type='checkbox' class='checkbox' checked data-url='$f_url' data-name='$f_name'><span class='tag tag-audio'>音频</span><span class='file-name'>$f_name</span></div>"
    fi
    
    # 谱面（去重后的）
    CHART_COUNT=0
    declare -A seen_charts  # 用于去重
    
    for chart_file in $CHART_FILES; do
        if [ -f "$chart_file" ]; then
            chart_name=$(basename "$chart_file")
            
            # 按难度去重（只保留每个难度一个）
            difficulty=$(echo "$chart_name" | grep -o -E "(EZ|HD|IN|AT|SP)")
            
            if [ ! -z "$difficulty" ] && [ -z "${seen_charts[$difficulty]}" ]; then
                seen_charts[$difficulty]=1
                FILES_COUNT=$((FILES_COUNT + 1))
                CHART_COUNT=$((CHART_COUNT + 1))
                f_url="${BASE_URL}/${chart_file}"
                
                # 难度样式
                diff_class=""
                case "$difficulty" in
                    EZ) diff_class="diff-ez" ;;
                    HD) diff_class="diff-hd" ;;
                    IN) diff_class="diff-in" ;;
                    AT) diff_class="diff-at" ;;
                    SP) diff_class="diff-sp" ;;
                esac
                
                FILE_ITEMS+="<div class='file-item'><input type='checkbox' class='checkbox' checked data-url='$f_url' data-name='$chart_name'><span class='tag tag-chart'>谱面</span><span class='file-name'>$chart_name</span><span class='difficulty $diff_class'>$difficulty</span></div>"
            fi
        fi
    done
    
    if [ $FILES_COUNT -eq 0 ]; then
        continue
    fi
    
    SONG_COUNT=$((SONG_COUNT + 1))
    
    # 生成卡片HTML
    CARD_HTML="<div class='song-card' data-id='$song_id_clean'>"
    CARD_HTML+="<div class='card-header'>"
    CARD_HTML+="<div class='song-title'>$song_id_clean</div>"
    CARD_HTML+="<div class='card-actions'>"
    CARD_HTML+="<span class='file-count' id='count-$song_id_clean'>$FILES_COUNT个文件</span>"
    CARD_HTML+="<button class='btn-download' onclick='downloadSelection(\"$song_id_clean\")'>📦 打包</button>"
    CARD_HTML+="</div></div>"
    
    CARD_HTML+="<div class='card-body'>"
    
    # 预览图
    if [ ! -z "$ILL_FILE" ]; then
        img_url="${BASE_URL}/${ILL_FILE}"
        CARD_HTML+="<div class='preview'><img src='$img_url' loading='lazy' alt='$song_id_clean'></div>"
    else
        CARD_HTML+="<div class='preview'><div class='no-image'>无预览</div></div>"
    fi
    
    # 文件列表
    CARD_HTML+="<div class='file-section'>"
    CARD_HTML+="<div class='select-all' onclick='toggleAll(\"$song_id_clean\")'>📋 全选/取消</div>"
    CARD_HTML+="<div class='file-list' id='list-$song_id_clean'>"
    CARD_HTML+="$FILE_ITEMS"
    CARD_HTML+="</div></div></div></div>"
    
    SONG_CARDS+="$CARD_HTML\n"
    
done

# 如果通过chart没找到，尝试music目录
if [ $SONG_COUNT -eq 0 ]; then
    echo "从music目录查找..."
    find music -type f \( -name "*.mp3" -o -name "*.ogg" \) 2>/dev/null | while read audio_file; do
        song_id=$(basename "$audio_file" | sed 's/\.[^.]*$//')
        song_id_clean=$(echo "$song_id" | sed 's/-[0-9]*$//')
        
        # ... 类似处理逻辑 ...
    done
fi

cd -

# 生成剩余的HTML
cat >> "$OUTPUT_FILE" << 'HTML_MIDDLE'
                </div>
                
                <!-- 真实页面样式 -->
                <style>
                    /* 简洁的复选框样式 */
                    .checkbox {
                        width: 18px;
                        height: 18px;
                        margin-right: 12px;
                        cursor: pointer;
                        accent-color: #238636;
                    }
                    
                    .file-item {
                        display: flex;
                        align-items: center;
                        padding: 10px 15px;
                        margin: 5px 0;
                        background: #161b22;
                        border: 1px solid #30363d;
                        border-radius: 6px;
                        cursor: pointer;
                    }
                    
                    .file-item:hover {
                        background: #21262d;
                    }
                    
                    .tag {
                        padding: 3px 8px;
                        border-radius: 4px;
                        font-size: 0.8em;
                        margin-right: 10px;
                        color: white;
                    }
                    
                    .tag-audio { background: #1f6feb; }
                    .tag-chart { background: #238636; }
                    .tag-ill { background: #da3633; }
                    
                    /* 页面布局 */
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                        background: #0d1117;
                        color: #c9d1d9;
                        padding: 20px;
                    }
                    
                    .page-container {
                        max-width: 900px;
                        margin: 0 auto;
                    }
                    
                    .page-title {
                        color: #58a6ff;
                        text-align: center;
                        margin-bottom: 20px;
                    }
                    
                    .song-card {
                        background: #161b22;
                        border: 1px solid #30363d;
                        border-radius: 10px;
                        margin-bottom: 20px;
                        overflow: hidden;
                    }
                </style>
            `;
        })();
    </script>
    
    <style>
        /* 基础样式 */
        * { box-sizing: border-box; }
        
        body {
            margin: 0;
            padding: 0;
            background: #0d1117;
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
        }
        
        #realContent {
            display: block !important;
        }
        
        .main-container {
            max-width: 1000px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding: 20px 0;
            border-bottom: 1px solid #30363d;
        }
        
        .site-title {
            color: #58a6ff;
            font-size: 2em;
            margin-bottom: 10px;
        }
        
        .site-subtitle {
            color: #8b949e;
            font-size: 0.9em;
        }
        
        .search-box {
            width: 100%;
            padding: 15px;
            background: #161b22;
            border: 1px solid #30363d;
            color: white;
            border-radius: 8px;
            font-size: 16px;
            margin-bottom: 25px;
        }
        
        .songs-container {
            display: grid;
            gap: 20px;
        }
        
        /* 歌曲卡片样式 */
        .song-card {
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 12px;
            overflow: hidden;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        
        .song-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 24px rgba(0,0,0,0.3);
        }
        
        .card-header {
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
        
        .card-actions {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .file-count {
            color: #8b949e;
            font-size: 0.9em;
            min-width: 100px;
            text-align: right;
        }
        
        .btn-download {
            background: #238636;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-weight: bold;
            transition: background 0.2s;
        }
        
        .btn-download:hover {
            background: #2ea043;
        }
        
        .btn-download:disabled {
            background: #30363d;
            cursor: not-allowed;
        }
        
        .card-body {
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
        
        .no-image {
            width: 100%;
            height: 150px;
            background: #30363d;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #8b949e;
        }
        
        .file-section {
            flex: 1;
        }
        
        .select-all {
            color: #58a6ff;
            cursor: pointer;
            padding: 8px 0;
            margin-bottom: 15px;
            display: inline-block;
            font-weight: 500;
        }
        
        .select-all:hover {
            text-decoration: underline;
        }
        
        .file-list {
            max-height: 400px;
            overflow-y: auto;
        }
        
        .file-item {
            display: flex;
            align-items: center;
            padding: 12px 15px;
            margin-bottom: 8px;
            background: #0d1117;
            border: 1px solid #30363d;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.2s;
        }
        
        .file-item:hover {
            background: #21262d;
            border-color: #58a6ff;
        }
        
        .checkbox {
            width: 18px;
            height: 18px;
            margin-right: 12px;
            cursor: pointer;
            accent-color: #238636;
            flex-shrink: 0;
        }
        
        .tag {
            font-size: 0.8em;
            padding: 4px 10px;
            border-radius: 4px;
            color: white;
            margin-right: 12px;
            min-width: 50px;
            text-align: center;
            flex-shrink: 0;
        }
        
        .file-name {
            flex: 1;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            color: #c9d1d9;
        }
        
        .difficulty {
            font-size: 0.7em;
            padding: 2px 6px;
            border-radius: 3px;
            margin-left: 8px;
            font-weight: bold;
        }
        
        .diff-ez { background: #238636; color: white; }
        .diff-hd { background: #da3633; color: white; }
        .diff-in { background: #8957e5; color: white; }
        .diff-at { background: #f0883e; color: white; }
        .diff-sp { background: #9e6a03; color: white; }
        
        .no-results {
            text-align: center;
            color: #8b949e;
            padding: 40px;
            font-style: italic;
        }
        
        @media (max-width: 768px) {
            .card-body {
                flex-direction: column;
                gap: 20px;
            }
            
            .preview {
                flex: none;
                width: 100%;
            }
            
            .preview img,
            .no-image {
                height: 200px;
            }
        }
    </style>
</head>
<body>
    <!-- 真实内容容器 -->
    <div id="realContent" style="display: none;">
        <div class="main-container">
            <div class="header">
                <h1 class="site-title">🎵 Zephyr的Phigros资源下载站</h1>
                <div class="site-subtitle">使用JSDelivr CDN，支持跨域下载</div>
            </div>
            
            <input type="text" class="search-box" id="searchInput" placeholder="搜索歌曲ID...">
            
            <div class="songs-container" id="songsList">
HTML_MIDDLE

# 添加生成的歌曲卡片
if [ $SONG_COUNT -eq 0 ]; then
    echo "<div class='no-results'>未找到资源文件</div>" >> "$OUTPUT_FILE"
else
    echo -e "$SONG_CARDS" >> "$OUTPUT_FILE"
fi

# 添加剩余的HTML和JavaScript
cat >> "$OUTPUT_FILE" << 'HTML_FOOT'
            </div>
        </div>
    </div>
    
    <script>
        // 页面初始化
        window.initPage = function() {
            console.log('初始化页面功能...');
            
            // 搜索功能
            const searchInput = document.getElementById('searchInput');
            if (searchInput) {
                searchInput.addEventListener('input', function() {
                    const term = this.value.toLowerCase().trim();
                    const cards = document.querySelectorAll('.song-card');
                    
                    cards.forEach(card => {
                        const songName = card.getAttribute('data-id').toLowerCase();
                        card.style.display = term === '' || songName.includes(term) ? '' : 'none';
                    });
                });
            }
            
            // 初始化文件计数
            updateAllFileCounts();
            
            // 点击文件项切换复选框
            document.addEventListener('click', function(e) {
                if (e.target.closest('.file-item') && !e.target.classList.contains('checkbox')) {
                    const fileItem = e.target.closest('.file-item');
                    const checkbox = fileItem.querySelector('.checkbox');
                    if (checkbox) {
                        checkbox.checked = !checkbox.checked;
                        updateFileCount(checkbox.closest('.song-card').getAttribute('data-id'));
                    }
                }
            });
            
            console.log('✅ 页面初始化完成');
        };
        
        // 更新单个歌曲的文件计数
        function updateFileCount(songId) {
            const container = document.getElementById('list-' + songId);
            if (!container) return;
            
            const checkboxes = container.querySelectorAll('.checkbox');
            const checkedCount = Array.from(checkboxes).filter(cb => cb.checked).length;
            const totalCount = checkboxes.length;
            
            const countElem = document.getElementById('count-' + songId);
            if (countElem) {
                countElem.textContent = checkedCount + '/' + totalCount + '选中';
            }
        }
        
        // 更新所有计数
        function updateAllFileCounts() {
            document.querySelectorAll('.song-card').forEach(card => {
                updateFileCount(card.getAttribute('data-id'));
            });
        }
        
        // 全选/取消
        window.toggleAll = function(songId) {
            const container = document.getElementById('list-' + songId);
            if (!container) return;
            
            const checkboxes = container.querySelectorAll('.checkbox');
            const allChecked = Array.from(checkboxes).every(cb => cb.checked);
            
            checkboxes.forEach(cb => {
                cb.checked = !allChecked;
            });
            
            updateFileCount(songId);
        };
        
        // 下载功能
        window.downloadSelection = async function(songId) {
            const container = document.getElementById('list-' + songId);
            if (!container) return;
            
            const checkboxes = container.querySelectorAll('.checkbox:checked');
            if (checkboxes.length === 0) {
                alert('请至少选择一个文件');
                return;
            }
            
            const button = document.querySelector(`.song-card[data-id="${songId}"] .btn-download`);
            if (button) {
                button.disabled = true;
                button.textContent = '打包中...';
            }
            
            try {
                const zip = new JSZip();
                const files = Array.from(checkboxes).map(cb => ({
                    url: cb.dataset.url,
                    name: cb.dataset.name
                }));
                
                for (const file of files) {
                    const response = await fetch(file.url);
                    if (response.ok) {
                        const blob = await response.blob();
                        zip.file(file.name, blob);
                    }
                }
                
                const content = await zip.generateAsync({ type: 'blob' });
                const link = document.createElement('a');
                link.href = URL.createObjectURL(content);
                link.download = songId + '_' + Date.now() + '.zip';
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
                
                if (button) {
                    button.textContent = '✅ 完成';
                    setTimeout(() => {
                        button.disabled = false;
                        button.textContent = '📦 打包';
                    }, 2000);
                }
            } catch (error) {
                alert('下载失败: ' + error.message);
                if (button) {
                    button.disabled = false;
                    button.textContent = '📦 打包';
                }
            }
        };
        
        // 自动初始化
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', window.initPage);
        } else {
            window.initPage();
        }
    </script>
</body>
</html>
HTML_FOOT

echo "✅ 生成完成！"
echo "📊 歌曲数量: $SONG_COUNT"
echo "🔒 验证: 强制重定向已启用"
echo "✓ 重复文件: 已去重处理"
echo "📁 输出: $OUTPUT_FILE"
