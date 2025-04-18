#!/bin/bash
set -e

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Kinuxota Client Installer (GitHub)\033[0m"
echo "This script will download and install the Kinuxota client from GitHub."
echo -e "${YELLOW}You will need sudo privileges for installation.\033[0m"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run this script as root or with sudo.\033[0m"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# GitHub repository information
GITHUB_USERNAME="yaswanthsk04"
REPO_NAME="kinuxota_client_deply"
PACKAGE_NAME="kinuxota_1.0.0_amd64.deb"
RELEASE_URL="https://github.com/$GITHUB_USERNAME/$REPO_NAME/releases/download/v1.0.0/$PACKAGE_NAME"

# Check if the package exists locally
if [ ! -f "$PACKAGE_NAME" ]; then
    echo -e "${YELLOW}Downloading package from GitHub...\033[0m"
    
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        echo -e "${YELLOW}curl not found. Installing...\033[0m"
        apt-get update
        apt-get install -y curl
    fi
    
    # Download the package
    curl -L -o "$PACKAGE_NAME" "$RELEASE_URL"
    
    # Check if download was successful
    if [ ! -f "$PACKAGE_NAME" ]; then
        echo -e "${RED}Failed to download package.\033[0m"
        exit 1
    fi
fi

# Create a temporary directory for installation
echo -e "${YELLOW}Creating temporary directory for installation...\033[0m"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Copy the package to the temporary directory
cp "$PACKAGE_NAME" "$TEMP_DIR/"

# Install the package
echo -e "${YELLOW}Installing Kinuxota client...\033[0m"
cd "$TEMP_DIR"
dpkg -i "$PACKAGE_NAME"

# Install dependencies if needed
echo -e "${YELLOW}Installing dependencies...\033[0m"
apt-get install -f -y

# Check if installation was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Kinuxota client installed successfully!\033[0m"
    echo ""
    echo -e "You can now configure the client with: ${YELLOW}sudo kinuxctl configure\033[0m"
    echo -e "And check its status with: ${YELLOW}kinuxctl status\033[0m"
    echo ""
    echo -e "The service is managed with systemd:"
    echo -e "  ${YELLOW}sudo systemctl start kinuxota\033[0m"
    echo -e "  ${YELLOW}sudo systemctl stop kinuxota\033[0m"
    echo -e "  ${YELLOW}sudo systemctl restart kinuxota\033[0m"
    echo -e "  ${YELLOW}sudo systemctl status kinuxota\033[0m"
else
    echo -e "${RED}Installation failed.\033[0m"
    exit 1
fi

exit 0
