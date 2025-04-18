#!/bin/bash
set -e

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Kinuxota Client Runner${NC}"
echo "This script will set up necessary permissions and run the Kinuxota client."
echo -e "${YELLOW}You will be asked for your sudo password for setup.${NC}"
echo ""

# Check if wsl-setup.sh exists and is executable
if [ -f "$(dirname "$0")/wsl-setup.sh" ] && [ -x "$(dirname "$0")/wsl-setup.sh" ]; then
    echo -e "${YELLOW}Running setup script to configure permissions...${NC}"
    # Run the setup script
    "$(dirname "$0")/wsl-setup.sh"
else
    echo -e "${RED}Setup script not found or not executable!${NC}"
    echo "Please make sure wsl-setup.sh exists in the same directory as this script and is executable."
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check if kinuxota_client exists and is executable
if [ ! -f "$SCRIPT_DIR/kinuxota_client" ] || [ ! -x "$SCRIPT_DIR/kinuxota_client" ]; then
    echo -e "${RED}kinuxota_client not found or not executable in $SCRIPT_DIR!${NC}"
    echo "Please make sure the client binary exists and is executable."
    exit 1
fi

# Copy binaries to /usr/local/bin if they're not already there
echo -e "${YELLOW}Copying binaries to /usr/local/bin...${NC}"

# Create /usr/local/bin if it doesn't exist
sudo mkdir -p /usr/local/bin

# Copy kinuxota_client if it doesn't already exist in /usr/local/bin
if [ -f "$SCRIPT_DIR/kinuxota_client" ] && [ -x "$SCRIPT_DIR/kinuxota_client" ]; then
    if [ ! -f "/usr/local/bin/kinuxota_client" ] || [ ! -x "/usr/local/bin/kinuxota_client" ]; then
        echo -e "${YELLOW}Copying kinuxota_client to /usr/local/bin...${NC}"
        sudo cp "$SCRIPT_DIR/kinuxota_client" /usr/local/bin/
        sudo chmod +x /usr/local/bin/kinuxota_client
        echo -e "${GREEN}kinuxota_client copied successfully.${NC}"
    else
        # Check if they are the same file (could be a symbolic link)
        if [ "$(readlink -f "$SCRIPT_DIR/kinuxota_client")" != "$(readlink -f "/usr/local/bin/kinuxota_client")" ]; then
            echo -e "${YELLOW}kinuxota_client already exists in /usr/local/bin but is different. Updating...${NC}"
            sudo cp "$SCRIPT_DIR/kinuxota_client" /usr/local/bin/
            sudo chmod +x /usr/local/bin/kinuxota_client
            echo -e "${GREEN}kinuxota_client updated successfully.${NC}"
        else
            echo -e "${GREEN}kinuxota_client already exists in /usr/local/bin.${NC}"
        fi
    fi
else
    echo -e "${RED}kinuxota_client not found or not executable in $SCRIPT_DIR!${NC}"
    echo "Please make sure the client binary exists and is executable."
    exit 1
fi

# Copy kinuxctl if it doesn't already exist in /usr/local/bin
if [ -f "$SCRIPT_DIR/kinuxctl" ] && [ -x "$SCRIPT_DIR/kinuxctl" ]; then
    if [ ! -f "/usr/local/bin/kinuxctl" ] || [ ! -x "/usr/local/bin/kinuxctl" ]; then
        echo -e "${YELLOW}Copying kinuxctl to /usr/local/bin...${NC}"
        sudo cp "$SCRIPT_DIR/kinuxctl" /usr/local/bin/
        sudo chmod +x /usr/local/bin/kinuxctl
        echo -e "${GREEN}kinuxctl copied successfully.${NC}"
    else
        # Always update the file to ensure we have the latest version
        echo -e "${YELLOW}Updating kinuxctl in /usr/local/bin...${NC}"
        sudo cp "$SCRIPT_DIR/kinuxctl" /usr/local/bin/
        sudo chmod +x /usr/local/bin/kinuxctl
        echo -e "${GREEN}kinuxctl updated successfully.${NC}"
    fi
else
    echo -e "${YELLOW}kinuxctl not found or not executable in $SCRIPT_DIR!${NC}"
    echo -e "${YELLOW}kinuxctl utility will not be available.${NC}"
fi

# Copy kinuxupdator if it doesn't already exist in /usr/local/bin
if [ -f "$SCRIPT_DIR/kinuxupdator" ] && [ -x "$SCRIPT_DIR/kinuxupdator" ]; then
    if [ ! -f "/usr/local/bin/kinuxupdator" ] || [ ! -x "/usr/local/bin/kinuxupdator" ]; then
        echo -e "${YELLOW}Copying kinuxupdator to /usr/local/bin...${NC}"
        sudo cp "$SCRIPT_DIR/kinuxupdator" /usr/local/bin/
        sudo chmod +x /usr/local/bin/kinuxupdator
        echo -e "${GREEN}kinuxupdator copied successfully.${NC}"
    else
        # Always update the file to ensure we have the latest version
        echo -e "${YELLOW}Updating kinuxupdator in /usr/local/bin...${NC}"
        sudo cp "$SCRIPT_DIR/kinuxupdator" /usr/local/bin/
        sudo chmod +x /usr/local/bin/kinuxupdator
        echo -e "${GREEN}kinuxupdator updated successfully.${NC}"
    fi
else
    echo -e "${YELLOW}kinuxupdator not found or not executable in $SCRIPT_DIR!${NC}"
    echo -e "${YELLOW}The update functionality may not work properly.${NC}"
fi

# Check if kinuxupdator exists in /usr/local/bin and copy it back to the script directory
# This ensures the client can find it in the same directory
if [ -f "/usr/local/bin/kinuxupdator" ] && [ -x "/usr/local/bin/kinuxupdator" ]; then
    if [ ! -f "$SCRIPT_DIR/kinuxupdator" ] || [ ! -x "$SCRIPT_DIR/kinuxupdator" ]; then
        echo -e "${YELLOW}Copying kinuxupdator from /usr/local/bin to $SCRIPT_DIR...${NC}"
        cp "/usr/local/bin/kinuxupdator" "$SCRIPT_DIR/"
        chmod +x "$SCRIPT_DIR/kinuxupdator"
        echo -e "${GREEN}kinuxupdator copied successfully.${NC}"
    fi
fi

# Parse command line arguments
SERVER_ADDRESS="http://172.25.176.1:4002"
DETACHED_MODE=false

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--detached)
            DETACHED_MODE=true
            shift
            ;;
        *)
            # Assume it's the server address
            SERVER_ADDRESS="$1"
            shift
            ;;
    esac
done

echo -e "${YELLOW}Starting Kinuxota client with server: ${GREEN}$SERVER_ADDRESS${NC}"
if [ "$DETACHED_MODE" = true ]; then
    echo -e "${YELLOW}Running in detached mode (no console output)${NC}"
fi

# Run the client with the specified server address and detached mode if requested
if [ "$DETACHED_MODE" = true ]; then
    cd "$SCRIPT_DIR" && ./kinuxota_client -d
else
    cd "$SCRIPT_DIR" && ./kinuxota_client
fi

# Note: The script will exit with the same exit code as the client
exit $?
