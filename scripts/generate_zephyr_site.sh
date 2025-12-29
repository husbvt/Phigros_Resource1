#!/bin/bash
# scripts/generate_zephyr_site.sh - 修复版，匹配index.html验证
set -e

BASE_URL="https://phigros-res.l1quid.dpdns.org"
BUILD_REPO="$1"
OUTPUT_FILE="$2"

echo "开始生成Zephyr下载站..."

# 创建基础HTML - 关键：匹配你的index.html验证逻辑
cat > "$OUTPUT_FILE" << 'HTML_HEAD'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zephyr的下载站</title>
    <script src="https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js"></script>
    
    <!-- 验证脚本 - 完全匹配你的index.html格式 -->
    <script>
        // ===== 验证系统 - 匹配index.html =====
        (function() {
            console.log('🔐 Zephyr下载站 - 访问控制启动');
            
            // 保存原始body内容
            const originalBody = document.body.innerHTML;
            
            // 显示验证界面
            document.body.innerHTML = `
                <div id="verify-overlay" style="
                    position: fixed;
                    top: 0; left: 0; right: 0; bottom: 0;
                    background: linear-gradient(135deg, #0d1117 0%, #161b22 100%);
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    z-index: 9999;
                ">
                    <div style="
                        background: #161b22;
                        border: 1px solid #30363d;
                        padding: 2rem;
                        border-radius: 12px;
                        max-width: 500px;
                        width: 90%;
                        text-align: center;
                        color: #c9d1d9;
                    ">
                        <h2 style="color: #58a6ff; margin-bottom: 1rem;">🔒 访问验证中</h2>
                        <div style="margin: 2rem 0;">
                            <div style="width: 100%; height: 6px; background: #30363d; border-radius: 3px; overflow: hidden;">
                                <div id="verifyProgress" style="height: 100%; background: #238636; width: 0%; transition: width 0.5s ease;"></div>
                            </div>
                        </div>
                        <p id="verifyStatus">正在检查验证令牌...</p>
                        <p style="color: #8b949e; font-size: 0.9em; margin-top: 1.5rem;">
                            如果长时间停留在此页面，请访问验证页面
                        </p>
                        <button onclick="window.location.href='index.html'" style="
                            margin-top: 1rem;
                            padding: 10px 20px;
                            background: #238636;
                            color: white;
                            border: none;
                            border-radius: 6px;
                            cursor: pointer;
                            font-weight: bold;
                        ">
                            前往验证页面
                        </button>
                    </div>
                </div>
            `;
            
            // 进度条动画
            let progress = 0;
            const progressBar = document.getElementById('verifyProgress');
            const statusText = document.getElementById('verifyStatus');
            const progressInterval = setInterval(() => {
                progress += 5;
                if (progressBar) progressBar.style.width = progress + '%';
                if (progress >= 100) clearInterval(progressInterval);
            }, 100);
            
            // === 核心验证函数 - 匹配你的index.html格式 ===
            function verifyAccess() {
                console.log('🔍 开始核心验证...');
                
                // 1. 检查sessionStorage中的令牌（你的index.html存到这里）
                const sessionToken = sessionStorage.getItem('auth_token');
                
                if (sessionToken) {
                    console.log('🔍 检查sessionStorage令牌');
                    try {
                        // 你的index.html格式：btoa(时间戳_随机字符串)
                        const decoded = atob(sessionToken);
                        console.log('令牌解码内容:', decoded);
                        
                        const [timestampStr] = decoded.split('_');
                        const timestamp = parseInt(timestampStr);
                        
                        if (!isNaN(timestamp)) {
                            const now = Date.now();
                            const tokenAge = now - timestamp;
                            
                            // 10分钟有效期（与index.html提示一致）
                            if (tokenAge < 10 * 60 * 1000) {
                                console.log('✅ sessionStorage令牌有效，年龄:', Math.round(tokenAge/1000), '秒');
                                // 更新验证时间
                                sessionStorage.setItem('auth_time', now.toString());
                                return true;
                            } else {
                                console.warn('❌ sessionStorage令牌已过期:', Math.round(tokenAge/1000), '秒');
                                sessionStorage.removeItem('auth_token');
                            }
                        }
                    } catch (e) {
                        console.error('sessionStorage令牌解码失败:', e);
                        sessionStorage.removeItem('auth_token');
                    }
                }
                
                // 2. 检查URL参数（备用）
                const urlParams = new URLSearchParams(window.location.search);
                const urlToken = urlParams.get('verified');
                
                if (urlToken) {
                    console.log('🔍 检查URL令牌');
                    try {
                        const decoded = atob(urlToken);
                        const [timestampStr] = decoded.split('_');
                        const timestamp = parseInt(timestampStr);
                        
                        if (!isNaN(timestamp)) {
                            const now = Date.now();
                            const tokenAge = now - timestamp;
                            
                            if (tokenAge < 10 * 60 * 1000) {
                                console.log('✅ URL令牌有效');
                                // 保存到sessionStorage以便后续使用
                                sessionStorage.setItem('auth_token', urlToken);
                                sessionStorage.setItem('auth_time', now.toString());
                                return true;
                            }
                        }
                    } catch (e) {
                        console.error('URL令牌解码失败:', e);
                    }
                }
                
                // 3. 检查localStorage的最近验证记录（你的index.html的快速访问功能）
                const lastVerified = localStorage.getItem('last_verified');
                if (lastVerified) {
                    const lastTime = parseInt(lastVerified);
                    const now = Date.now();
                    if (now - lastTime < 5 * 60 * 1000) { // 5分钟内快速验证
                        console.log('⏱️ 检测到最近已验证，生成新令牌');
                        // 生成新令牌
                        const newToken = btoa(now.toString() + '_' + Math.random().toString(36).substr(2));
                        sessionStorage.setItem('auth_token', newToken);
                        sessionStorage.setItem('auth_time', now.toString());
                        return true;
                    }
                }
                
                // 所有验证都失败
                console.log('❌ 访问验证失败，重定向到验证页');
                return false;
            }
            
            // 执行验证
            setTimeout(() => {
                const isValid = verifyAccess();
                
                if (isValid) {
                    console.log('🎉 验证通过，加载下载站');
                    if (statusText) statusText.textContent = '✅ 验证通过，正在加载...';
                    if (progressBar) progressBar.style.backgroundColor = '#58a6ff';
                    
                    clearInterval(progressInterval);
                    
                    setTimeout(() => {
                        document.body.innerHTML = originalBody;
                        if (typeof window.initDownloadStation === 'function') {
                            window.initDownloadStation();
                        }
                        // 强制显示所有复选框
                        document.querySelectorAll('.checkbox').forEach(cb => {
                            cb.style.display = 'block';
                            cb.style.visibility = 'visible';
                            cb.style.opacity = '1';
                        });
                    }, 500);
                } else {
                    console.log('🚫 验证失败，重定向');
                    if (statusText) statusText.textContent = '❌ 验证失败，正在跳转...';
                    if (progressBar) progressBar.style.backgroundColor = '#da3633';
                    
                    setTimeout(() => {
                        window.location.href = 'index.html?from=' + encodeURIComponent(window.location.href);
                    }, 1500);
                }
            }, 1000);
        })();
        // ===== 验证结束 =====
    </script>
    
    <style>
        /* === 强制显示复选框 === */
        .checkbox { 
            margin-right: 12px; 
            width: 16px; 
            height: 16px; 
            cursor: pointer; 
            flex-shrink: 0;
            display: block !important;
            visibility: visible !important;
            opacity: 1 !important;
            appearance: checkbox !important;
            -webkit-appearance: checkbox !important;
            -moz-appearance: checkbox !important;
        }
        
        /* 文件项样式 */
        .file-item {
            display: flex;
            align-items: center;
            background: #0d1117;
            padding: 10px 12px;
            margin-bottom: 8px;
            border-radius: 6px;
            border: 1px solid #30363d;
            font-size: 14px;
            cursor: pointer;
            transition: background 0.2s;
            user-select: none;
        }
        
        .file-item:hover {
            background: #21262d;
            border-color: #58a6ff;
        }
        
        /* 标签样式 */
        .tag {
            font-size: 0.75em;
            padding: 3px 8px;
            border-radius: 4px;
            color: #fff;
            margin-right: 10px;
            font-weight: bold;
            min-width: 50px;
            text-align: center;
            flex-shrink: 0;
        }
        
        .tag-audio { background: #1f6feb; }
        .tag-chart { background: #238636; }
        .tag-ill { background: #da3633; }
        
        /* 基础样式 */
        :root { --blue: #58a6ff; --bg: #0d1117; --card: #161b22; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background: var(--bg);
            color: #c9d1d9;
            margin: 0;
            padding: 15px;
        }
        
        .container {
            max-width: 900px;
            margin: auto;
        }
        
        h1 {
            color: var(--blue);
            text-align: center;
            margin-bottom: 30px;
            padding-top: 20px;
        }
        
        .search-box {
            width: 100%;
            padding: 12px;
            background: var(--card);
            border: 1px solid #30363d;
            color: #fff;
            border-radius: 8px;
            margin-bottom: 20px;
            box-sizing: border-box;
            font-size: 16px;
        }
        
        .search-box:focus {
            outline: none;
            border-color: #58a6ff;
        }
        
        .song-card {
            background: var(--card);
            border: 1px solid #30363d;
            border-radius: 12px;
            margin-bottom: 25px;
            overflow: hidden;
        }
        
        .song-header {
            background: #21262d;
            padding: 15px;
            border-bottom: 1px solid #30363d;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .song-header span {
            font-size: 1.2em;
            font-weight: bold;
            color: #58a6ff;
        }
        
        .song-content {
            display: flex;
            flex-direction: column;
            padding: 15px;
            gap: 20px;
        }
        
        @media (min-width: 600px) {
            .song-content {
                flex-direction: row;
            }
        }
        
        .preview-area {
            flex: 0 0 250px;
        }
        
        .preview-img {
            width: 100%;
            height: 140px;
            object-fit: cover;
            border-radius: 8px;
            border: 1px solid #30363d;
        }
        
        .resource-list {
            flex: 1;
        }
        
        .btn-zip {
            background: #238636;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 6px;
            cursor: pointer;
            font-weight: bold;
        }
        
        .btn-zip:hover {
            background: #2ea043;
        }
        
        .status {
            font-size: 0.85em;
            color: #8b949e;
            margin-right: 10px;
        }
        
        .select-all {
            margin: 10px 0 15px 0;
            font-size: 0.9em;
            color: #58a6ff;
            cursor: pointer;
        }
        
        .file-name {
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            flex: 1;
        }
        
        .difficulty {
            font-size: 0.7em;
            padding: 1px 4px;
            border-radius: 3px;
            background: #30363d;
            color: #8b949e;
            margin-left: 5px;
        }
        
        .difficulty-ez { background: #238636; color: #fff; }
        .difficulty-hd { background: #da3633; color: #fff; }
        .difficulty-in { background: #8957e5; color: #fff; }
        
        .progress-bar {
            width: 100%;
            height: 4px;
            background: #30363d;
            border-radius: 2px;
            margin-top: 5px;
            display: none;
        }
        
        .progress-fill {
            height: 100%;
            background: #238636;
            width: 0%;
        }
    </style>
</head>
<body>
    <!-- 下载站内容 -->
    <div class="container">
        <h1>🎵 Zephyr的Phigros资源下载站</h1>
        <div style="text-align: center; margin-bottom: 20px; color: #8b949e; font-size: 0.9em;">
            使用JSDelivr CDN，支持跨域下载
        </div>
        <input type="text" id="search" class="search-box" placeholder="搜索歌曲ID (例如: 青芽) 或直接输入ID...">
        <div id="list">
HTML_HEAD

echo "基础HTML生成完成，开始生成歌曲卡片..."

cd "$BUILD_REPO"

# 获取歌曲ID
SONG_IDS=""
if [ -d "chart" ]; then
    SONG_IDS=$(find chart -type d -mindepth 1 -maxdepth 1 | sed 's|chart/||' | sort)
fi

if [ -z "$SONG_IDS" ] && [ -d "music" ]; then
    SONG_IDS=$(find music -type f \( -name "*.mp3" -o -name "*.ogg" \) 2>/dev/null | \
              xargs -I {} basename {} .mp3 | \
              xargs -I {} basename {} .ogg | \
              sort -u)
fi

SONG_COUNT=0
SONG_CARDS=""

if [ -z "$SONG_IDS" ]; then
    SONG_CARDS="<div style='text-align:center;color:#8b949e;padding:40px;'>未找到任何资源</div>"
else
    for id in $SONG_IDS; do
        id_clean=$(echo "$id" | sed 's/\.[0-9]*$//')
        [ -z "$id_clean" ] && continue
        
        # 查找文件
        ILL_FILES=$(find . -type f \( -name "${id}.*" -o -name "${id_clean}.*" \) -path "*/illustration/*" 2>/dev/null | head -3)
        AUDIO_FILES=$(find . -type f \( -name "${id}.*" -o -name "${id_clean}.*" \) -path "*/music/*" 2>/dev/null | head -3)
        CHART_FILES=$(find . -type f -name "*.json" -path "*/chart/*" 2>/dev/null | head -5)
        
        ILL_COUNT=$(echo "$ILL_FILES" | grep -v "^$" | wc -l)
        AUDIO_COUNT=$(echo "$AUDIO_FILES" | grep -v "^$" | wc -l)
        CHART_COUNT=$(echo "$CHART_FILES" | grep -v "^$" | wc -l)
        TOTAL=$((ILL_COUNT + AUDIO_COUNT + CHART_COUNT))
        
        if [ $TOTAL -eq 0 ]; then
            continue
        fi
        
        SONG_COUNT=$((SONG_COUNT + 1))
        
        # 生成卡片
        CARD_HTML="<div class='song-card' data-name='$id_clean'>"
        CARD_HTML+="<div class='song-header'>"
        CARD_HTML+="<span>$id_clean</span>"
        CARD_HTML+="<div>"
        CARD_HTML+="<span id='st-$id_clean' class='status'>$TOTAL个文件</span>"
        CARD_HTML+="<button class='btn-zip' onclick='window.pack(\"$id_clean\", this)'>📦 打包</button>"
        CARD_HTML+="</div></div>"
        CARD_HTML+="<div class='song-content'>"
        
        # 预览图
        CARD_HTML+="<div class='preview-area'>"
        ILL_PREVIEW=$(echo "$ILL_FILES" | head -n1)
        if [ ! -z "$ILL_PREVIEW" ]; then
            ILL_URL="${BASE_URL}/${ILL_PREVIEW#./}"
            CARD_HTML+="<img class='preview-img' src='$ILL_URL' loading='lazy'>"
        else
            CARD_HTML+="<div style='height:140px;background:#30363d;border-radius:8px;'></div>"
        fi
        CARD_HTML+="</div>"
        
        # 文件列表
        CARD_HTML+="<div class='resource-list'>"
        CARD_HTML+="<div class='select-all' onclick='window.toggleAll(\"$id_clean\")'>📋 全选/取消</div>"
        CARD_HTML+="<div id='files-$id_clean'>"
        
        # 曲绘
        if [ $ILL_COUNT -gt 0 ]; then
            echo "$ILL_FILES" | while read -r f; do
                f_clean=${f#./}
                f_name=$(basename "$f")
                f_url="${BASE_URL}/${f_clean}"
                CARD_HTML+="<label class='file-item'>"
                CARD_HTML+="<input type='checkbox' class='checkbox' data-url='$f_url' data-name='$f_name' checked>"
                CARD_HTML+="<span class='tag tag-ill'>曲绘</span>"
                CARD_HTML+="<span class='file-name'>$f_name</span>"
                CARD_HTML+="</label>"
            done
        fi
        
        # 音频
        if [ $AUDIO_COUNT -gt 0 ]; then
            echo "$AUDIO_FILES" | while read -r f; do
                f_clean=${f#./}
                f_name=$(basename "$f")
                f_url="${BASE_URL}/${f_clean}"
                CARD_HTML+="<label class='file-item'>"
                CARD_HTML+="<input type='checkbox' class='checkbox' data-url='$f_url' data-name='$f_name' checked>"
                CARD_HTML+="<span class='tag tag-audio'>音频</span>"
                CARD_HTML+="<span class='file-name'>$f_name</span>"
                CARD_HTML+="</label>"
            done
        fi
        
        # 谱面
        if [ $CHART_COUNT -gt 0 ]; then
            echo "$CHART_FILES" | while read -r f; do
                f_clean=${f#./}
                f_name=$(basename "$f")
                f_url="${BASE_URL}/${f_clean}"
                CARD_HTML+="<label class='file-item'>"
                CARD_HTML+="<input type='checkbox' class='checkbox' data-url='$f_url' data-name='$f_name' checked>"
                CARD_HTML+="<span class='tag tag-chart'>谱面</span>"
                CARD_HTML+="<span class='file-name'>$f_name</span>"
                CARD_HTML+="</label>"
            done
        fi
        
        CARD_HTML+="</div></div></div></div>"
        SONG_CARDS+="$CARD_HTML\n"
    done
fi

cd -

if [ $SONG_COUNT -eq 0 ]; then
    echo "<div style='text-align:center;color:#8b949e;padding:40px;'>未找到任何资源</div>" >> "$OUTPUT_FILE"
else
    echo -e "$SONG_CARDS" >> "$OUTPUT_FILE"
fi

echo "</div>" >> "$OUTPUT_FILE"

# 添加JavaScript功能
cat >> "$OUTPUT_FILE" << 'JS_CONTENT'
</div>

<script>
    // 下载站功能
    window.initDownloadStation = function() {
        console.log('下载站初始化');
        
        // 搜索功能
        const searchInput = document.getElementById('search');
        if (searchInput) {
            searchInput.addEventListener('input', function() {
                const term = this.value.toLowerCase();
                document.querySelectorAll('.song-card').forEach(card => {
                    card.style.display = card.dataset.name.toLowerCase().includes(term) ? '' : 'none';
                });
            });
        }
        
        // 点击文件项切换复选框
        document.querySelectorAll('.file-item').forEach(item => {
            item.addEventListener('click', function(e) {
                if (e.target.type !== 'checkbox') {
                    const cb = this.querySelector('.checkbox');
                    if (cb) {
                        cb.checked = !cb.checked;
                        window.updateStatus(cb.closest('.song-card').dataset.name);
                    }
                }
            });
        });
        
        // 初始化状态
        document.querySelectorAll('.song-card').forEach(card => {
            window.updateStatus(card.dataset.name);
        });
    };
    
    window.toggleAll = function(songId) {
        const container = document.getElementById('files-' + songId);
        if (!container) return;
        
        const checkboxes = container.querySelectorAll('.checkbox');
        const allChecked = Array.from(checkboxes).every(cb => cb.checked);
        
        checkboxes.forEach(cb => {
            cb.checked = !allChecked;
        });
        
        window.updateStatus(songId);
    };
    
    window.updateStatus = function(songId) {
        const container = document.getElementById('files-' + songId);
        if (!container) return;
        
        const checkboxes = container.querySelectorAll('.checkbox');
        const checked = Array.from(checkboxes).filter(cb => cb.checked).length;
        const total = checkboxes.length;
        
        const statusElem = document.getElementById('st-' + songId);
        if (statusElem) {
            statusElem.textContent = checked + '/' + total + '选中';
        }
    };
    
    window.pack = async function(songId, button) {
        const container = document.getElementById('files-' + songId);
        if (!container) return;
        
        const checkboxes = container.querySelectorAll('.checkbox:checked');
        if (checkboxes.length === 0) {
            alert('请选择文件');
            return;
        }
        
        button.disabled = true;
        button.textContent = '打包中...';
        
        try {
            const zip = new JSZip();
            for (const cb of checkboxes) {
                const response = await fetch(cb.dataset.url);
                const blob = await response.blob();
                zip.file(cb.dataset.name, blob);
            }
            
            const content = await zip.generateAsync({ type: 'blob' });
            const link = document.createElement('a');
            link.href = URL.createObjectURL(content);
            link.download = songId + '.zip';
            link.click();
            
            button.textContent = '完成';
            setTimeout(() => {
                button.disabled = false;
                button.textContent = '📦 打包';
            }, 2000);
        } catch (error) {
            alert('错误: ' + error.message);
            button.disabled = false;
            button.textContent = '📦 打包';
        }
    };
    
    // 页面加载完成后初始化
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
echo "📊 歌曲数量: $SONG_COUNT"
echo "🔒 验证系统: 已启用（匹配index.html）"
echo "✓ 复选框: 强制显示"
echo "📦 文件: $OUTPUT_FILE"
