# KinuxOTA Client

This repository contains the KinuxOTA client, a tool for managing over-the-air updates for Linux systems.

## Prerequisites

- Ubuntu Linux environment (works in both standard Ubuntu and WSL)
- curl or wget (for downloading binaries)
- sudo privileges (for setting up permissions)

## Installation and Usage

### Option 1: One-line Command (Easiest)

```bash
curl -L https://github.com/yaswanthsk04/kinuxota_client_deploy/raw/main/run-client.sh -o run-client.sh && chmod +x run-client.sh && ./run-client.sh
```

To run in detached mode (no console output):
```bash
curl -L https://github.com/yaswanthsk04/kinuxota_client_deploy/raw/main/run-client.sh -o run-client.sh && chmod +x run-client.sh && ./run-client.sh -d
```

### Option 2: Step-by-Step Instructions

1. **Download the run-client.sh script**:
   ```bash
   curl -L https://github.com/yaswanthsk04/kinuxota_client_deploy/raw/main/run-client.sh -o run-client.sh
   ```
   or with wget:
   ```bash
   wget https://github.com/yaswanthsk04/kinuxota_client_deploy/raw/main/run-client.sh
   ```

2. **Make the script executable**:
   ```bash
   chmod +x run-client.sh
   ```

3. **Run the script**:
   ```bash
   ./run-client.sh
   ```

   With detached mode:
   ```bash
   ./run-client.sh -d
   ```

## What the Script Does

When you run the script, it will:

1. Download the required binaries from GitHub if they don't exist locally
2. Set up the necessary directories and permissions
3. Configure passwordless sudo for package management (needed for automated updates)
4. Install the binaries system-wide
5. Run the KinuxOTA client

## Detached Mode

Running the client in detached mode (`-d` flag) disables console output, but the client still logs all information to the log file at `/var/log/kinuxota/`.

This is useful for running the client in the background or as part of automated scripts.
