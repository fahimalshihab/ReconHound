#!/bin/bash

# ReconHound Dependency Installer
echo -e "\033[1;34m[+] Installing ReconHound dependencies...\033[0m"

# Check for Go
if ! command -v go &> /dev/null; then
    echo -e "\033[1;33m[!] Go not found. Installing...\033[0m"
    sudo apt install golang -y || brew install go
fi

# Required Tools
tools=(
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    "github.com/OWASP/Amass/v3/cmd/amass@latest"
    "github.com/projectdiscovery/httpx/cmd/httpx@latest"
    "github.com/ffuf/ffuf@latest"
    "github.com/tomnomnom/assetfinder@latest"
    "github.com/lc/gau/v2/cmd/gau@latest"
)

# Install Go tools
for tool in "${tools[@]}"; do
    echo -e "\033[1;32m[*] Installing $tool\033[0m"
    go install $tool
done

# Update PATH
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
source ~/.bashrc

# Wordlists (Optional)
if [ ! -d "wordlists" ]; then
    mkdir wordlists
    wget https://gist.githubusercontent.com/jhaddix/86a06c5dc309d08580a018c66354a056/raw/96f4e51d96b2203f19f6381c8c545b278eaa0837/all.txt -O wordlists/dns_wordlist.txt
fi

echo -e "\033[1;32m[+] Installation complete! Run ./ReconHound.v1.0.0\033[0m"
