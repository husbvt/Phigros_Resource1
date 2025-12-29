# 2. 生成带强制访问控制 + 可视化进度条的下载站
run: |
  # 使用JSDelivr CDN
  BASE_URL="https://phigros-res.l1quid.dpdns.org"
  
  # 1. 初始化 HTML 头部 
  # (包含: 强力访问控制 + 进度条样式 + 灯箱样式)
  cat > home.html <<'EOF'
  <!DOCTYPE html>
  <html lang="zh-CN">
  <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Zephyr的下载站</title>
      <script src="https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js"></script>
      
      <style>
          :root { --blue: #58a6ff; --bg: #0d1117; --card: #161b22; --border: #30363d; --green: #238636; --red: #da3633; }
          body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: var(--bg); color: #c9d1d9; margin: 0; padding: 15px; }
          .container { max-width: 900px; margin: auto; padding-bottom: 50px; }
          
          /* 基础组件 */
          h1 { color: var(--blue); text-align: center; margin-bottom: 30px; padding-top: 20px; }
          .search-box { width: 100%; padding: 12px; background: var(--card); border: 1px solid var(--border); color: #fff; border-radius: 8px; margin-bottom: 20px; box-sizing: border-box; font-size: 16px; outline: none; }
          .search-box:focus { border-color: var(--blue); }
          
          /* 歌曲卡片 */
          .song-card { background: var(--card); border: 1px solid var(--border); border-radius: 12px; margin-bottom: 25px; overflow: hidden; transition: transform 0.2s; }
          .song-card:hover { border-color: #58a6ff; }
          .song-header { background: #21262d; padding: 15px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px; }
          .song-title { font-size: 1.1em; font-weight: bold; color: var(--blue); }
          
          /* 卡片内容布局 */
          .song-content { display: flex; flex-direction: column; padding: 15px; gap: 20px; }
          @media (min-width: 600px) { .song-content { flex-direction: row; } }
          
          /* 曲绘预览 (带点击提示) */
          .preview-area { flex: 0 0 240px; position: relative; cursor: zoom-in; overflow: hidden; border-radius: 8px; }
          .preview-img { width: 100%; height: 140px; object-fit: cover; border: 1px solid var(--border); background: #21262d; transition: transform 0.3s; }
          .preview-area:hover .preview-img { transform: scale(1.05); }
          .preview-overlay { position: absolute; inset: 0; background: rgba(0,0,0,0.3); display: flex; justify-content: center; align-items: center; opacity: 0; transition: 0.2s; }
          .preview-area:hover .preview-overlay { opacity: 1; }
          
          /* 文件列表 */
          .resource-list { flex: 1; min-width: 0; }
          .file-item { display: flex; align-items: center; background: #0d1117; padding: 10px; margin-bottom: 6px; border-radius: 6px; border: 1px solid var(--border); font-size: 13px; cursor: pointer; user-select: none; transition: 0.2s; }
          .file-item:hover { border-color: var(--blue); background: #1c2128; }
          .file-item input { margin-right: 12px; accent-color: var(--green); transform: scale(1.1); }
          
          /* 标签 */
          .tag { font-size: 0.75em; padding: 2px 6px; border-radius: 4px; color: #fff; margin-right: 8px; font-weight: bold; min-width: 40px; text-align: center; }
          .tag-ill { background: var(--red); } .tag-audio { background: #1f6feb; } .tag-chart { background: var(--green); }
          .file-name { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; flex: 1; color: #e6edf3; }
          
          /* 难度标签 */
          .diff { font-size: 0.7em; padding: 1px 5px; border-radius: 3px; margin-left: 5px; font-weight: bold; }
          .diff-EZ { background: var(--green); color: #fff; } .diff-HD { background: #0077b6; color: #fff; }
          .diff-IN { background: #da3633; color: #fff; } .diff-AT { background: #6c757d; color: #fff; } .diff-SP { background: #e9c46a; color: #000; }
  
          /* 按钮 */
          .btn-zip { background: var(--green); color: white; border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer; font-weight: bold; transition: 0.2s; white-space: nowrap; }
          .btn-zip:hover { background: #2ea043; transform: translateY(-1px); }
          .btn-sel { background: transparent; color: var(--blue); border: 1px solid var(--border); padding: 5px 10px; border-radius: 6px; cursor: pointer; font-size: 12px; margin-bottom: 10px; display: inline-block; }
          .btn-sel:hover { border-color: var(--blue); }
  
          /* === 🚀 核心新增：全屏下载进度面板样式 === */
          #dl-modal { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.85); z-index: 10000; justify-content: center; align-items: center; backdrop-filter: blur(8px); animation: fadeIn 0.2s; }
          .dl-box { background: #161b22; border: 1px solid #30363d; padding: 30px; border-radius: 16px; width: 90%; max-width: 420px; text-align: center; box-shadow: 0 20px 50px rgba(0,0,0,0.6); transform: scale(0.9); animation: popUp 0.3s forwards cubic-bezier(0.175, 0.885, 0.32, 1.275); }
          .dl-title { font-size: 20px; color: #fff; margin-bottom: 25px; font-weight: bold; display: flex; align-items: center; justify-content: center; gap: 10px; }
          .dl-bar-bg { width: 100%; height: 12px; background: #0d1117; border-radius: 6px; overflow: hidden; border: 1px solid #30363d; margin-bottom: 15px; position: relative; }
          .dl-bar-fill { height: 100%; width: 0%; background: linear-gradient(90deg, #238636, #2ea043); transition: width 0.3s ease; box-shadow: 0 0 10px rgba(46, 160, 67, 0.5); }
          .dl-info { font-size: 14px; color: #8b949e; min-height: 20px; margin-bottom: 25px; font-family: monospace; }
          .dl-close { padding: 8px 25px; background: #30363d; color: white; border: none; border-radius: 6px; cursor: pointer; display: none; font-weight: bold; }
          .dl-close:hover { background: #484f58; }
          
          /* === 🖼️ 核心新增：图片灯箱 (Lightbox) 样式 === */
          #lightbox { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.9); z-index: 10001; justify-content: center; align-items: center; cursor: zoom-out; animation: fadeIn 0.2s; }
          #lightbox img { max-width: 95%; max-height: 95vh; border-radius: 4px; box-shadow: 0 0 30px rgba(0,0,0,0.5); transform: scale(0.95); animation: zoomIn 0.25s forwards; }
          
          /* 动画定义 */
          @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
          @keyframes popUp { to { transform: scale(1); } }
          @keyframes zoomIn { to { transform: scale(1); } }
      </style>
  
      <script>
          // 🔒 访问控制逻辑 (保持最简核心保护)
          (function() {
              function check() {
                  const t = new URLSearchParams(location.search).get('verified') || sessionStorage.getItem('auth_token');
                  if(!t) return false;
                  try { 
                      const ts = parseInt(atob(t).split('_')[0]);
                      return (Date.now() - ts < 600000); // 10分钟有效期
                  } catch(e) { return false; }
              }
              if(!check()) {
                  // 验证失败，显示遮罩
                  document.write('<div style="position:fixed;inset:0;background:#0d1117;color:#c9d1d9;display:flex;flex-direction:column;justify-content:center;align-items:center;z-index:99999"><h2>🔒 正在验证访问权限...</h2><p>如果没有跳转，请手动返回首页。</p></div>');
                  setTimeout(() => location.href = 'index.html', 1500);
              } else {
                  // 验证通过，刷新Token时间
                  sessionStorage.setItem('auth_time', Date.now());
              }
          })();
      </script>
  </head>
  <body>
      <div id="dl-modal">
          <div class="dl-box">
              <div class="dl-title">📦 资源打包下载中</div>
              <div class="dl-bar-bg"><div id="dl-progress" class="dl-bar-fill"></div></div>
              <div id="dl-text" class="dl-info">准备开始...</div>
              <button id="dl-close-btn" class="dl-close" onclick="closeDlModal()">关闭窗口</button>
          </div>
      </div>
  
      <div id="lightbox" onclick="this.style.display='none'">
          <img id="lb-img" src="" alt="预览大图">
      </div>
  
      <div class="container">
          <h1>🎵 Zephyr的下载站</h1>
          <input type="text" id="search" class="search-box" placeholder="🔍 搜索歌曲 (ID/名称)...">
          <div id="list"></div>
      </div>
  EOF
  
  # 2. 核心逻辑：生成卡片并注入 JS
  cd build_repo
  
  # 获取 ID 列表
  SONG_IDS=$( ( \
      [ -d "chart" ] && find chart -type d -mindepth 1 -maxdepth 1 | sed 's|chart/||' ; \
      [ -d "music" ] && find music -type f \( -name "*.mp3" -o -name "*.ogg" \) | xargs -I {} basename {} | sed 's/\.[^.]*$//' \
  ) | sed 's/\.[0-9]*$//' | sort -u )
  
  TMP_JS=$(mktemp)
  
  # 生成数据 JSON (比直接生成HTML更高效)
  echo "const db = [" > "$TMP_JS"
  
  for id in $SONG_IDS; do
      # 查找文件
      ILL=$(find illustration -type f \( -name "${id}.*" -o -name "${id}.*.*" \) 2>/dev/null | head -1)
      AUD=$(find music -type f \( -name "${id}.*" -o -name "${id}.*.*" \) 2>/dev/null | head -1)
      
      # 查找谱面
      CHART_DIR=""
      if [ -d "chart/${id}" ]; then CHART_DIR="chart/${id}"; 
      else POSSIBLE=$(find chart -type d -name "${id}*" | head -1); [ -n "$POSSIBLE" ] && CHART_DIR="$POSSIBLE"; fi
      CHARTS=$( [ -n "$CHART_DIR" ] && find "$CHART_DIR" -type f -name "*.json" 2>/dev/null || echo "" )
      
      [ -z "$ILL$AUD$CHARTS" ] && continue
  
      # 构建 JSON 对象
      echo "{id: \"$id\", ill: \"$ILL\", aud: \"$AUD\", charts: [" >> "$TMP_JS"
      for c in $CHARTS; do
          fn=$(basename "$c")
          echo "{path: \"$c\", name: \"$fn\"}," >> "$TMP_JS"
      done
      echo "]}," >> "$TMP_JS"
  done
  
  echo "];" >> "$TMP_JS"
  
  # 3. 注入前端逻辑 (含进度条控制 + 灯箱逻辑)
  cat >> ../home.html <<EOF2
  <script>
  // 注入数据
  $(cat "$TMP_JS")
  
  const BASE_URL = "$BASE_URL";
  
  // 初始化渲染
  const list = document.getElementById('list');
  
  function render() {
      list.innerHTML = db.map(song => {
          let html = \`<div class="song-card" data-id="\${song.id.toLowerCase()}">
              <div class="song-header">
                  <span class="song-title">\${song.id}</span>
                  <button class="btn-zip" onclick="startDownload('\${song.id}')">📦 打包下载</button>
              </div>
              <div class="song-content">
                  <div class="preview-area" onclick="showLightbox('\${song.ill ? BASE_URL + '/' + song.ill : ''}')">
                      \${song.ill 
                          ? \`<img class="preview-img" src="\${BASE_URL}/\${song.ill}" loading="lazy"><div class="preview-overlay"><span style="color:white;font-weight:bold">🔍 点击查看大图</span></div>\`
                          : '<div class="preview-img" style="display:flex;justify-content:center;align-items:center;color:#555">无预览</div>'
                      }
                  </div>
                  <div class="resource-list" id="files-\${song.id}">
                      <div class="btn-sel" onclick="toggleAll(this)">✅ 全选/反选</div>\`;
          
          // 曲绘选项
          if(song.ill) {
              const fn = song.ill.split('/').pop();
              html += \`<label class="file-item" data-url="\${BASE_URL}/\${song.ill}" data-name="\${fn}">
                  <input type="checkbox" checked><span class="tag tag-ill">曲绘</span><span class="file-name">\${fn}</span>
              </label>\`;
          }
          // 音频选项
          if(song.aud) {
              const fn = song.aud.split('/').pop();
              html += \`<label class="file-item" data-url="\${BASE_URL}/\${song.aud}" data-name="\${fn}">
                  <input type="checkbox" checked><span class="tag tag-audio">音频</span><span class="file-name">\${fn}</span>
              </label>\`;
          }
          // 谱面选项
          song.charts.forEach(c => {
              let diff = "";
              const up = c.name.toUpperCase();
              if(up.includes('EZ')) diff = '<span class="diff diff-EZ">EZ</span>';
              else if(up.includes('HD')) diff = '<span class="diff diff-HD">HD</span>';
              else if(up.includes('IN')) diff = '<span class="diff diff-IN">IN</span>';
              else if(up.includes('AT')) diff = '<span class="diff diff-AT">AT</span>';
              else if(up.includes('SP')) diff = '<span class="diff diff-SP">SP</span>';
              
              html += \`<label class="file-item" data-url="\${BASE_URL}/\${c.path}" data-name="\${c.name}">
                  <input type="checkbox" checked><span class="tag tag-chart">谱面</span><span class="file-name">\${c.name}</span>\${diff}
              </label>\`;
          });
  
          html += \`</div></div></div>\`;
          return html;
      }).join('');
  }
  
  // 搜索功能
  document.getElementById('search').oninput = (e) => {
      const v = e.target.value.toLowerCase();
      document.querySelectorAll('.song-card').forEach(c => {
          c.style.display = c.dataset.id.includes(v) ? '' : 'none';
      });
  };
  
  // 灯箱功能 (点击图片放大)
  window.showLightbox = (url) => {
      if(!url || url.endsWith('/')) return;
      const lb = document.getElementById('lightbox');
      const img = document.getElementById('lb-img');
      img.src = url;
      lb.style.display = 'flex';
  };
  
  // 全选/反选
  window.toggleAll = (btn) => {
      const inputs = btn.parentElement.querySelectorAll('input');
      const all = Array.from(inputs).every(i => i.checked);
      inputs.forEach(i => i.checked = !all);
  };
  
  // 关闭下载弹窗
  window.closeDlModal = () => {
      document.getElementById('dl-modal').style.display = 'none';
  };
  
  // === 核心：带进度条的下载逻辑 ===
  window.startDownload = async (id) => {
      // 1. 获取选中的文件
      const container = document.getElementById('files-' + id);
      const items = Array.from(container.querySelectorAll('.file-item'))
          .filter(item => item.querySelector('input').checked)
          .map(item => ({
              url: item.dataset.url,
              name: item.dataset.name
          }));
  
      if(items.length === 0) return alert("请至少选择一个文件！");
  
      // 2. 唤起进度条弹窗
      const modal = document.getElementById('dl-modal');
      const pBar = document.getElementById('dl-progress');
      const pText = document.getElementById('dl-text');
      const closeBtn = document.getElementById('dl-close-btn');
      
      modal.style.display = 'flex';
      closeBtn.style.display = 'none'; // 下载中禁止关闭
      pBar.style.width = '0%';
      pBar.style.background = 'linear-gradient(90deg, #238636, #2ea043)'; // 恢复绿色
      
      try {
          const zip = new JSZip();
          const total = items.length;
          let count = 0;
  
          // 3. 逐个下载文件
          for(const item of items) {
              // 更新UI：显示当前下载的文件名
              pText.innerHTML = \`正在下载 (\${count+1}/\${total}): <br><span style="color:#58a6ff">\${item.name}</span>\`;
              
              // 获取文件
              const resp = await fetch(item.url);
              if(!resp.ok) throw new Error(\`下载失败: \${item.name}\`);
              const blob = await resp.blob();
              
              // 添加到Zip
              zip.file(item.name, blob);
              
              // 更新进度条
              count++;
              pBar.style.width = ((count / total) * 100) + '%';
          }
  
          // 4. 压缩打包
          pText.innerHTML = '📦 正在压缩打包，请稍候...';
          const content = await zip.generateAsync({type:"blob"});
          
          // 5. 触发下载
          const a = document.createElement('a');
          a.href = URL.createObjectURL(content);
          a.download = \`\${id}.zip\`;
          a.click();
  
          // 6. 完成状态
          pText.innerHTML = '✅ 下载完成！已自动保存';
          closeBtn.style.display = 'inline-block';
          
          // 3秒后自动关闭
          setTimeout(() => { if(modal.style.display !== 'none') closeDlModal(); }, 3000);
  
      } catch(e) {
          console.error(e);
          pText.innerHTML = \`❌ 发生错误: <br>\${e.message}\`;
          pBar.style.background = '#da3633'; // 变红
          closeBtn.style.display = 'inline-block';
      }
  };
  
  // 启动
  render();
  </script>
  </body>
  </html>
  EOF2
  
  rm "$TMP_JS"
  echo "✅ 增强版下载站生成完成"
