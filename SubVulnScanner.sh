#!/bin/bash

# Check if the script is being run with sudo privileges
check_sudo() {
    if [ "$(id -u)" -ne 0; then
        echo -e "\e[91m[!] This script must be run as root (with sudo).\e[0m"
        echo -e "\e[91m[!] Please run the script with sudo.\e[0m"
        exit 1
    fi
}

# Banner
print_banner() {
    echo -e "\e[95m###############################################\e[0m"
    echo -e "\e[95m#       Subdomain Security Toolkit v3.1       #\e[0m"
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

# Main menu function
main_menu() {
    while true; do
        echo -e "\n\e[96mSelect an option:\e[0m"
        echo -e "1. Subdomain Enumeration"
        echo -e "2. Probe Live Subdomains"
        echo -e "3. Exit"
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
check_sudo           # Check for sudo privileges
print_banner         # Display the banner
main_menu            # Launch the main menu
