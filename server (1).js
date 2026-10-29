const express = require('express');
const bodyParser = require('body-parser');
const session = require('express-session');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3080;
const CONFIG_FILE = path.join(__dirname, 'config.json');

const defaultConfig = {
  brandName: "Xeriox",
  primaryColor: "#0ea5e9",
  secondaryColor: "#1e293b",
  accentColor: "#22c55e",
  theme: "dark",
  panels: {
    game: { name: "Game Panel", service: "nginx", enabled: true, domain: "game.example.com" },
    web: { name: "Web Panel", service: "hestia", enabled: true, domain: "web.example.com" },
    bot: { name: "Bot Panel", service: "docker", enabled: true, domain: "bot.example.com" }
  },
  adminUser: "admin",
  adminPass: "xeriox123"
};

function loadConfig() {
  try {
    if (fs.existsSync(CONFIG_FILE)) {
      return JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
    }
  } catch (e) {}
  fs.writeFileSync(CONFIG_FILE, JSON.stringify(defaultConfig, null, 2));
  return defaultConfig;
}

function saveConfig(config) {
  fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
}

let config = loadConfig();

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(session({
  secret: 'xeriox-secret-key-change-me',
  resave: false,
  saveUninitialized: true,
  cookie: { maxAge: 24 * 60 * 60 * 1000 }
}));

function requireAuth(req, res, next) {
  if (req.session && req.session.loggedIn) return next();
  res.redirect('/login');
}

app.get('/login', (req, res) => {
  if (req.session.loggedIn) return res.redirect('/');
  res.send(getLoginHTML());
});

app.post('/login', (req, res) => {
  const { username, password } = req.body;
  if (username === config.adminUser && password === config.adminPass) {
    req.session.loggedIn = true;
    return res.redirect('/');
  }
  res.send(getLoginHTML('Invalid username or password'));
});

app.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/login');
});

app.get('/', requireAuth, (req, res) => {
  res.send(getDashboardHTML(config));
});

app.get('/api/status', requireAuth, (req, res) => {
  const statuses = {};
  const checks = [
    { key: 'nginx', cmd: 'systemctl is-active nginx' },
    { key: 'docker', cmd: 'systemctl is-active docker' },
    { key: 'mysql', cmd: 'systemctl is-active mysql || systemctl is-active mariadb' },
    { key: 'redis', cmd: 'systemctl is-active redis || systemctl is-active redis-server' }
  ];
  let completed = 0;
  checks.forEach(check => {
    exec(check.cmd, (err, stdout) => {
      statuses[check.key] = (stdout || '').trim() === 'active' ? 'running' : 'stopped';
      completed++;
      if (completed === checks.length) res.json(statuses);
    });
  });
});

app.post('/api/service', requireAuth, (req, res) => {
  const { service, action } = req.body;
  if (!['start', 'stop', 'restart'].includes(action)) {
    return res.status(400).json({ error: 'Invalid action' });
  }
  const allowed = ['nginx', 'docker', 'mysql', 'mariadb', 'redis', 'redis-server', 'wings', 'pteroq'];
  if (!allowed.includes(service)) {
    return res.status(400).json({ error: 'Service not allowed' });
  }
  exec(`systemctl ${action} ${service}`, (err) => {
    if (err) return res.json({ success: false, message: err.message });
    res.json({ success: true, message: `${service} ${action}ed successfully` });
  });
});

