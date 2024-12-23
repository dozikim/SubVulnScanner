#!/bin/bash

# Check if the script is being run with sudo privileges
check_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "\e[91m[!] This script must be run as root (with sudo).\e[0m"
        echo -e "\e[91m[!] Please run the script with sudo.\e[0m"
        exit 1
    fi
}

# Install Go if not already installed
install_go() {
    if ! command -v go &> /dev/null; then
        echo -e "\e[93m[+] Go is not installed. Installing Go...\e[0m"
        GO_VERSION=$(curl -s https://go.dev/VERSION?m=text)
        wget "https://golang.org/dl/${GO_VERSION}.linux-amd64.tar.gz"
        tar -C /usr/local -xzf "${GO_VERSION}.linux-amd64.tar.gz"
        rm "${GO_VERSION}.linux-amd64.tar.gz"

        # Set up Go environment
        echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile
        echo "export GOPATH=\$HOME/go" >> ~/.profile
        echo "export PATH=\$PATH:\$GOPATH/bin" >> ~/.profile
        source ~/.profile

        echo -e "\e[92m[+] Go has been successfully installed and configured.\e[0m"
    else
        echo -e "\e[92m[+] Go is already installed.\e[0m"
    fi
}

# Install tools if missing
install_tools() {
    echo -e "\e[94m[+] Checking and installing missing tools...\e[0m"

    # Ensure Go environment is set up
    export GOPATH="${GOPATH:-$HOME/go}"
    export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
    mkdir -p "$GOPATH/bin"

    # Install Amass
    if ! command -v amass &> /dev/null; then
        echo -e "\e[93m[+] Installing Amass...\e[0m"
        apt update && apt install snapd -y
        snap install amass
    else
        echo -e "\e[92m[+] Amass is already installed.\e[0m"
    fi

    # Install Assetfinder
    if ! command -v assetfinder &> /dev/null; then
        echo -e "\e[93m[+] Installing Assetfinder...\e[0m"
        go install github.com/tomnomnom/assetfinder@latest
        mv "$GOPATH/bin/assetfinder" /usr/local/bin/
    else
        echo -e "\e[92m[+] Assetfinder is already installed.\e[0m"
    fi

    # Install Subfinder
    if ! command -v subfinder &> /dev/null; then
        echo -e "\e[93m[+] Installing Subfinder...\e[0m"
        go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
        mv "$GOPATH/bin/subfinder" /usr/local/bin/
    else
        echo -e "\e[92m[+] Subfinder is already installed.\e[0m"
    fi

    # Install Subzy
    if ! command -v subzy &> /dev/null; then
        echo -e "\e[93m[+] Installing Subzy...\e[0m"
        go install github.com/LukaSikic/subzy@latest
        mv "$GOPATH/bin/subzy" /usr/local/bin/
    else
        echo -e "\e[92m[+] Subzy is already installed.\e[0m"
    fi

    # Install httpx
    if ! command -v httpx &> /dev/null; then
        echo -e "\e[93m[+] Installing httpx...\e[0m"
        go install github.com/projectdiscovery/httpx/cmd/httpx@latest
        mv "$GOPATH/bin/httpx" /usr/local/bin/
    else
        echo -e "\e[92m[+] httpx is already installed.\e[0m"
    fi

    # Install Waybackurl
    if ! command -v waybackurls &> /dev/null; then
        echo -e "\e[93m[+] Installing Waybackurl...\e[0m"
        go install github.com/tomnomnom/waybackurls@latest
        mv "$GOPATH/bin/waybackurls" /usr/local/bin/
    else
        echo -e "\e[92m[+] Waybackurl is already installed.\e[0m"
    fi

    # Install Nuclei
    if ! command -v nuclei &> /dev/null; then
        echo -e "\e[93m[+] Installing Nuclei...\e[0m"
        latest_nuclei_url=$(curl -s https://api.github.com/repos/projectdiscovery/nuclei/releases/latest \
        | grep "browser_download_url.*nuclei-linux-amd64.zip" \
        | cut -d '"' -f 4)
        wget "$latest_nuclei_url"
        unzip nuclei-linux-amd64.zip && chmod +x nuclei
        mv nuclei /usr/local/bin/
        rm nuclei-linux-amd64.zip
        nuclei -update-templates
    else
        echo -e "\e[92m[+] Nuclei is already installed.\e[0m"
    fi

    # Install sqlmap
    if ! command -v sqlmap &> /dev/null; then
        echo -e "\e[93m[+] Installing sqlmap...\e[0m"
        apt-get install sqlmap -y
    fi

    echo -e "\e[94m[+] All tools are installed and ready to use.\e[0m"
}

# Run the script
check_sudo           # Check for sudo privileges
install_go           # Install Go if necessary
install_tools        # Install required tools
