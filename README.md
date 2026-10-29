# Xeriox Installer

**Multi-Panel Installer with Own Branding**

One installer to install multiple panels on your server:

- Game Panel (Pterodactyl)
- Web Panel (HestiaCP)
- Bot Panel (Mechon)
- Xeriox Admin Panel (Central Control Center)

---

## Quick Install

```bash
bash <(curl -s https://raw.githubusercontent.com/YOUR_USERNAME/xeriox-installer/main/install.sh)
```

Or manual way:

```bash
git clone https://github.com/YOUR_USERNAME/xeriox-installer.git
cd xeriox-installer
chmod +x install.sh
sudo bash install.sh
```

---

## Features

- Clean branded menu
- Domain support for every panel
- Install single or multiple panels
- **Xeriox Admin Panel** — central control panel
  - Start / Stop / Restart services
  - Customize brand name & colors
  - View installed panels

---

## Menu Options

| Option | What it installs          |
|--------|---------------------------|
| 1      | Game Panel (Pterodactyl)  |
| 2      | Web Panel (HestiaCP)      |
| 3      | Bot Panel (Mechon)        |
| 4      | VPS Panel (Coming Soon)   |
| 5      | Xeriox Admin Panel        |
| 6      | Install Multiple Panels   |
| 0      | Exit                      |

---

## Xeriox Admin Panel

After installing option **[5]**:

- Access: `http://admin.yourdomain.com` or `http://YOUR_IP:3080`
- Default login is the username & password you set during install
- You can start/stop Nginx, Docker, MySQL, Redis
- Change theme colors and brand name

Service commands:

```bash
systemctl status xeriox-admin
systemctl restart xeriox-admin
systemctl stop xeriox-admin
```

---

## Requirements

- Ubuntu 22.04 / 24.04 or Debian 12 (recommended)
- Root access
- Fresh server is best

---

## Folder Structure

```
xeriox-installer/
├── install.sh              # Main installer
├── README.md
└── admin-panel/
    ├── package.json
    └── server.js           # Admin panel source
```

---

## License

You can use, modify and publish this freely.

---

Made with ❤️ for the community
