# SubVulnScanner

SubVulnScanner is a Bash-based subdomain enumeration and vulnerability testing toolkit. It automates the process of discovering subdomains and testing for vulnerabilities such as SQL Injection and Cross-Site Scripting (XSS) on live subdomains. This tool is intended for penetration testers, bug bounty hunters, and security researchers.

## Features

- **Subdomain Enumeration**: Automatically discovers subdomains using multiple tools like Amass, Assetfinder, and Subfinder.
- **Live Subdomain Probing**: Verifies which discovered subdomains are live using `httpx`.
- **SQL Injection Testing**: Automatically tests live subdomains for SQL Injection vulnerabilities using `sqlmap`.
- **XSS Testing**: Tests for Cross-Site Scripting (XSS) vulnerabilities by injecting payloads into query parameters.
- **Tool Installation**: Automatically installs necessary tools like `Amass`, `Assetfinder`, `Subfinder`, `httpx`, `sqlmap`, and `nuclei`.

## Requirements

- **Linux-based Operating System** (Ubuntu recommended)
- **sudo privileges** (for installing required tools)
- **Tools**: `curl`, `wget`, `unzip`, `git`, `go`, and `apt` package manager

## Installation

To get started, follow these steps to clone and set up the tool:

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/SubVulnScanner.git
   cd SubVulnScanner

Make the script executable:

    chmod +x SubVulnScanner.sh

Run the script with sudo to install required tools:

    sudo ./SubVulnScanner.sh

Usage

    Run the tool: Start the tool by running the following command:

    sudo ./SubVulnScanner.sh

    Main Menu: The script will display a menu where you can choose options such as:
        Subdomain enumeration
        Probing live subdomains
        Testing for SQL Injection
        Testing for XSS vulnerabilities

    Subdomain Enumeration: You will be prompted to enter a domain. The script will then use tools like Amass, Assetfinder, and Subfinder to enumerate subdomains and save them to all_subdomains.txt.

    Probe Live Subdomains: The script will check which subdomains are live using httpx and save the results to live_subdomains.txt.

    SQL Injection Testing: The script will use sqlmap to test the live subdomains for SQL Injection vulnerabilities.

    XSS Testing: The script will test the live subdomains for XSS vulnerabilities by injecting a predefined script payload.

Tool Installation

The script will automatically check for missing tools and install the following:

    Amass (Subdomain enumeration)
    Assetfinder (Subdomain enumeration)
    Subfinder (Subdomain enumeration)
    httpx (Live subdomain probing)
    sqlmap (SQL Injection testing)
    nuclei (Vulnerability scanning)

The script will install any missing dependencies during execution.
