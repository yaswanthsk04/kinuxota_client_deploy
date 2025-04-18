# Kinuxota OTA Client

Kinuxota is a client application that enables remote management and over-the-air updates for Ubuntu devices.

## Installation

### Using the Install Script (Recommended)

#### Using `wget`:

```bash
wget -O install.sh https://raw.githubusercontent.com/yaswanthsk04/kinuxota_client_deploy/main/download
chmod +x install.sh
sudo ./install.sh
```

#### Or using `curl`:

```bash
curl -o install.sh https://raw.githubusercontent.com/yaswanthsk04/kinuxota_client_deploy/main/download
chmod +x install.sh
sudo ./install.sh
```

## Configuration

After installation, configure the client:

```bash
sudo kinuxctl configure
```

## Managing the Service

```bash
# Check service status
sudo systemctl status kinuxota

# Restart the service
sudo systemctl restart kinuxota

# Stop the service
sudo systemctl stop kinuxota
```

## Features

- Remote device management
- Over-the-air (OTA) updates
- Command-line utility (`kinuxctl`) for local management
- Systemd service for automatic startup

## File Locations

- **Configuration:** `/etc/kinuxota/config.json`
- **Logs:** `/var/log/kinuxota/`
- **Updates:** `/var/lib/kinuxota/updates/`
- **Binaries:** `/usr/local/bin/`

## Support

For support, please open an issue on this repository.
