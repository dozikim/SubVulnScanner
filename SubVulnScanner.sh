#!/bin/bash

# Check if the script is being run with sudo privileges
check_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "\e[91m[!] This script must be run as root (with sudo).\e[0m"
        echo -e "\e[91m[!] Please run the script with sudo.\e[0m"
        exit 1
    fi
}

# Function to install tools if missing
install_tools() {
    echo -e "\e[94m[+] Checking and installing missing tools...\e[0m"

    # Install Amass
    if ! command -v amass &> /dev/null; then
        echo -e "\e[93m[+] Installing Amass...\e[0m"
        sudo apt update && sudo apt install snapd -y
        sudo snap install amass
    else
        echo -e "\e[92m[+] Amass is already installed.\e[0m"
    fi

    # Install Assetfinder
    if ! command -v assetfinder &> /dev/null; then
        echo -e "\e[93m[+] Installing Assetfinder...\e[0m"
        go install github.com/tomnomnom/assetfinder@latest
        sudo mv ~/go/bin/assetfinder /usr/local/bin/
    else
        echo -e "\e[92m[+] Assetfinder is already installed.\e[0m"
    fi

    # Install Subfinder
    if ! command -v subfinder &> /dev/null; then
        echo -e "\e[93m[+] Installing Subfinder...\e[0m"
        go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
        sudo mv ~/go/bin/subfinder /usr/local/bin/
    else
        echo -e "\e[92m[+] Subfinder is already installed.\e[0m"
    fi

    # Install Subzy
    if ! command -v subzy &> /dev/null; then
        echo -e "\e[93m[+] Installing Subzy...\e[0m"
        go install github.com/LukaSikic/subzy@latest
        sudo mv ~/go/bin/subzy /usr/local/bin/
    else
        echo -e "\e[92m[+] Subzy is already installed.\e[0m"
    fi

    # Install httpx (used for live subdomain checking)
    if ! command -v httpx &> /dev/null; then
        echo -e "\e[93m[+] Installing httpx...\e[0m"
        go install github.com/projectdiscovery/httpx/cmd/httpx@latest
        sudo mv ~/go/bin/httpx /usr/local/bin/
    else
        echo -e "\e[92m[+] httpx is already installed.\e[0m"
    fi

    # Install Waybackurl
    if ! command -v waybackurls &> /dev/null; then
        echo -e "\e[93m[+] Installing Waybackurl...\e[0m"
        go install github.com/tomnomnom/waybackurls@latest
        sudo mv ~/go/bin/waybackurls /usr/local/bin/
    else
        echo -e "\e[92m[+] Waybackurl is already installed.\e[0m"
    fi

    # Install Nuclei
    if ! command -v nuclei &> /dev/null; then
        echo -e "\e[93m[+] Installing Nuclei...\e[0m"
        curl -s https://api.github.com/repos/projectdiscovery/nuclei/releases/latest \
        | grep "browser_download_url.*nuclei-linux-amd64.zip" \
        | cut -d '"' -f 4 | wget -i -
        unzip nuclei-linux-amd64.zip && chmod +x nuclei && sudo mv nuclei /usr/local/bin/
        nuclei -update-templates
    else
        echo -e "\e[92m[+] Nuclei is already installed.\e[0m"
    fi

    # Install sqlmap (for SQLi testing)
    if ! command -v sqlmap &> /dev/null; then
        echo -e "\e[93m[+] Installing sqlmap...\e[0m"
        sudo apt-get install sqlmap -y
    fi

    echo -e "\e[94m[+] All tools are installed and ready to use.\e[0m"
}

# Banner
print_banner() {
    echo -e "\e[95m###############################################\e[0m"
    echo -e "\e[95m#       Subdomain Security Toolkit v3.0       #\e[0m"
    echo -e "\e[95m###############################################\e[0m"
}

