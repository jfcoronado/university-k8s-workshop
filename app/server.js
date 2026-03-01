const http = require('http');
const os = require('os');
const fs = require('fs');

const PORT = process.env.PORT || 3000;

// Track requests handled by THIS pod
let requestCount = 0;
const startTime = new Date();

// Read environment (injected by ConfigMap/Secret)
const config = {
  appEnv:        process.env.APP_ENV        || 'unknown',
  logLevel:      process.env.LOG_LEVEL      || 'info',
  featureNewUI:  process.env.FEATURE_NEW_UI || 'false',
  appVersion:    process.env.APP_VERSION    || '1.0.0',
  dbPassword:    process.env.DB_PASSWORD    ? '****** (injected from Secret)' : 'not set',
  apiKey:        process.env.API_KEY        ? '****** (injected from Secret)' : 'not set',
};

// Read mounted config file if present
let mountedConfig = null;
try {
  mountedConfig = fs.readFileSync('/etc/config/app.properties', 'utf8');
} catch (_) {}

const html = () => `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>☸ K8s Workshop — Live Demo</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&family=Syne:wght@400;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg:        #0a0e1a;
      --surface:   #0f1629;
      --border:    #1e2d4a;
      --accent:    #00d4ff;
      --accent2:   #7c3aed;
      --green:     #10b981;
      --yellow:    #f59e0b;
      --red:       #ef4444;
      --text:      #e2e8f0;
      --muted:     #64748b;
      --mono:      'JetBrains Mono', monospace;
      --sans:      'Syne', sans-serif;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      background: var(--bg);
      color: var(--text);
      font-family: var(--sans);
      min-height: 100vh;
      padding: 2rem;
      background-image:
        radial-gradient(ellipse 80% 50% at 50% -20%, rgba(0,212,255,0.08) 0%, transparent 60%),
        radial-gradient(ellipse 60% 40% at 80% 80%, rgba(124,58,237,0.06) 0%, transparent 50%);
    }

    header {
      display: flex;
      align-items: center;
      gap: 1rem;
      margin-bottom: 2.5rem;
      padding-bottom: 1.5rem;
      border-bottom: 1px solid var(--border);
    }

    .logo {
      font-size: 2.5rem;
      animation: spin 8s linear infinite;
    }

    @keyframes spin {
      from { transform: rotate(0deg); }
      to   { transform: rotate(360deg); }
    }

    h1 {
      font-size: 1.6rem;
      font-weight: 800;
      letter-spacing: -0.02em;
    }

    h1 span { color: var(--accent); }

    .version-badge {
      margin-left: auto;
      background: var(--accent2);
      color: #fff;
      font-family: var(--mono);
      font-size: 0.75rem;
      padding: 0.3rem 0.8rem;
      border-radius: 999px;
      letter-spacing: 0.05em;
    }

    /* ── HERO POD CARD ─────────────────────────────────── */
    .hero {
      background: linear-gradient(135deg, #0f1e3d 0%, #1a0e3d 100%);
      border: 1px solid var(--accent);
      border-radius: 12px;
      padding: 2rem;
      margin-bottom: 2rem;
      position: relative;
      overflow: hidden;
    }

    .hero::before {
      content: '';
      position: absolute;
      top: 0; left: 0; right: 0;
      height: 2px;
      background: linear-gradient(90deg, var(--accent), var(--accent2), var(--accent));
      animation: shimmer 3s linear infinite;
      background-size: 200% 100%;
    }

    @keyframes shimmer {
      0%   { background-position: -200% 0; }
      100% { background-position:  200% 0; }
    }

    .hero-label {
      font-family: var(--mono);
      font-size: 0.7rem;
      color: var(--accent);
      letter-spacing: 0.15em;
      text-transform: uppercase;
      margin-bottom: 0.5rem;
    }

    .pod-name {
      font-family: var(--mono);
      font-size: 1.4rem;
      font-weight: 700;
      color: #fff;
      word-break: break-all;
      margin-bottom: 1.5rem;
    }

    .hero-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
      gap: 1rem;
    }

    .hero-stat {
      background: rgba(255,255,255,0.04);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 0.8rem 1rem;
    }

    .hero-stat-label {
      font-family: var(--mono);
      font-size: 0.65rem;
      color: var(--muted);
      text-transform: uppercase;
      letter-spacing: 0.1em;
      margin-bottom: 0.3rem;
    }

    .hero-stat-value {
      font-family: var(--mono);
      font-size: 0.95rem;
      color: var(--accent);
      font-weight: 700;
    }

    /* ── GRID ──────────────────────────────────────────── */
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(340px, 1fr));
      gap: 1.5rem;
      margin-bottom: 2rem;
    }

    .card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 1.5rem;
    }

    .card-title {
      font-family: var(--mono);
      font-size: 0.7rem;
      color: var(--muted);
      text-transform: uppercase;
      letter-spacing: 0.12em;
      margin-bottom: 1.2rem;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }

    .card-title::after {
      content: '';
      flex: 1;
      height: 1px;
      background: var(--border);
    }

    /* ── REQUEST COUNTER ─────────────────────────────── */
    .counter-wrap {
      text-align: center;
      padding: 1rem 0;
    }

    .counter-number {
      font-family: var(--mono);
      font-size: 4rem;
      font-weight: 700;
      color: var(--accent);
      line-height: 1;
      text-shadow: 0 0 40px rgba(0,212,255,0.4);
    }

    .counter-label {
      font-size: 0.8rem;
      color: var(--muted);
      margin-top: 0.5rem;
    }

    .counter-note {
      font-size: 0.75rem;
      color: var(--yellow);
      margin-top: 1rem;
      font-family: var(--mono);
      background: rgba(245,158,11,0.08);
      border: 1px solid rgba(245,158,11,0.2);
      border-radius: 6px;
      padding: 0.5rem 0.75rem;
    }

    /* ── KV TABLE ────────────────────────────────────── */
    .kv-row {
      display: flex;
      align-items: baseline;
      gap: 0.75rem;
      padding: 0.55rem 0;
      border-bottom: 1px solid var(--border);
      font-family: var(--mono);
      font-size: 0.8rem;
    }

    .kv-row:last-child { border-bottom: none; }

    .kv-key {
      color: var(--muted);
      min-width: 120px;
      flex-shrink: 0;
    }

    .kv-val {
      color: var(--text);
      word-break: break-all;
    }

    .kv-val.green  { color: var(--green); }
    .kv-val.yellow { color: var(--yellow); }
    .kv-val.accent { color: var(--accent); }
    .kv-val.red    { color: var(--red); }

    /* ── CONFIG FILE ─────────────────────────────────── */
    .config-file {
      background: #060b14;
      border: 1px solid var(--border);
      border-left: 3px solid var(--accent2);
      border-radius: 6px;
      padding: 1rem;
      font-family: var(--mono);
      font-size: 0.75rem;
      color: #94a3b8;
      white-space: pre-wrap;
      word-break: break-word;
    }

    /* ── STATUS PILLS ───────────────────────────────── */
    .pill-row {
      display: flex;
      flex-wrap: wrap;
      gap: 0.5rem;
      margin-top: 0.5rem;
    }

    .pill {
      display: inline-flex;
      align-items: center;
      gap: 0.3rem;
      padding: 0.3rem 0.7rem;
      border-radius: 999px;
      font-size: 0.72rem;
      font-family: var(--mono);
      font-weight: 700;
    }

    .pill.green  { background: rgba(16,185,129,0.12); color: var(--green);  border: 1px solid rgba(16,185,129,0.3); }
    .pill.blue   { background: rgba(0,212,255,0.1);   color: var(--accent); border: 1px solid rgba(0,212,255,0.25); }
    .pill.purple { background: rgba(124,58,237,0.12); color: #a78bfa;       border: 1px solid rgba(124,58,237,0.3); }
    .pill.yellow { background: rgba(245,158,11,0.1);  color: var(--yellow); border: 1px solid rgba(245,158,11,0.25); }

    /* ── UPTIME BAR ──────────────────────────────────── */
    .uptime-bar {
      height: 6px;
      background: var(--border);
      border-radius: 999px;
      margin-top: 0.75rem;
      overflow: hidden;
    }

    .uptime-fill {
      height: 100%;
      background: linear-gradient(90deg, var(--green), var(--accent));
      border-radius: 999px;
      width: 100%;
      animation: pulse-bar 2s ease-in-out infinite;
    }

    @keyframes pulse-bar {
      0%, 100% { opacity: 1; }
      50%       { opacity: 0.7; }
    }

    /* ── REFRESH HINT ────────────────────────────────── */
    .refresh-banner {
      background: rgba(0,212,255,0.05);
      border: 1px solid rgba(0,212,255,0.15);
      border-radius: 10px;
      padding: 1.2rem 1.5rem;
      display: flex;
      align-items: center;
      gap: 1rem;
      margin-bottom: 2rem;
    }

    .refresh-icon { font-size: 1.5rem; flex-shrink: 0; }

    .refresh-text strong { color: var(--accent); }

    .refresh-text {
      font-size: 0.85rem;
      color: var(--muted);
      line-height: 1.5;
    }

    footer {
      margin-top: 2rem;
      padding-top: 1.5rem;
      border-top: 1px solid var(--border);
      font-family: var(--mono);
      font-size: 0.72rem;
      color: var(--muted);
      display: flex;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 0.5rem;
    }

    /* ── AUTO REFRESH ────────────────────────────────── */
    .refresh-btn {
      background: var(--accent);
      color: var(--bg);
      border: none;
      border-radius: 6px;
      padding: 0.4rem 1rem;
      font-family: var(--mono);
      font-size: 0.8rem;
      font-weight: 700;
      cursor: pointer;
      transition: opacity 0.2s;
    }
    .refresh-btn:hover { opacity: 0.85; }
  </style>
</head>
<body>

  <header>
    <div class="logo">☸</div>
    <div>
      <h1>K8s <span>Workshop</span> — Live Demo</h1>
      <div style="font-size:0.8rem; color:var(--muted); margin-top:0.2rem;">SCaLE Linux Expo · Kubernetes for Beginners</div>
    </div>
    <div class="version-badge">v${config.appVersion}</div>
  </header>

  <!-- ── WHO AM I? ── -->
  <div class="hero">
    <div class="hero-label">⚡ You are talking to this Pod</div>
    <div class="pod-name">${os.hostname()}</div>
    <div class="hero-grid">
      <div class="hero-stat">
        <div class="hero-stat-label">Namespace</div>
        <div class="hero-stat-value">${process.env.POD_NAMESPACE || 'workshop-app'}</div>
      </div>
      <div class="hero-stat">
        <div class="hero-stat-label">Pod IP</div>
        <div class="hero-stat-value">${process.env.POD_IP || getLocalIP()}</div>
      </div>
      <div class="hero-stat">
        <div class="hero-stat-label">Node</div>
        <div class="hero-stat-value">${process.env.NODE_NAME || 'workshop-control-plane'}</div>
      </div>
      <div class="hero-stat">
        <div class="hero-stat-label">Uptime</div>
        <div class="hero-stat-value">${getUptime()}</div>
      </div>
    </div>
  </div>

  <!-- ── REFRESH BANNER ── -->
  <div class="refresh-banner">
    <div class="refresh-icon">🔄</div>
    <div class="refresh-text">
      <strong>Hit refresh a few times!</strong> The Pod Name above will change as Kubernetes load-balances
      your requests across multiple replicas. Each Pod tracks its own request count below — watch them climb independently.
    </div>
    <button class="refresh-btn" onclick="location.reload()">Refresh</button>
  </div>

  <div class="grid">

    <!-- ── REQUEST COUNTER ── -->
    <div class="card">
      <div class="card-title">📊 This Pod's Request Counter</div>
      <div class="counter-wrap">
        <div class="counter-number">${requestCount}</div>
        <div class="counter-label">requests handled by <strong style="color:var(--accent)">${os.hostname()}</strong></div>
        <div class="counter-note">
          💡 Each pod has its own counter. Reload and watch a DIFFERENT pod's counter go up — that's load balancing!
        </div>
      </div>
    </div>

    <!-- ── K8S STATUS ── -->
    <div class="card">
      <div class="card-title">☸ Kubernetes Status</div>
      <div class="pill-row" style="margin-bottom:1rem">
        <span class="pill green">● Running</span>
        <span class="pill blue">🐳 Containerized</span>
        <span class="pill purple">⚖ Load Balanced</span>
        <span class="pill yellow">🔀 Behind Ingress</span>
      </div>
      <div class="kv-row">
        <span class="kv-key">Environment</span>
        <span class="kv-val green">${config.appEnv}</span>
      </div>
      <div class="kv-row">
        <span class="kv-key">App Version</span>
        <span class="kv-val accent">${config.appVersion}</span>
      </div>
      <div class="kv-row">
        <span class="kv-key">Log Level</span>
        <span class="kv-val yellow">${config.logLevel}</span>
      </div>
      <div class="kv-row">
        <span class="kv-key">New UI Feature</span>
        <span class="kv-val ${config.featureNewUI === 'true' ? 'green' : 'red'}">${config.featureNewUI === 'true' ? '✅ enabled' : '❌ disabled'}</span>
      </div>
      <div class="uptime-bar"><div class="uptime-fill"></div></div>
    </div>

    <!-- ── CONFIGMAP VALUES ── -->
    <div class="card">
      <div class="card-title">⚙️ ConfigMap — Env Vars</div>
      <div class="kv-row">
        <span class="kv-key">APP_ENV</span>
        <span class="kv-val accent">${config.appEnv}</span>
      </div>
      <div class="kv-row">
        <span class="kv-key">LOG_LEVEL</span>
        <span class="kv-val accent">${config.logLevel}</span>
      </div>
      <div class="kv-row">
        <span class="kv-key">FEATURE_NEW_UI</span>
        <span class="kv-val accent">${config.featureNewUI}</span>
      </div>
      <div class="kv-row" style="margin-top:0.5rem; padding-top:0.5rem; border-top: 1px dashed var(--border)">
        <span class="kv-key" style="color:var(--red)">🔐 DB_PASSWORD</span>
        <span class="kv-val yellow">${config.dbPassword}</span>
      </div>
      <div class="kv-row">
        <span class="kv-key" style="color:var(--red)">🔐 API_KEY</span>
        <span class="kv-val yellow">${config.apiKey}</span>
      </div>
    </div>

    <!-- ── MOUNTED CONFIG FILE ── -->
    <div class="card">
      <div class="card-title">📄 ConfigMap — Mounted File (/etc/config/app.properties)</div>
      ${mountedConfig
        ? `<div class="config-file">${mountedConfig}</div>`
        : `<div class="config-file" style="color:var(--muted)">File not mounted yet.\n\nApply deployment-with-config.yaml\nto see this populate:\n\n  kubectl apply -f manifests/deployment-with-config.yaml</div>`
      }
    </div>

  </div>

  <footer>
    <span>Pod: ${os.hostname()} · Node.js ${process.version} · PID ${process.pid}</span>
    <span>Started: ${startTime.toISOString()}</span>
  </footer>

</body>
</html>`;