app.post('/api/theme', requireAuth, (req, res) => {
  const { primaryColor, secondaryColor, accentColor, theme, brandName } = req.body;
  if (primaryColor) config.primaryColor = primaryColor;
  if (secondaryColor) config.secondaryColor = secondaryColor;
  if (accentColor) config.accentColor = accentColor;
  if (theme) config.theme = theme;
  if (brandName) config.brandName = brandName;
  saveConfig(config);
  res.json({ success: true, config });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Xeriox Admin Panel running on port ${PORT}`);
});

function getLoginHTML(error = '') {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Login - Xeriox Admin</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Segoe UI', system-ui, sans-serif; background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; color: #e2e8f0; }
    .login-box { background: #1e293b; padding: 40px; border-radius: 16px; width: 100%; max-width: 400px; box-shadow: 0 20px 60px rgba(0,0,0,0.4); border: 1px solid #334155; }
    h1 { text-align: center; margin-bottom: 8px; color: #0ea5e9; font-size: 28px; }
    .subtitle { text-align: center; color: #94a3b8; margin-bottom: 30px; font-size: 14px; }
    .form-group { margin-bottom: 20px; }
    label { display: block; margin-bottom: 6px; font-size: 14px; color: #94a3b8; }
    input { width: 100%; padding: 12px 16px; border: 1px solid #334155; border-radius: 8px; background: #0f172a; color: #e2e8f0; font-size: 15px; }
    input:focus { outline: none; border-color: #0ea5e9; }
    button { width: 100%; padding: 14px; background: #0ea5e9; color: white; border: none; border-radius: 8px; font-size: 16px; font-weight: 600; cursor: pointer; }
    button:hover { background: #0284c7; }
    .error { background: #7f1d1d; color: #fecaca; padding: 12px; border-radius: 8px; margin-bottom: 20px; text-align: center; font-size: 14px; }
  </style>
</head>
<body>
  <div class="login-box">
    <h1>Xeriox</h1>
    <p class="subtitle">Admin Control Panel</p>
    ${error ? `<div class="error">${error}</div>` : ''}
    <form method="POST" action="/login">
      <div class="form-group"><label>Username</label><input type="text" name="username" required autofocus></div>
      <div class="form-group"><label>Password</label><input type="password" name="password" required></div>
      <button type="submit">Login</button>
    </form>
  </div>
</body>
</html>`;
}

function getDashboardHTML(config) {
  const primary = config.primaryColor || '#0ea5e9';
  const secondary = config.secondaryColor || '#1e293b';
  const accent = config.accentColor || '#22c55e';

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${config.brandName} Admin Panel</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Segoe UI', system-ui, sans-serif; background: #0f172a; color: #e2e8f0; min-height: 100vh; }
    .header { background: ${secondary}; padding: 16px 32px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #334155; }
    .header h1 { color: ${primary}; font-size: 22px; }
    .header a { color: #94a3b8; text-decoration: none; font-size: 14px; }
    .header a:hover { color: ${primary}; }
    .container { max-width: 1100px; margin: 0 auto; padding: 32px 20px; }
    .section { margin-bottom: 40px; }
    .section h2 { font-size: 18px; margin-bottom: 16px; color: ${primary}; border-bottom: 1px solid #334155; padding-bottom: 8px; }
    .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 16px; }
    .card { background: ${secondary}; border: 1px solid #334155; border-radius: 12px; padding: 20px; }
    .card h3 { font-size: 16px; margin-bottom: 8px; }
    .card .domain { font-size: 13px; color: #94a3b8; margin-bottom: 16px; }
    .status { display: inline-block; padding: 4px 10px; border-radius: 20px; font-size: 12px; font-weight: 600; margin-bottom: 12px; }
    .status.running { background: #14532d; color: #86efac; }
    .status.stopped { background: #7f1d1d; color: #fca5a5; }
    .btn-group { display: flex; gap: 8px; flex-wrap: wrap; }
    .btn { padding: 8px 14px; border: none; border-radius: 6px; font-size: 13px; cursor: pointer; font-weight: 500; }
    .btn:hover { opacity: 0.85; }
    .btn-start { background: ${accent}; color: #052e16; }
    .btn-stop { background: #ef4444; color: white; }
    .btn-restart { background: #f59e0b; color: #1c1917; }
    .theme-form { background: ${secondary}; border: 1px solid #334155; border-radius: 12px; padding: 24px; display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; }
    .theme-form label { display: block; font-size: 13px; color: #94a3b8; margin-bottom: 6px; }
    .theme-form input[type="color"], .theme-form input[type="text"] { width: 100%; padding: 10px; border: 1px solid #334155; border-radius: 6px; background: #0f172a; color: #e2e8f0; }
    .theme-form button { grid-column: 1 / -1; padding: 12px; background: ${primary}; color: white; border: none; border-radius: 8px; font-weight: 600; cursor: pointer; margin-top: 8px; }
    .msg { margin-top: 12px; padding: 10px; border-radius: 6px; font-size: 14px; display: none; }
    .msg.success { background: #14532d; color: #86efac; display: block; }
    .msg.error { background: #7f1d1d; color: #fca5a5; display: block; }
  </style>
</head>
<body>
  <div class="header">
    <h1>${config.brandName} Admin</h1>
    <a href="/logout">Logout</a>
  </div>
  <div class="container">
    <div class="section">
      <h2>Service Control</h2>
      <div class="cards">
        <div class="card"><h3>Nginx</h3><div class="status" id="status-nginx">checking...</div>
          <div class="btn-group">
            <button class="btn btn-start" onclick="control('nginx','start')">Start</button>
            <button class="btn btn-stop" onclick="control('nginx','stop')">Stop</button>
            <button class="btn btn-restart" onclick="control('nginx','restart')">Restart</button>
          </div>
        </div>
        <div class="card"><h3>Docker</h3><div class="status" id="status-docker">checking...</div>
          <div class="btn-group">
            <button class="btn btn-start" onclick="control('docker','start')">Start</button>
            <button class="btn btn-stop" onclick="control('docker','stop')">Stop</button>
            <button class="btn btn-restart" onclick="control('docker','restart')">Restart</button>
          </div>
        </div>
        <div class="card"><h3>Database</h3><div class="status" id="status-mysql">checking...</div>
          <div class="btn-group">
            <button class="btn btn-start" onclick="control('mysql','start')">Start</button>
            <button class="btn btn-stop" onclick="control('mysql','stop')">Stop</button>
            <button class="btn btn-restart" onclick="control('mysql','restart')">Restart</button>
          </div>
        </div>
        <div class="card"><h3>Redis</h3><div class="status" id="status-redis">checking...</div>
          <div class="btn-group">
            <button class="btn btn-start" onclick="control('redis','start')">Start</button>
            <button class="btn btn-stop" onclick="control('redis','stop')">Stop</button>
            <button class="btn btn-restart" onclick="control('redis','restart')">Restart</button>
          </div>
        </div>
      </div>
      <div id="service-msg" class="msg"></div>
    </div>

    <div class="section">
      <h2>Installed Panels</h2>
      <div class="cards">
        ${Object.entries(config.panels || {}).map(([key, panel]) => `
          <div class="card">
            <h3>${panel.name}</h3>
            <div class="domain">${panel.domain || 'No domain set'}</div>
            <div class="status ${panel.enabled ? 'running' : 'stopped'}">${panel.enabled ? 'Enabled' : 'Disabled'}</div>
          </div>
        `).join('')}
      </div>
    </div>

    <div class="section">
      <h2>Customize Theme & Branding</h2>
      <div class="theme-form">
        <div><label>Brand Name</label><input type="text" id="brandName" value="${config.brandName}"></div>
        <div><label>Primary Color</label><input type="color" id="primaryColor" value="${primary}"></div>
        <div><label>Secondary Color</label><input type="color" id="secondaryColor" value="${secondary}"></div>
        <div><label>Accent Color</label><input type="color" id="accentColor" value="${accent}"></div>
        <button onclick="saveTheme()">Save Theme</button>
      </div>
      <div id="theme-msg" class="msg"></div>
    </div>
  </div>

  <script>
    async function refreshStatus() {
      try {
        const res = await fetch('/api/status');
        const data = await res.json();
        ['nginx','docker','mysql','redis'].forEach(s => {
          const el = document.getElementById('status-' + s);
          if (el) { el.textContent = data[s] || 'stopped'; el.className = 'status ' + (data[s] || 'stopped'); }
        });
      } catch(e) {}
    }
    async function control(service, action) {
      const msg = document.getElementById('service-msg');
      try {
        const res = await fetch('/api/service', { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify({service, action}) });
        const data = await res.json();
        msg.textContent = data.message || (data.success ? 'Done' : 'Failed');
        msg.className = 'msg ' + (data.success ? 'success' : 'error');
        setTimeout(refreshStatus, 1000);
      } catch(e) { msg.textContent = 'Error'; msg.className = 'msg error'; }
    }
    async function saveTheme() {
      const msg = document.getElementById('theme-msg');
      const body = {
        brandName: document.getElementById('brandName').value,
        primaryColor: document.getElementById('primaryColor').value,
        secondaryColor: document.getElementById('secondaryColor').value,
        accentColor: document.getElementById('accentColor').value
      };
      try {
        const res = await fetch('/api/theme', { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(body) });
        const data = await res.json();
        msg.textContent = data.success ? 'Theme saved! Refreshing...' : 'Failed';
        msg.className = 'msg ' + (data.success ? 'success' : 'error');
        if (data.success) setTimeout(() => location.reload(), 800);
      } catch(e) { msg.textContent = 'Error'; msg.className = 'msg error'; }
    }
    refreshStatus();
    setInterval(refreshStatus, 10000);
  </script>
</body>
</html>`;
}
