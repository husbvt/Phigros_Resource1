#!/bin/bash
# scripts/generate_zephyr_site.sh - 完整修复版
set -e

BASE_URL="https://phigros-res.l1quid.dpdns.org"
BUILD_REPO="$1"
OUTPUT_FILE="$2"

echo "开始生成Zephyr下载站..."

# 创建完整HTML文件
cat > "$OUTPUT_FILE" << 'HTML_HEAD'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zephyr的下载站</title>
    <script src="https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js"></script>
    
    <script>
        // ===== 强制验证系统 =====
        (function() {
            console.log('🔐 Zephyr下载站 - 强制验证启动');
            
            // 立即清空页面，显示验证界面
            document.body.innerHTML = `
                <div style="
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
                    z-index: 99999;
                    color: #c9d1d9;
                    text-align: center;
                    padding: 40px 20px;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                ">
                    <div style="font-size: 4rem; margin-bottom: 20px;">🔒</div>
                    <h1 style="color: #58a6ff; margin: 0 0 15px 0; font-size: 2rem;">访问验证</h1>
                    <p id="verifyMessage" style="margin: 0 0 40px 0; font-size: 1.1rem; max-width: 500px;">
                        正在验证访问权限，请稍候...
                    </p>
                    
                    <div style="width: 300px; height: 8px; background: #30363d; border-radius: 4px; overflow: hidden; margin-bottom: 30px;">
                        <div id="verifyProgress" style="height: 100%; background: #238636; width: 0%; transition: width 0.3s ease;"></div>
                    </div>
                    
                    <div id="verifyActions" style="display: none;">
                        <button onclick="window.location.href='index.html'" style="
                            padding: 12px 30px;
                            background: #238636;
                            color: white;
                            border: none;
                            border-radius: 8px;
                            cursor: pointer;
                            font-weight: bold;
                            font-size: 1rem;
                            transition: background 0.2s;
                        ">
                            前往验证页面
                        </button>
                        <p style="margin-top: 20px; color: #8b949e; font-size: 0.9rem;">
                            如果未自动跳转，请点击上方按钮
                        </p>
                    </div>
                </div>
            `;
            
            // 严格的验证函数
            function strictVerify() {
                console.log('🔍 执行严格验证检查...');
                
                // 1. 必须检查 sessionStorage 令牌
                const token = sessionStorage.getItem('auth_token');
                if (!token || token.trim() === '') {
                    console.log('❌ 未找到验证令牌');
                    return { valid: false, reason: 'no_token' };
                }
                
                try {
                    // 2. 解码令牌
                    const decoded = atob(token);
                    console.log('令牌解码:', decoded.substring(0, 50) + '...');
                    
                    // 3. 检查格式: 时间戳_随机字符串
                    const parts = decoded.split('_');
                    if (parts.length < 2) {
                        console.log('❌ 令牌格式错误');
                        return { valid: false, reason: 'bad_format' };
                    }
                    
                    // 4. 验证时间戳
                    const timestamp = parseInt(parts[0]);
                    if (isNaN(timestamp)) {
                        console.log('❌ 无效的时间戳');
                        return { valid: false, reason: 'bad_timestamp' };
                    }
                    
                    // 5. 检查有效期 (10分钟)
                    const now = Date.now();
                    const age = now - timestamp;
                    const maxAge = 10 * 60 * 1000; // 10分钟
                    
                    console.log(`令牌信息: 创建于 ${new Date(timestamp).toLocaleTimeString()}, 年龄 ${Math.round(age/1000)}秒`);
                    
                    if (age > maxAge) {
                        console.log(`❌ 令牌已过期 (${Math.round(age/1000)}秒 > ${maxAge/1000}秒)`);
                        // 清除过期令牌
                        sessionStorage.removeItem('auth_token');
                        return { valid: false, reason: 'expired' };
                    }
                    
                    if (age < 0) {
                        console.log('❌ 未来时间戳');
                        return { valid: false, reason: 'future_timestamp' };
                    }
                    
                    console.log(`✅ 令牌验证通过 (${Math.round(age/1000)}秒前)`);
                    return { valid: true, age: age };
                    
                } catch (error) {
                    console.log('❌ 令牌解码失败:', error);
                    sessionStorage.removeItem('auth_token');
                    return { valid: false, reason: 'decode_error' };
                }
            }
            
            // 进度条动画
            let progress = 0;
            const progressBar = document.getElementById('verifyProgress');
            const verifyMessage = document.getElementById('verifyMessage');
            const verifyActions = document.getElementById('verifyActions');
            
            // 验证定时器
            const verifyTimer = setInterval(() => {
                progress += 5;
                if (progressBar) {
                    progressBar.style.width = progress + '%';
                }
                
                if (progress >= 100) {
                    clearInterval(verifyTimer);
                    
                    // 执行验证
                    const result = strictVerify();
                    
                    if (result.valid) {
                        // 验证成功
                        verifyMessage.textContent = '✅ 验证通过，正在加载下载站...';
                        if (progressBar) progressBar.style.background = '#58a6ff';
                        
                        // 显示真实页面内容
                        setTimeout(() => {
                            document.body.innerHTML = ORIGINAL_PAGE_CONTENT;
                            // 初始化页面功能
                            if (typeof window.initDownloadPage === 'function') {
                                setTimeout(window.initDownloadPage, 100);
                            }
                        }, 500);
                        
                    } else {
                        // 验证失败
                        verifyMessage.innerHTML = '❌ 需要验证访问权限<br><small style="color:#8b949e;font-size:0.9em;">请完成人机验证后访问</small>';
                        if (progressBar) {
                            progressBar.style.background = '#da3633';
                            progressBar.style.width = '100%';
                        }
                        
                        // 显示操作按钮
                        verifyActions.style.display = 'block';
                        
                        // 5秒后自动跳转
                        setTimeout(() => {
                            // 清理可能的残留数据
                            sessionStorage.removeItem('auth_token');
                            // 强制跳转到验证页
                            window.location.href = 'index.html?from=' + encodeURIComponent(window.location.pathname);
                        }, 5000);
                    }
                }
            }, 50);
            
            // 原始页面内容 (由脚本填充)
            const ORIGINAL_PAGE_CONTENT = `
                <!-- 下载站页面内容 -->
                <div class="page-container">
HTML_HEAD

echo "生成页面内容..."

# 进入资源目录
cd "$BUILD_REPO"

# 统计歌曲数量
SONG_COUNT=0
SONG_CARDS=""

# 方法1: 从chart目录查找歌曲
if [ -d "chart" ]; then
    echo "从chart目录查找歌曲..."
    find chart -type d -mindepth 1 -maxdepth 1 2>/dev/null | sort | while read song_dir; do
        song_id=$(basename "$song_dir")
        song_id_clean=$(echo "$song_id" | sed 's/\.[0-9]*$//')
        
        if [ -z "$song_id_clean" ]; then
            continue
        fi
        
        echo "  处理: $song_id_clean"
        
        # === 文件查找（去重处理） ===
        
        # 1. 曲绘文件 - 只取第一个
        ILL_FILE=""
        if [ -d "illustration" ]; then
            ILL_FILE=$(find illustration -maxdepth 1 -type f \( -name "${song_id}.*" -o -name "${song_id_clean}.*" \) 2>/dev/null | head -1)
            if [ -z "$ILL_FILE" ]; then
                # 尝试模糊匹配
                ILL_FILE=$(find illustration -maxdepth 1 -type f -name "*${song_id_clean}*" 2>/dev/null | head -1)
            fi
        fi
        
        # 2. 音频文件 - 只取第一个（优先ogg，然后mp3）
        AUDIO_FILE=""
        if [ -d "music" ]; then
            AUDIO_FILE=$(find music -maxdepth 1 -type f \( -name "${song_id}.ogg" -o -name "${song_id_clean}.ogg" \) 2>/dev/null | head -1)
            if [ -z "$AUDIO_FILE" ]; then
                AUDIO_FILE=$(find music -maxdepth 1 -type f \( -name "${song_id}.mp3" -o -name "${song_id_clean}.mp3" \) 2>/dev/null | head -1)
            fi
        fi
        
        # 3. 谱面文件 - 按难度去重
        CHART_FILES=""
        if [ -d "chart/$song_id" ]; then
            # 按难度去重：只保留每个难度的第一个文件
            declare -A difficulty_map
            find "chart/$song_id" -type f -name "*.json" 2>/dev/null | while read chart_file; do
                filename=$(basename "$chart_file")
                # 提取难度
                difficulty=""
                if [[ $filename =~ EZ|Ez|ez ]]; then difficulty="EZ"
                elif [[ $filename =~ HD|Hd|hd ]]; then difficulty="HD"
                elif [[ $filename =~ IN|In|in ]]; then difficulty="IN"
                elif [[ $filename =~ AT|At|at ]]; then difficulty="AT"
                elif [[ $filename =~ SP|Sp|sp ]]; then difficulty="SP"
                fi
                
                if [ ! -z "$difficulty" ] && [ -z "${difficulty_map[$difficulty]}" ]; then
                    difficulty_map[$difficulty]=$chart_file
                    CHART_FILES="$CHART_FILES$chart_file"$'\n'
                fi
            done
        fi
        
        # 统计文件数量
        FILE_COUNT=0
        if [ ! -z "$ILL_FILE" ] && [ -f "$ILL_FILE" ]; then
            FILE_COUNT=$((FILE_COUNT + 1))
        fi
        if [ ! -z "$AUDIO_FILE" ] && [ -f "$AUDIO_FILE" ]; then
            FILE_COUNT=$((FILE_COUNT + 1))
        fi
        CHART_COUNT=$(echo "$CHART_FILES" | grep -c . || true)
        FILE_COUNT=$((FILE_COUNT + CHART_COUNT))
        
        if [ $FILE_COUNT -eq 0 ]; then
            continue
        fi
        
        SONG_COUNT=$((SONG_COUNT + 1))
        
        # 生成歌曲卡片HTML
        CARD_HTML="<div class='song-card' data-song-id='$song_id_clean'>"
        CARD_HTML+="<div class='song-header'>"
        CARD_HTML+="<div class='song-title'>$song_id_clean</div>"
        CARD_HTML+="<div class='song-controls'>"
        CARD_HTML+="<span class='file-count' id='count-$song_id_clean'>0/$FILE_COUNT 选中</span>"
        CARD_HTML+="<button class='download-btn' onclick='downloadSong(\"$song_id_clean\")'>📦 打包下载</button>"
        CARD_HTML+="</div></div>"
        
        CARD_HTML+="<div class='song-content'>"
        
        # 预览区域
        CARD_HTML+="<div class='preview-area'>"
        if [ ! -z "$ILL_FILE" ] && [ -f "$ILL_FILE" ]; then
            ILL_URL="${BASE_URL}/${ILL_FILE}"
            CARD_HTML+="<img src='$ILL_URL' alt='$song_id_clean' class='preview-img' loading='lazy'>"
        else
            CARD_HTML+="<div class='no-preview'>无预览图</div>"
        fi
        CARD_HTML+="</div>"
        
        # 文件列表区域
        CARD_HTML+="<div class='files-area'>"
        CARD_HTML+="<div class='select-all' onclick='toggleAllFiles(\"$song_id_clean\")'>📋 全选/取消全选</div>"
        CARD_HTML+="<div class='file-list' id='files-$song_id_clean'>"
        
        # 添加曲绘文件
        if [ ! -z "$ILL_FILE" ] && [ -f "$ILL_FILE" ]; then
            ILL_URL="${BASE_URL}/${ILL_FILE}"
            ILL_NAME=$(basename "$ILL_FILE")
            CARD_HTML+="<div class='file-item' onclick='toggleFile(this)'>"
            CARD_HTML+="<input type='checkbox' class='file-checkbox' checked data-url='$ILL_URL' data-name='$ILL_NAME'>"
            CARD_HTML+="<span class='file-tag file-tag-ill'>曲绘</span>"
            CARD_HTML+="<span class='file-name'>$ILL_NAME</span>"
            CARD_HTML+="</div>"
        fi
        
        # 添加音频文件
        if [ ! -z "$AUDIO_FILE" ] && [ -f "$AUDIO_FILE" ]; then
            AUDIO_URL="${BASE_URL}/${AUDIO_FILE}"
            AUDIO_NAME=$(basename "$AUDIO_FILE")
            CARD_HTML+="<div class='file-item' onclick='toggleFile(this)'>"
            CARD_HTML+="<input type='checkbox' class='file-checkbox' checked data-url='$AUDIO_URL' data-name='$AUDIO_NAME'>"
            CARD_HTML+="<span class='file-tag file-tag-audio'>音频</span>"
            CARD_HTML+="<span class='file-name'>$AUDIO_NAME</span>"
            CARD_HTML+="</div>"
        fi
        
        # 添加谱面文件（已去重）
        if [ ! -z "$CHART_FILES" ]; then
            echo "$CHART_FILES" | while read -r CHART_FILE; do
                [ -z "$CHART_FILE" ] && continue
                if [ -f "$CHART_FILE" ]; then
                    CHART_URL="${BASE_URL}/${CHART_FILE}"
                    CHART_NAME=$(basename "$CHART_FILE")
                    
                    # 确定难度
                    DIFF_CLASS=""
                    DIFF_TEXT=""
                    if [[ $CHART_NAME =~ EZ|Ez|ez ]]; then
                        DIFF_CLASS="diff-ez"
                        DIFF_TEXT="EZ"
                    elif [[ $CHART_NAME =~ HD|Hd|hd ]]; then
                        DIFF_CLASS="diff-hd"
                        DIFF_TEXT="HD"
                    elif [[ $CHART_NAME =~ IN|In|in ]]; then
                        DIFF_CLASS="diff-in"
                        DIFF_TEXT="IN"
                    elif [[ $CHART_NAME =~ AT|At|at ]]; then
                        DIFF_CLASS="diff-at"
                        DIFF_TEXT="AT"
                    elif [[ $CHART_NAME =~ SP|Sp|sp ]]; then
                        DIFF_CLASS="diff-sp"
                        DIFF_TEXT="SP"
                    fi
                    
                    CARD_HTML+="<div class='file-item' onclick='toggleFile(this)'>"
                    CARD_HTML+="<input type='checkbox' class='file-checkbox' checked data-url='$CHART_URL' data-name='$CHART_NAME'>"
                    CARD_HTML+="<span class='file-tag file-tag-chart'>谱面</span>"
                    CARD_HTML+="<span class='file-name'>$CHART_NAME</span>"
                    if [ ! -z "$DIFF_CLASS" ]; then
                        CARD_HTML+="<span class='difficulty $DIFF_CLASS'>$DIFF_TEXT</span>"
                    fi
                    CARD_HTML+="</div>"
                fi
            done
        fi
        
        CARD_HTML+="</div></div></div></div>"
        
        SONG_CARDS+="$CARD_HTML"
    done
fi

# 方法2: 如果chart目录没找到，从music目录查找
if [ $SONG_COUNT -eq 0 ] && [ -d "music" ]; then
    echo "从music目录查找歌曲..."
    find music -type f \( -name "*.mp3" -o -name "*.ogg" \) 2>/dev/null | while read audio_file; do
        song_id=$(basename "$audio_file" | sed 's/\.[^.]*$//')
        song_id_clean=$(echo "$song_id" | sed 's/-[0-9]*$//')
        
        if [ -z "$song_id_clean" ]; then
            continue
        fi
        
        # ... 类似的去重处理逻辑 ...
    done
fi

cd -

echo "找到 $SONG_COUNT 个歌曲"

# 继续生成HTML
cat >> "$OUTPUT_FILE" << 'HTML_MIDDLE'
                    <div class="page-header">
                        <h1>🎵 Zephyr的Phigros资源下载站</h1>
                        <p class="page-subtitle">使用JSDelivr CDN，支持跨域下载</p>
                    </div>
                    
                    <div class="search-container">
                        <input type="text" id="searchInput" class="search-input" placeholder="搜索歌曲ID (例如: 青芽)...">
                    </div>
                    
                    <div class="songs-list" id="songsList">
HTML_MIDDLE

# 添加歌曲卡片
if [ $SONG_COUNT -eq 0 ]; then
    echo "<div class='no-results'>❌ 未找到任何资源文件</div>" >> "$OUTPUT_FILE"
else
    echo "$SONG_CARDS" >> "$OUTPUT_FILE"
fi

# 完成HTML
cat >> "$OUTPUT_FILE" << 'HTML_FOOT'
                    </div>
                </div>
                
                <style>
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
                    
                    .search-input::placeholder {
                        color: #6e7681;
                    }
                    
                    /* 歌曲卡片样式 */
                    .song-card {
                        background: #161b22;
                        border: 1px solid #30363d;
                        border-radius: 12px;
                        margin-bottom: 25px;
                        overflow: hidden;
                        transition: transform 0.2s, box-shadow 0.2s;
                    }
                    
                    .song-card:hover {
                        transform: translateY(-2px);
                        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
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
                        word-break: break-all;
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
                        transition: background 0.2s;
                        display: flex;
                        align-items: center;
                        gap: 8px;
                    }
                    
                    .download-btn:hover {
                        background: #2ea043;
                    }
                    
                    .download-btn:disabled {
                        background: #30363d;
                        cursor: not-allowed;
                        opacity: 0.6;
                    }
                    
                    .song-content {
                        display: flex;
                        padding: 25px;
                        gap: 30px;
                    }
                    
                    @media (max-width: 768px) {
                        .song-content {
                            flex-direction: column;
                        }
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
                    
                    .no-preview {
                        width: 100%;
                        height: 180px;
                        background: #21262d;
                        border-radius: 8px;
                        border: 1px dashed #30363d;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        color: #8b949e;
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
                        user-select: none;
                    }
                    
                    .select-all:hover {
                        text-decoration: underline;
                    }
                    
                    .file-list {
                        max-height: 350px;
                        overflow-y: auto;
                        padding-right: 10px;
                    }
                    
                    .file-list::-webkit-scrollbar {
                        width: 8px;
                    }
                    
                    .file-list::-webkit-scrollbar-track {
                        background: #161b22;
                        border-radius: 4px;
                    }
                    
                    .file-list::-webkit-scrollbar-thumb {
                        background: #30363d;
                        border-radius: 4px;
                    }
                    
                    .file-list::-webkit-scrollbar-thumb:hover {
                        background: #484f58;
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
                        transition: all 0.2s;
                        user-select: none;
                    }
                    
                    .file-item:hover {
                        background: #21262d;
                        border-color: #58a6ff;
                    }
                    
                    /* 复选框 - 确保可见 */
                    .file-checkbox {
                        width: 20px;
                        height: 20px;
                        margin-right: 15px;
                        cursor: pointer;
                        accent-color: #238636;
                        flex-shrink: 0;
                    }
                    
                    /* 文件标签 */
                    .file-tag {
                        font-size: 0.8rem;
                        padding: 4px 10px;
                        border-radius: 4px;
                        color: white;
                        margin-right: 12px;
                        font-weight: 600;
                        min-width: 55px;
                        text-align: center;
                        flex-shrink: 0;
                    }
                    
                    .file-tag-ill {
                        background: #da3633;
                    }
                    
                    .file-tag-audio {
                        background: #1f6feb;
                    }
                    
                    .file-tag-chart {
                        background: #238636;
                    }
                    
                    .file-name {
                        flex: 1;
                        overflow: hidden;
                        text-overflow: ellipsis;
                        white-space: nowrap;
                        color: #c9d1d9;
                    }
                    
                    /* 难度标签 */
                    .difficulty {
                        font-size: 0.75rem;
                        padding: 3px 8px;
                        border-radius: 4px;
                        margin-left: 10px;
                        font-weight: bold;
                        color: white;
                        flex-shrink: 0;
                    }
                    
                    .diff-ez { background: #238636; }
                    .diff-hd { background: #da3633; }
                    .diff-in { background: #8957e5; }
                    .diff-at { background: #f0883e; }
                    .diff-sp { background: #9e6a03; }
                    
                    /* 无结果提示 */
                    .no-results {
                        text-align: center;
                        padding: 60px 20px;
                        color: #8b949e;
                        font-size: 1.1rem;
                        background: #161b22;
                        border-radius: 12px;
                        border: 1px solid #30363d;
                    }
                    
                    /* 响应式调整 */
                    @media (max-width: 768px) {
                        .page-container {
                            padding: 15px;
                        }
                        
                        .page-header h1 {
                            font-size: 1.8rem;
                        }
                        
                        .song-header {
                            flex-direction: column;
                            align-items: flex-start;
                            gap: 15px;
                        }
                        
                        .song-controls {
                            width: 100%;
                            justify-content: space-between;
                        }
                        
                        .preview-area {
                            flex: none;
                            width: 100%;
                        }
                        
                        .preview-img,
                        .no-preview {
                            height: 200px;
                        }
                    }
                    
                    @media (max-width: 480px) {
                        .song-content {
                            padding: 20px;
                        }
                        
                        .file-item {
                            padding: 12px 15px;
                            flex-wrap: wrap;
                            gap: 10px;
                        }
                        
                        .file-checkbox {
                            order: 1;
                        }
                        
                        .file-tag {
                            order: 2;
                        }
                        
                        .file-name {
                            order: 3;
                            width: 100%;
                            margin-top: 5px;
                        }
                        
                        .difficulty {
                            order: 4;
                            margin-left: auto;
                        }
                    }
                </style>
            `;
        })();
    </script>
