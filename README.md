# Wake on WAN Project

A simple system to remotely wake up your computer.

## Architecture
- **PC1**: Target computer (Sleeps).
- **LAP1 (Server)**: Always-on device running the Python Server.
- **MOBILE1 (Client)**: Phone running the Flutter App.

## Setup

### Server Setup

**Option 1: Run Manually (Testing)**
1.  `cd server`
2.  `pip install -r requirements.txt`
3.  `python main.py`

**Option 2: Run as a Service (Ubuntu/Linux - Recommended)**
This ensures the server runs automatically in the background and restarts on boot.

1.  Copy the `server/` folder to your Ubuntu machine (e.g., `/opt/wake_on_wan_server`).
2.  Install dependencies:
    ```bash
    sudo apt update && sudo apt install python3-pip -y
    cd /opt/wake_on_wan_server
    sudo pip3 install -r requirements.txt
    ```
3.  Setup Systemd Service:
    ```bash
    # Copy service file
    sudo cp wake_on_wan.service /etc/systemd/system/
    
    # Reload and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable wake_on_wan
    sudo systemctl start wake_on_wan
    ```
4.  Check status: `sudo systemctl status wake_on_wan`


### Client
1.  `cd client`
2.  `flutter create .` (To regenerate platform files)
3.  `flutter pub get`
4.  `flutter run`

## Configuration
Inside the mobile app:
- **Server IP**: IP address of LAP1.
  - If on Local Network: Use local IP (e.g., `192.168.1.5`).
  - **If using Tailscale**: Use Tailscale IP (e.g., `100.x.y.z`).
- **Server Port**: `8000`.
- **MAC Address**: Physical address of PC1.

## Remote Access (Tailscale) - Recommended
Instead of opening ports on your router, use **Tailscale** to create a secure private network.

### 1. Install on Server (Ubuntu)
```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Authenticate (Follow the link provided in terminal)
sudo tailscale up
```
After installation, run `ip addr show tailscale0` to get the **Tailscale IP** (starts with `100.`).

### 2. Install on Phone
1.  Download **Tailscale** app from App Store / Play Store.
2.  Login with the same account.
3.  Turn **On** the VPN switch.
4.  In the Wake on WAN app, enter the **Tailscale IP** of the server.