function getLocalIP() {
  const ifaces = os.networkInterfaces();
  for (const name of Object.keys(ifaces)) {
    for (const iface of ifaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) return iface.address;
    }
  }
  return '127.0.0.1';
}

function getUptime() {
  const secs = Math.floor((Date.now() - startTime) / 1000);
  if (secs < 60)   return `${secs}s`;
  if (secs < 3600) return `${Math.floor(secs/60)}m ${secs%60}s`;
  return `${Math.floor(secs/3600)}h ${Math.floor((secs%3600)/60)}m`;
}

// ── Server ──────────────────────────────────────────────────────────────────
const server = http.createServer((req, res) => {
  // Health endpoints (don't count toward request total)
  if (req.url === '/health' || req.url === '/healthz') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', pod: os.hostname(), uptime: getUptime() }));
    return;
  }

  // JSON API for live polling
  if (req.url === '/api/info') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      pod:       os.hostname(),
      namespace: process.env.POD_NAMESPACE || 'workshop-app',
      podIP:     process.env.POD_IP || getLocalIP(),
      node:      process.env.NODE_NAME || 'workshop-control-plane',
      requests:  requestCount,
      uptime:    getUptime(),
      version:   config.appVersion,
      env:       config.appEnv,
    }));
    return;
  }

  // Main page
  requestCount++;
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url} — pod: ${os.hostname()} — req #${requestCount}`);

  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end(html());
});

server.listen(PORT, () => {
  console.log(`☸  Workshop demo app running on port ${PORT}`);
  console.log(`   Pod: ${os.hostname()}`);
  console.log(`   Env: ${config.appEnv} | Version: ${config.appVersion}`);
});
