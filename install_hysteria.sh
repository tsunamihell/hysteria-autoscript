#!/bin/bash

# Function to print characters with delay
print_with_delay() {
    text="$1"
    delay="$2"
    for ((i = 0; i < ${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo
}

# Introduction animation
echo ""
echo ""
print_with_delay "Hysteria2 Installer by YourName" 0.1
echo ""
echo ""

# Install required packages
install_required_packages() {
    REQUIRED_PACKAGES=("curl" "openssl")
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if ! command -v $pkg &> /dev/null; then
            apt-get update > /dev/null 2>&1
            apt-get install -y $pkg > /dev/null 2>&1
        fi
    done
}

# Check if the directory /root/hysteria exists
if [ -d "/root/hysteria" ]; then
    echo "Hysteria seems to be already installed."
    echo ""
    echo "Choose an option:"
    echo "1) Reinstall"
    echo "2) Modify Configuration"
    echo "3) Uninstall"
    read -p "Enter your choice: " choice
    case $choice in
        1)
            echo "Reinstalling..."
            rm -rf /root/hysteria
            systemctl stop hysteria
            systemctl disable hysteria > /dev/null 2>&1
            rm /etc/systemd/system/hysteria.service
            ;;
        2)
            echo "Modifying Configuration..."
            cd /root/hysteria

            # Get current settings
            current_port=$(grep -oP 'listen: :\K\d+' config.yaml)
            current_password=$(grep -m 1 'password:' config.yaml | awk -F': ' '{print $2}' | tr -d '[:space:]')

            # Prompt user for new settings
            read -p "Enter a new port (current: $current_port): " new_port
            read -p "Enter a new password (current: $current_password): " new_password
            new_port=${new_port:-$current_port}
            new_password=${new_password:-$current_password}

            # Update configuration
            sed -i "s/listen: :$current_port/listen: :$new_port/" config.yaml
            sed -i "s/password: $current_password/password: $new_password/" config.yaml

            # Restart service
            systemctl restart hysteria
            echo "Configuration updated successfully!"
            exit 0
            ;;
        3)
            echo "Uninstalling..."
            rm -rf /root/hysteria
            systemctl stop hysteria
            systemctl disable hysteria > /dev/null 2>&1
            rm /etc/systemd/system/hysteria.service
            echo "Hysteria uninstalled successfully!"
            exit 0
            ;;
        *)
            echo "Invalid choice."
            exit 1
            ;;
    esac
fi

# Install required packages
install_required_packages

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"
BINARY_NAME="hysteria-linux-amd64"

# Create installation directory
mkdir -p /root/hysteria
cd /root/hysteria

# Download the Hysteria binary
echo "Downloading Hysteria binary..."
wget -q "https://github.com/apernet/hysteria/releases/latest/download/$BINARY_NAME"
chmod +x "$BINARY_NAME"

# Generate certificates
echo "Generating self-signed certificates..."
openssl ecparam -genkey -name prime256v1 -out ca.key
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/CN=localhost"

# Prompt user for port and password
read -p "Enter a port (default: 443): " port
port=${port:-443}
read -p "Enter a password (default: random): " password
password=${password:-$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 16 | head -n 1)}

# Create config.yaml
echo "Creating configuration..."
cat > config.yaml <<EOL
listen: :$port
tls:
  cert: /root/hysteria/ca.crt
  key: /root/hysteria/ca.key
auth:
  type: password
  password: $password
EOL

# Create systemd service
cat > /etc/systemd/system/hysteria.service <<EOL
[Unit]
Description=Hysteria VPN Service
After=network.target

[Service]
ExecStart=/root/hysteria/$BINARY_NAME server -c /root/hysteria/config.yaml
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Start the service
systemctl daemon-reload
systemctl enable hysteria
systemctl start hysteria

# Display client configuration
PUBLIC_IP=$(curl -s https://api.ipify.org)
echo "Hysteria is successfully installed!"
echo "Server: $PUBLIC_IP"
echo "Port: $port"
echo "Password: $password"
