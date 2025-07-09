#!/bin/bash

set -e  # Stop kalau ada error

echo "🔄 Updating repositories..."
sudo yum update -y

echo "📦 Installing dependencies..."
sudo yum install -y git npm python3 python3-pip docker cronie curl

echo "🔧 Enabling and starting Docker & Cron..."
sudo systemctl enable --now docker
sudo systemctl enable --now crond

# Install Docker Compose (manual karena tidak tersedia default di yum)
if ! command -v docker-compose &> /dev/null; then
    echo "🔧 Installing docker-compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Install virtualenv (ganti python3-venv di yum)
if ! python3 -m venv --help &>/dev/null; then
    echo "📦 Installing virtualenv..."
    sudo pip3 install virtualenv
fi

# Clean up running podman containers if any (optional)
if command -v podman &> /dev/null; then
    echo "🧹 Checking for running podman containers..."
    running=$(podman ps -q)
    if [[ ! -z "$running" ]]; then
        echo "⚠️ Found running podman containers. Stopping them..."
        podman stop $(podman ps -q)
    fi
    echo "🧼 Removing all podman containers..."
    podman rm -a || true
fi

# Clone the repo
if [[ ! -d yumOcean ]]; then
    echo "📥 Cloning yumOcean repo..."
    git clone https://github.com/ahmadhidayatt/yumOcean.git
fi

cd yumOcean
chmod +x ocean.sh

# Setup Python virtual environment
if [[ ! -d venv ]]; then
    echo "🐍 Creating Python virtual environment..."
    python3 -m venv venv || virtualenv venv
fi

echo "✅ Activating virtual environment..."
source venv/bin/activate

# Install Python packages
echo "📦 Installing Python libraries..."
pip3 install --upgrade pip
pip3 install eth_account requests pyyaml

echo "🚀 Setup completed. You're now ready to run ./ocean.sh"
