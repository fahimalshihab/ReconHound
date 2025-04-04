# 🔍 ReconHound - Targeted Reconnaissance Tool

```text
██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗██╗  ██╗ ██████╗ ██╗   ██╗███╗   ██╗██████╗ 
██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║██║  ██║██╔═══██╗██║   ██║████╗  ██║██╔══██╗
██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║███████║██║   ██║██║   ██║██╔██╗ ██║██║  ██║
██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║██╔══██║██║   ██║██║   ██║██║╚██╗██║██║  ██║
██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║██║  ██║╚██████╔╝╚██████╔╝██║ ╚████║██████╔╝
╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═════╝ 
```
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Release](https://img.shields.io/github/v/release/fahimalshihab/ReconHound)](https://github.com/fahimalshihab/ReconHound/releases/latest)
[![Open Issues](https://img.shields.io/github/issues/fahimalshihab/ReconHound)](https://github.com/fahimalshihab/ReconHound/issues)

Automated reconnaissance tool for bug bounty hunters and penetration testers with scope-aware target discovery and professional reporting.

## 🌟 Features

- **Smart Scope Management**
  - Separate in-scope/out-of-scope targets
  - Automatic scope validation
  - Domain normalization (handles URLs with/without http/https)

- **Comprehensive Reconnaissance**
  - Subdomain discovery (Subfinder, Assetfinder)
  - Live URL validation (httpx)
  - Directory brute-forcing (FFUF integration)
  - Response code/size filtering

- **Professional Reporting**
  - Interactive HTML reports
  - Exportable PDF reports
  - Visual statistics and charts
  - Clickable target links

- **Optimized Workflow**
  - Rate limiting controls
  - Wordlist selection
  - Stealth mode (passive reconnaissance)
  - Automated output organization

## 🚀 Quick Start

### Prerequisites
- Linux/macOS
- Bash 4.0+
- Go 1.15+ (for tool installation)
- Python 3.6+ (for reporting)

### Installation
```bash
git clone https://github.com/fahimalshihab/ReconHound.git
cd ReconHound
chmod +x install.sh 
./install.sh  # Installs all dependencies
```

### Basic Usage
```./ReconHound.sh```

### Interactive Example

```bash
$ ./ReconHound.sh
██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗██╗  ██╗ ██████╗ ██╗   ██╗███╗   ██╗██████╗ 
██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║██║  ██║██╔═══██╗██║   ██║████╗  ██║██╔══██╗
██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║███████║██║   ██║██║   ██║██╔██╗ ██║██║  ██║
██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║██╔══██║██║   ██║██║   ██║██║╚██╗██║██║  ██║
██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║██║  ██║╚██████╔╝╚██████╔╝██║ ╚████║██████╔╝
╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═════╝ 

ScopeRecon - Targeted Subdomain Finder for Bug Bounty
Author: Md Fahim Al Shihab
==========================================================
[?] How many in-scope URLs do you want to add?
Enter number: 1
Enter in-scope URL #1 (with or without http/https): https://manager.thefork.com/
[?] How many out-of-scope URLs do you want to add?
Enter number: 0
[*] Detected target domain: manager.thefork.com
[+] Discovering subdomains...
[*] Running passive subdomain discovery (Subfinder)...
www.manager.thefork.com
[*] Running additional discovery (Assetfinder)...
[*] Found 2 unique subdomains
[+] Checking for live URLs...
[*] Checking in-scope URLs...
https://manager.thefork.com/
[*] Checking discovered subdomains...
[*] Found 3 live URLs in scope

[?] Directory Brute-Force
Run FFUF on main target ONLY? (y/n) y
Available wordlists:
1) Quick scan (common.txt)
2) Deep scan (big.txt)
3) Custom path
Choose wordlist (1/2/3): 1
Threads (default: 20): 20
Delay between requests (seconds, default: 0.2): 0.5
[+] Brute-forcing MAIN TARGET: https://manager.thefork.com
.git-rewrite
.git_release
.gitk
.git/HEAD
.cvsignore
.cvs
.git
.cache
.git/index
.env
.git/logs/
.gitconfig
etc..........

[+] FFUF scan saved to: scoperecon-manager.thefork.com-20250405_001420/ffuf_scans/main_target.json
[*] Findings:88
[+] Generating HTML report...
[+] Generating PDF report...
[+] Attempting to open report in browser...

[+] Reconnaissance completed!
Report generated in: scoperecon-manager.thefork.com-20250405_001420/
To view your report:
1. Open the HTML report in your browser:
   firefox scoperecon-manager.thefork.com-20250405_001420/report.html
   google-chrome scoperecon-manager.thefork.com-20250405_001420/report.html
2. Or serve it with a simple web server:
   cd scoperecon-manager.thefork.com-20250405_001420 && python3 -m http.server 8000
   Then visit http://localhost:8000/report.html
3. PDF version available: scoperecon-manager.thefork.com-20250405_001420/report.pdf
```
![image](https://github.com/user-attachments/assets/f8d49061-51a1-41a1-a3ac-6eed74c4ddfb)

### 🤝 Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you'd like to change.
