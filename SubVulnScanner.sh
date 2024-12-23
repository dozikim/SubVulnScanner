#!/bin/bash

# Check if the script is being run with sudo privileges
check_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "\e[91m[!] This script must be run as root (with sudo).\e[0m"
        exit 1
    fi
}

# Banner
print_banner() {
    echo -e "\e[95m###############################################\e[0m"
    echo -e "\e[95m#            SubVulnScanner v1.0                #\e[0m"
    echo -e "\e[95m#    Automated Subdomain & SQLi Scanner       #\e[0m"
    echo -e "\e[95m###############################################\e[0m"
}

# Install required tools
install_tools() {
    echo -e "\e[94m[+] Installing required tools...\e[0m"

    # Install Go if not installed
    if ! command -v go &> /dev/null; then
        echo -e "\e[93m[+] Installing Go...\e[0m"
        sudo apt update && sudo apt install -y golang
    fi

    # Install Amass
    if ! command -v amass &> /dev/null; then
        echo -e "\e[93m[+] Installing Amass...\e[0m"
        sudo apt install -y snapd
        sudo snap install amass
    fi

    # Install Assetfinder
    if ! command -v assetfinder &> /dev/null; then
        echo -e "\e[93m[+] Installing Assetfinder...\e[0m"
        go install github.com/tomnomnom/assetfinder@latest
        sudo mv ~/go/bin/assetfinder /usr/local/bin/
    fi

    # Install Subfinder
    if ! command -v subfinder &> /dev/null; then
        echo -e "\e[93m[+] Installing Subfinder...\e[0m"
        go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
        sudo mv ~/go/bin/subfinder /usr/local/bin/
    fi

    # Install Httpx
    if ! command -v httpx &> /dev/null; then
        echo -e "\e[93m[+] Installing Httpx...\e[0m"
        go install github.com/projectdiscovery/httpx/cmd/httpx@latest
        sudo mv ~/go/bin/httpx /usr/local/bin/
    fi

    # Install Sqlmap
    if ! command -v sqlmap &> /dev/null; then
        echo -e "\e[93m[+] Installing Sqlmap...\e[0m"
        sudo apt install -y sqlmap
    fi

    echo -e "\e[92m[+] All tools are installed and ready to use.\e[0m"
}

# Enumerate subdomains
enumerate_subdomains() {
    domain=$1
    echo -e "\e[94m[+] Enumerating subdomains for: $domain\e[0m"

    amass enum -passive -d $domain -o amass_subdomains.txt
    assetfinder --subs-only $domain > assetfinder_subdomains.txt
    subfinder -d $domain -o subfinder_subdomains.txt

    cat amass_subdomains.txt assetfinder_subdomains.txt subfinder_subdomains.txt | sort -u > all_subdomains.txt
    echo -e "\e[92m[+] Subdomains saved to all_subdomains.txt\e[0m"
}

# Probe live subdomains
probe_live_subdomains() {
    echo -e "\e[94m[+] Probing live subdomains...\e[0m"
    httpx -l all_subdomains.txt -o live_subdomains.txt
    echo -e "\e[92m[+] Live subdomains saved to live_subdomains.txt\e[0m"
}

# Perform SQL Injection testing
test_sql_injection() {
    echo -e "\e[94m[+] Testing for SQL Injection...\e[0m"
    if [ ! -f live_subdomains.txt ]; then
        echo -e "\e[91m[!] No live subdomains found. Please run the 'Probe Live Subdomains' option first.\e[0m"
        return
    fi

    while read -r subdomain; do
        if [[ ! "$subdomain" =~ ^https?:// ]]; then
            subdomain="http://$subdomain"
        fi
        echo -e "\e[94m[+] Testing $subdomain for SQL Injection...\e[0m"
        sqlmap -u "$subdomain" --batch --crawl=2 --risk=3 --level=5
    done < live_subdomains.txt

    echo -e "\e[92m[+] SQL Injection testing completed.\e[0m"
}

# Main function
main() {
    check_sudo
    print_banner
    install_tools

    echo -en "\e[96mEnter the target domain: \e[0m"
    read domain

    if [ -z "$domain" ]; then
        echo -e "\e[91m[!] No domain provided. Exiting.\e[0m"
        exit 1
    fi

    enumerate_subdomains $domain
    probe_live_subdomains
    test_sql_injection
}

# Execute main function
main
