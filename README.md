# 🔍 ReconHound - Targeted Reconnaissance Tool

![Banner](assets/banner.png) *(Optional: Add a cool ASCII art banner)*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
Automated reconnaissance tool for bug bounty hunters with:
- Scope-aware subdomain discovery
- Live URL validation
- Beautiful HTML/PDF reporting
- FFUF integration for directory brute-forcing

## 🚀 Features
- **Smart Scope Management**: Separate in-scope/out-of-scope targets
- **Multi-Tool Integration**: Subfinder, Amass, httpx, FFUF
- **Professional Reports**: Exportable HTML/PDF with clickable links
- **Stealth Mode**: Passive reconnaissance options

## ⚡ Quick Start
```bash
git clone https://github.com/your-username/ReconHound.git
cd ReconHound
chmod +x install.sh ReconHound.sh
./install.sh  # Installs dependencies
./ReconHound.sh example.com
