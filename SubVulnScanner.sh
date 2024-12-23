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
    echo -e "\e[95m#       Subdomain Vulnerability Scanner       #\e[0m"
    echo -e "\e[95m###############################################\e[0m"
}

# Enumerate subdomains
enumerate_subdomains() {
    domain=$1
    echo -e "\e[94m[+] Starting subdomain enumeration for: $domain\e[0m"
    amass enum -passive -d $domain -o amass_subdomains.txt
    assetfinder --subs-only $domain > assetfinder_subdomains.txt
    subfinder -d $domain -o subfinder_subdomains.txt
    cat amass_subdomains.txt assetfinder_subdomains.txt subfinder_subdomains.txt | sort -u > all_subdomains.txt
    echo -e "\e[92m[+] Subdomains saved to all_subdomains.txt\e[0m"
}

# Probe live subdomains
probe_live_subdomains() {
    echo -e "\e[94m[+] Checking live subdomains...\e[0m"
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

# Main menu function
main_menu() {
    while true; do
        echo -e "\n\e[96mSelect an option:\e[0m"
        echo -e "1. Subdomain Enumeration"
        echo -e "2. Probe Live Subdomains"
        echo -e "3. Test SQL Injection"
        echo -e "4. Exit"
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
check_sudo
print_banner
main_menu
