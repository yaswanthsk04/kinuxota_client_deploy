#!/bin/bash
set -e

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# GitHub repository URL
REPO_URL="https://github.com/yaswanthsk04/kinuxota_client_deploy"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "${GREEN}Kinuxota Client Runner${NC}"
echo "This script will set up necessary permissions and run the Kinuxota client."
echo -e "${YELLOW}You will be asked for your sudo password for setup.${NC}"
echo ""

# Function to download binaries from GitHub
download_binaries() {
    echo -e "${YELLOW}Checking for required binaries...${NC}"
    
    # Check if binaries exist and are executable
    if [ ! -f "$SCRIPT_DIR/kinuxota_client" ] || [ ! -x "$SCRIPT_DIR/kinuxota_client" ] || \
       [ ! -f "$SCRIPT_DIR/kinuxctl" ] || [ ! -x "$SCRIPT_DIR/kinuxctl" ]; then
        
        echo -e "${YELLOW}Downloading binaries from GitHub repository...${NC}"
        
        # Create temporary download directory
        DOWNLOAD_DIR="/tmp/kinuxota_download"
        mkdir -p "$DOWNLOAD_DIR"
        cd "$DOWNLOAD_DIR"
        
        # Download the binaries
        if command -v curl &> /dev/null; then
            # Use curl if available
            echo -e "${YELLOW}Using curl to download binaries...${NC}"
            curl -L "$REPO_URL/raw/main/kinuxota_client" -o kinuxota_client
            curl -L "$REPO_URL/raw/main/kinuxctl" -o kinuxctl
            # Check if kinuxupdator exists in the repo
            if curl -L "$REPO_URL/raw/main/kinuxupdator" -o kinuxupdator --fail 2>/dev/null; then
                echo -e "${GREEN}Downloaded kinuxupdator successfully.${NC}"
            else
                echo -e "${YELLOW}kinuxupdator not found in the repository.${NC}"
            fi
        elif command -v wget &> /dev/null; then
            # Use wget if curl is not available
            echo -e "${YELLOW}Using wget to download binaries...${NC}"
            wget "$REPO_URL/raw/main/kinuxota_client" -O kinuxota_client
            wget "$REPO_URL/raw/main/kinuxctl" -O kinuxctl
            # Check if kinuxupdator exists in the repo
            if wget "$REPO_URL/raw/main/kinuxupdator" -O kinuxupdator 2>/dev/null; then
                echo -e "${GREEN}Downloaded kinuxupdator successfully.${NC}"
            else
                echo -e "${YELLOW}kinuxupdator not found in the repository.${NC}"
                rm -f kinuxupdator
            fi
        else
            echo -e "${RED}Neither curl nor wget is installed. Cannot download binaries.${NC}"
            echo "Please install curl or wget and try again."
            exit 1
        fi
        
        # Make binaries executable
        echo -e "${YELLOW}Making binaries executable...${NC}"
        chmod +x kinuxota_client
        chmod +x kinuxctl
        if [ -f kinuxupdator ]; then
            chmod +x kinuxupdator
        fi
        
        # Copy binaries to the script directory
        echo -e "${YELLOW}Copying binaries to $SCRIPT_DIR...${NC}"
        cp kinuxota_client "$SCRIPT_DIR/"
        cp kinuxctl "$SCRIPT_DIR/"
        if [ -f kinuxupdator ]; then
            cp kinuxupdator "$SCRIPT_DIR/"
        fi
        
        # Clean up
        echo -e "${YELLOW}Cleaning up temporary files...${NC}"
        cd "$SCRIPT_DIR"
        rm -rf "$DOWNLOAD_DIR"
        
        echo -e "${GREEN}Binaries downloaded and installed successfully.${NC}"
    else
        echo -e "${GREEN}All required binaries are present.${NC}"
    fi
}