# Enumerate subdomains
enumerate_subdomains() {
    domain=$1

    echo -e "\e[94m[+] Starting subdomain enumeration for: $domain\e[0m"
    echo -e "\e[96mChoose tools for subdomain enumeration:\e[0m"
    echo -e "1. Amass"
    echo -e "2. Assetfinder"
    echo -e "3. Subfinder"
    echo -e "4. All tools"
    echo -en "\e[96mYour choice: \e[0m"
    read enum_choice

    case $enum_choice in
        1)
            echo -e "\e[94m[+] Using Amass...\e[0m"
            amass enum -passive -d $domain -o amass_subdomains.txt
            cat amass_subdomains.txt > all_subdomains.txt
            ;;
        2)
            echo -e "\e[94m[+] Using Assetfinder...\e[0m"
            assetfinder --subs-only $domain > assetfinder_subdomains.txt
            cat assetfinder_subdomains.txt > all_subdomains.txt
            ;;
        3)
            echo -e "\e[94m[+] Using Subfinder...\e[0m"
            subfinder -d $domain -o subfinder_subdomains.txt
            cat subfinder_subdomains.txt > all_subdomains.txt
            ;;
        4)
            echo -e "\e[94m[+] Using Amass, Assetfinder, and Subfinder...\e[0m"
            amass enum -passive -d $domain -o amass_subdomains.txt
            assetfinder --subs-only $domain > assetfinder_subdomains.txt
            subfinder -d $domain -o subfinder_subdomains.txt
            cat amass_subdomains.txt assetfinder_subdomains.txt subfinder_subdomains.txt | sort -u > all_subdomains.txt
            ;;
        *)
            echo -e "\e[91m[!] Invalid choice. Skipping enumeration.\e[0m"
            return
            ;;
    esac

    echo -e "\e[92m[+] Subdomains saved to all_subdomains.txt\e[0m"
}

# Probe live subdomains
probe_live_subdomains() {
    echo -e "\e[94m[+] Checking live subdomains...\e[0m"
    httpx -l all_subdomains.txt -o live_subdomains.txt
    echo -e "\e[92m[+] Live subdomains saved to live_subdomains.txt\e[0m"
}

# Perform SQL Injection testing (automatic without prompt)
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
        echo -e "\e[92m[+] SQL Injection testing completed for $subdomain\e[0m"
    done < live_subdomains.txt
}


# Perform XSS testing
test_xss() {
    echo -e "\e[94m[+] Testing for Cross-Site Scripting (XSS)...\e[0m"
    payload="<script>alert('XSS')</script>"
    while read -r subdomain; do
        echo -e "\e[94m[+] Testing $subdomain with payload: $payload\e[0m"
        curl -s -G "$subdomain" --data-urlencode "input=$payload"
    done < live_subdomains.txt
}

# Main menu function
main_menu() {
    while true; do
        echo -e "\n\e[96mSelect an option:\e[0m"
        echo -e "1. Subdomain Enumeration"
        echo -e "2. Probe Live Subdomains"
        echo -e "3. Test SQL Injection"
        echo -e "4. Test XSS"
        echo -e "5. Exit"
        echo -en "\e[96mYour choice: \e[0m"
        read choice

        case $choice in
            1)
                echo -en "\e[96mEnter the target domain: \e[0m"
                read domain
                if [ -z "$domain" ]; then
                    echo -e "\e[91m[!] No domain provided.\e[0m"
                else
                    enumerate_subdomains $domain
                fi
                ;;
            2)
                probe_live_subdomains
                ;;
            3)
                test_sql_injection
                ;;
            4)
                test_xss
                ;;
            5)
                echo -e "\e[91mExiting. Goodbye!\e[0m"
                exit 0
                ;;
            *)
                echo -e "\e[91mInvalid choice. Try again.\e[0m"
                ;;
        esac
    done
}

# Run the script
check_sudo  # Check for sudo privileges
print_banner
install_tools
main_menu