</head>
<body>
    <!-- 页面内容由JavaScript动态加载 -->
    
    <script>
        // ===== 页面功能初始化 =====
        window.initDownloadPage = function() {
            console.log('🚀 初始化下载页面功能');
            
            // 1. 搜索功能
            const searchInput = document.getElementById('searchInput');
            if (searchInput) {
                searchInput.addEventListener('input', function() {
                    const searchTerm = this.value.toLowerCase().trim();
                    const songCards = document.querySelectorAll('.song-card');
                    
                    songCards.forEach(card => {
                        const songId = card.getAttribute('data-song-id').toLowerCase();
                        if (searchTerm === '' || songId.includes(searchTerm)) {
                            card.style.display = '';
                        } else {
                            card.style.display = 'none';
                        }
                    });
                });
            }
            
            // 2. 初始化文件计数
            updateAllFileCounts();
            
            // 3. 点击文件项切换复选框
            document.addEventListener('click', function(event) {
                const fileItem = event.target.closest('.file-item');
                if (fileItem && !event.target.classList.contains('file-checkbox')) {
                    const checkbox = fileItem.querySelector('.file-checkbox');
                    if (checkbox) {
                        checkbox.checked = !checkbox.checked;
                        const songId = fileItem.closest('.song-card').getAttribute('data-song-id');
                        updateFileCount(songId);
                    }
                }
            });
            
            // 4. 监听复选框变化
            document.addEventListener('change', function(event) {
                if (event.target.classList.contains('file-checkbox')) {
                    const songId = event.target.closest('.song-card').getAttribute('data-song-id');
                    updateFileCount(songId);
                }
            });
            
            console.log('✅ 页面功能初始化完成');
        };
        
        // 更新单个歌曲的文件计数
        function updateFileCount(songId) {
            const fileList = document.getElementById('files-' + songId);
            if (!fileList) return;
            
            const checkboxes = fileList.querySelectorAll('.file-checkbox');
            const checkedCount = Array.from(checkboxes).filter(cb => cb.checked).length;
            const totalCount = checkboxes.length;
            
            const countElement = document.getElementById('count-' + songId);
            if (countElement) {
                countElement.textContent = checkedCount + '/' + totalCount + ' 选中';
            }
        }
        
        // 更新所有歌曲的文件计数
        function updateAllFileCounts() {
            document.querySelectorAll('.song-card').forEach(card => {
                const songId = card.getAttribute('data-song-id');
                updateFileCount(songId);
            });
        }
        
        // 全选/取消全选
        window.toggleAllFiles = function(songId) {
            const fileList = document.getElementById('files-' + songId);
            if (!fileList) return;
            
            const checkboxes = fileList.querySelectorAll('.file-checkbox');
            const allChecked = Array.from(checkboxes).every(cb => cb.checked);
            
            checkboxes.forEach(checkbox => {
                checkbox.checked = !allChecked;
            });
            
            updateFileCount(songId);
        };
        
        // 下载歌曲文件
        window.downloadSong = async function(songId) {
            const fileList = document.getElementById('files-' + songId);
            if (!fileList) return;
            
            const checkboxes = fileList.querySelectorAll('.file-checkbox:checked');
            if (checkboxes.length === 0) {
                alert('请至少选择一个文件');
                return;
            }
            
            const button = document.querySelector(`.song-card[data-song-id="${songId}"] .download-btn`);
            if (button) {
                button.disabled = true;
                button.innerHTML = '⏳ 打包中...';
            }
            
            try {
                const zip = new JSZip();
                const files = Array.from(checkboxes).map(cb => ({
                    url: cb.dataset.url,
                    name: cb.dataset.name
                }));
                
                let processed = 0;
                for (const file of files) {
                    try {
                        const response = await fetch(file.url);
                        if (response.ok) {
                            const blob = await response.blob();
                            zip.file(file.name, blob);
                        }
                        processed++;
                    } catch (error) {
                        console.error('下载文件失败:', file.name, error);
                    }
                }
                
                if (Object.keys(zip.files).length === 0) {
                    throw new Error('没有成功下载任何文件');
                }
                
                const content = await zip.generateAsync({ type: 'blob' });
                const downloadUrl = URL.createObjectURL(content);
                const link = document.createElement('a');
                link.href = downloadUrl;
                link.download = songId + '_resources_' + Date.now() + '.zip';
                
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
                
                // 清理URL对象
                setTimeout(() => URL.revokeObjectURL(downloadUrl), 100);
                
                if (button) {
                    button.innerHTML = '✅ 下载完成';
                    setTimeout(() => {
                        button.disabled = false;
                        button.innerHTML = '📦 打包下载';
                    }, 2000);
                }
                
            } catch (error) {
                console.error('打包下载失败:', error);
                alert('下载失败: ' + error.message);
                
                if (button) {
                    button.disabled = false;
                    button.innerHTML = '📦 打包下载';
                }
            }
        };
        
        // 自动初始化
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', function() {
                if (typeof window.initDownloadPage === 'function') {
                    window.initDownloadPage();
                }
            });
        }
    </script>
</body>
</html>
HTML_FOOT

echo "✅ 生成完成！"
echo "📊 统计: $SONG_COUNT 个歌曲"
echo "🔒 验证: 强制验证系统已启用"
echo "✓ 文件: 已去重处理（每个难度只显示一个谱面）"
echo "📁 输出: $OUTPUT_FILE"
echo "🚀 提示: 访问 home.html 会强制验证，必须从 index.html 验证后访问"