# Function to set up the environment (directories, permissions, etc.)
setup_environment() {
    echo -e "${YELLOW}Setting up KinuxOTA client environment...${NC}"
    
    # Ask for sudo password once and keep it alive for the duration of the script
    sudo -v
    # Keep sudo alive until the script finishes
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    
    # Check if running in WSL
    if grep -q Microsoft /proc/version; then
        echo -e "${YELLOW}Detected Windows Subsystem for Linux (WSL) environment.${NC}"
        
        # Mount the kinuxota_client binaries directory if not already mounted
        if ! mountpoint -q /mnt/kinuxota_binaries 2>/dev/null; then
            echo -e "${YELLOW}Mounting kinuxota_client binaries directory...${NC}"
            sudo mkdir -p /mnt/kinuxota_binaries
            sudo mount --bind "$SCRIPT_DIR" /mnt/kinuxota_binaries
            echo -e "${GREEN}Binaries directory mounted successfully.${NC}"
        else
            echo -e "${GREEN}Binaries directory already mounted.${NC}"
        fi
    else
        echo -e "${YELLOW}Running in standard Ubuntu environment.${NC}"
    fi
    
    # Create necessary directories with proper permissions
    echo -e "${YELLOW}Creating necessary directories with proper permissions...${NC}"
    sudo mkdir -p /var/log/kinuxota
    sudo chmod 755 /var/log/kinuxota
    sudo chown $(whoami):$(whoami) /var/log/kinuxota
    echo -e "${GREEN}Log directory created with proper permissions.${NC}"
    
    # Create config directory if it doesn't exist
    sudo mkdir -p /etc/kinuxota
    sudo chmod 755 /etc/kinuxota
    sudo chown $(whoami):$(whoami) /etc/kinuxota
    echo -e "${GREEN}Config directory created with proper permissions.${NC}"
    
    # Create updates directory if it doesn't exist
    sudo mkdir -p /var/lib/kinuxota/updates
    sudo chmod 755 /var/lib/kinuxota/updates
    sudo chown $(whoami):$(whoami) /var/lib/kinuxota/updates
    echo -e "${GREEN}Updates directory created with proper permissions.${NC}"
    
    # Set up passwordless sudo for package management
    echo -e "${YELLOW}Setting up passwordless sudo for package management...${NC}"
    
    # Detect package managers on the system
    PACKAGE_MANAGERS=""
    
    # Check for common package managers
    if command -v apt-get &> /dev/null; then
        PACKAGE_MANAGERS="$PACKAGE_MANAGERS /usr/bin/apt-get, /usr/bin/apt,"
    fi
    if command -v yum &> /dev/null; then
        PACKAGE_MANAGERS="$PACKAGE_MANAGERS /usr/bin/yum,"
    fi
    if command -v dnf &> /dev/null; then
        PACKAGE_MANAGERS="$PACKAGE_MANAGERS /usr/bin/dnf,"
    fi
    if command -v pacman &> /dev/null; then
        PACKAGE_MANAGERS="$PACKAGE_MANAGERS /usr/bin/pacman,"
    fi
    if command -v apk &> /dev/null; then
        PACKAGE_MANAGERS="$PACKAGE_MANAGERS /usr/bin/apk,"
    fi
    if command -v zypper &> /dev/null; then
        PACKAGE_MANAGERS="$PACKAGE_MANAGERS /usr/bin/zypper,"
    fi
    
    # Remove trailing comma
    PACKAGE_MANAGERS=${PACKAGE_MANAGERS%,}
    
    if [ -z "$PACKAGE_MANAGERS" ]; then
        echo -e "${RED}No package managers detected on the system.${NC}"
        echo "Passwordless sudo configuration will not be set up."
    else
        echo -e "Detected package managers: ${GREEN}$PACKAGE_MANAGERS${NC}"
    
        # Create sudoers file for Kinuxota
        CURRENT_USER=$(whoami)
        SUDOERS_CONTENT="# Allow Kinuxota client to run package management commands without password\n$CURRENT_USER ALL=(ALL) NOPASSWD: $PACKAGE_MANAGERS"
    
        # Create the sudoers file
        echo -e "$SUDOERS_CONTENT" | sudo tee /etc/sudoers.d/kinuxota > /dev/null
    
        # Set proper permissions
        sudo chmod 440 /etc/sudoers.d/kinuxota
    
        echo -e "${GREEN}Passwordless sudo configured successfully.${NC}"
    
        # Test the configuration
        echo "Testing passwordless sudo configuration..."
        if sudo -n true 2>/dev/null; then
            echo -e "${GREEN}Passwordless sudo is working correctly.${NC}"
        else
            echo -e "${RED}Passwordless sudo configuration failed. Please check /etc/sudoers.d/kinuxota${NC}"
        fi
    fi
}

# Download binaries if needed
download_binaries

# Set up the environment
setup_environment

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
