#!/bin/bash

# =============================================
# ScopeRecon - Targeted Subdomain Finder for Bug Bounty
# Author: Md Fahim Al Shihab
# Version: 1.0.0
# Features:
# - Proper HTML report generation with clickable links
# - Scope management (in-scope/out-of-scope)
# - Subdomain discovery
# - Live URL validation
# - Auto-generated HTML/PDF reports
# =============================================

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# ASCII Banner
echo -e "${PURPLE}${BOLD}"
cat << "EOF"

██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗██╗  ██╗ ██████╗ ██╗   ██╗███╗   ██╗██████╗ 
██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║██║  ██║██╔═══██╗██║   ██║████╗  ██║██╔══██╗
██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║███████║██║   ██║██║   ██║██╔██╗ ██║██║  ██║
██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║██╔══██║██║   ██║██║   ██║██║╚██╗██║██║  ██║
██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║██║  ██║╚██████╔╝╚██████╔╝██║ ╚████║██████╔╝
╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═════╝ 
EOF
echo -e "${NC}"
echo -e "${BLUE}${BOLD}ScopeRecon - Targeted Subdomain Finder for Bug Bounty${NC}"
echo -e "${BLUE}${BOLD}Author: Md Fahim Al Shihab${NC}"
echo -e "${BLUE}==========================================================${NC}"

# Initialize variables
IN_SCOPE=()
OUT_SCOPE=()
TARGET=""
OUTDIR=""
HTML_REPORT=""
SUBS_FILE=""
LIVE_URLS_FILE=""

# Function to normalize URLs (add https:// if not present)
normalize_url() {
    local url=$1
    if [[ ! $url =~ ^https?:// ]]; then
        url="https://$url"
    fi
    echo "$url"
}

# Function to extract domain from URL
extract_domain() {
    local url=$1
    # Remove http:// or https://
    url=${url#*//}
    # Remove path and query parameters
    url=${url%%/*}
    # Remove port number if present
    url=${url%:*}
    echo "$url"
}

# Function to get user input for scope
get_scope() {
    # Get in-scope URLs
    echo -e "${GREEN}[?] How many in-scope URLs do you want to add?${NC}"
    read -p "Enter number: " in_scope_count
    
    for ((i=1; i<=$in_scope_count; i++)); do
        read -p "Enter in-scope URL #$i (with or without http/https): " url
        normalized_url=$(normalize_url "$url")
        IN_SCOPE+=("$normalized_url")
    done
    
    # Get out-of-scope URLs
    echo -e "${YELLOW}[?] How many out-of-scope URLs do you want to add?${NC}"
    read -p "Enter number: " out_scope_count
    
    for ((i=1; i<=$out_scope_count; i++)); do
        read -p "Enter out-of-scope URL #$i (with or without http/https): " url
        normalized_url=$(normalize_url "$url")
        OUT_SCOPE+=("$normalized_url")
    done
    
    # Extract base domain from first in-scope URL if TARGET not set
    if [ ${#IN_SCOPE[@]} -gt 0 ]; then
        TARGET=$(extract_domain "${IN_SCOPE[0]}")
        echo -e "${BLUE}[*] Detected target domain: $TARGET${NC}"
    else
        echo -e "${RED}[!] No in-scope URLs provided. Please specify a target domain.${NC}"
        read -p "Enter target domain (e.g., example.com): " TARGET
    fi
    
    # Setup output directory
    OUTDIR="scoperecon-$TARGET-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$OUTDIR"
    
    # Save scope files
    printf "%s\n" "${IN_SCOPE[@]}" > "$OUTDIR/in_scope.txt"
    printf "%s\n" "${OUT_SCOPE[@]}" > "$OUTDIR/out_scope.txt"
    
    # Set file paths
    HTML_REPORT="$OUTDIR/report.html"
    SUBS_FILE="$OUTDIR/subdomains.txt"
    LIVE_URLS_FILE="$OUTDIR/live_urls.txt"
}

# Function to perform subdomain discovery
subdomain_discovery() {
    echo -e "${GREEN}[+] Discovering subdomains...${NC}"
    
    # Use subfinder for passive discovery
    echo -e "${BLUE}[*] Running passive subdomain discovery (Subfinder)...${NC}"
    subfinder -d "$TARGET" -silent -o "$SUBS_FILE"
    
    # Use assetfinder for additional sources
    echo -e "${BLUE}[*] Running additional discovery (Assetfinder)...${NC}"
    assetfinder --subs-only "$TARGET" >> "$SUBS_FILE"
    
    # Sort and remove duplicates
    sort -u "$SUBS_FILE" -o "$SUBS_FILE"
    
    SUBS_COUNT=$(wc -l < "$SUBS_FILE" 2>/dev/null || echo 0)
    echo -e "${BLUE}[*] Found $SUBS_COUNT unique subdomains${NC}"
}

# Function to validate live URLs
validate_live_urls() {
    echo -e "${GREEN}[+] Checking for live URLs...${NC}"
    
    # First check all in-scope URLs
    echo -e "${BLUE}[*] Checking in-scope URLs...${NC}"
    printf "%s\n" "${IN_SCOPE[@]}" | httpx -silent -mc 200,403,401,302 -o "$LIVE_URLS_FILE"
    
    # Then check discovered subdomains
    echo -e "${BLUE}[*] Checking discovered subdomains...${NC}"
    cat "$SUBS_FILE" | httpx -silent -mc 200,403,401,302 >> "$LIVE_URLS_FILE"
    
    # Remove any out-of-scope URLs that might have been found
    if [ ${#OUT_SCOPE[@]} -gt 0 ]; then
        echo -e "${BLUE}[*] Filtering out out-of-scope URLs...${NC}"
        # Normalize out-of-scope URLs for comparison
        printf "%s\n" "${OUT_SCOPE[@]}" | sed 's|^https\?://||' > "$OUTDIR/out_scope_patterns.txt"
        grep -v -f "$OUTDIR/out_scope_patterns.txt" "$LIVE_URLS_FILE" > "$LIVE_URLS_FILE.tmp"
        mv "$LIVE_URLS_FILE.tmp" "$LIVE_URLS_FILE"
    fi
    
    # Sort and remove duplicates
    sort -u "$LIVE_URLS_FILE" -o "$LIVE_URLS_FILE"
    
    LIVE_COUNT=$(wc -l < "$LIVE_URLS_FILE" 2>/dev/null || echo 0)
    echo -e "${BLUE}[*] Found $LIVE_COUNT live URLs in scope${NC}"
}

dir_bruteforce() {
    echo -e "\n${GREEN}[?] Directory Brute-Force${NC}"
    read -p "Run FFUF on main target ONLY? (y/n) " run_ffuf
    
    if [[ "$run_ffuf" == "y" ]]; then
        # Wordlist selection
        echo -e "${BLUE}Available wordlists:${NC}"
        echo "1) Quick scan (common.txt)"
        echo "2) Deep scan (big.txt)"
        echo "3) Custom path"
        read -p "Choose wordlist (1/2/3): " wordlist_choice

        case $wordlist_choice in
            1) wordlist="/usr/share/wordlists/SecLists/Discovery/Web-Content/common.txt" ;;
            2) wordlist="/usr/share/wordlists/SecLists/Discovery/Web-Content/big.txt" ;;
            3) read -p "Enter full wordlist path: " wordlist ;;
            *) wordlist="/usr/share/wordlists/SecLists/Discovery/Web-Content/common.txt" ;;
        esac

        # Verify wordlist exists
        if [ ! -f "$wordlist" ]; then
            echo -e "${RED}[!] Wordlist not found: $wordlist${NC}"
            return 1
        fi

        # Rate-limiting
        read -p "Threads (default: 20): " threads
        read -p "Delay between requests (seconds, default: 0.2): " delay
        threads=${threads:-20}
        delay=${delay:-0.2}

        echo -e "${GREEN}[+] Brute-forcing MAIN TARGET: https://$TARGET${NC}"
        mkdir -p "$OUTDIR/ffuf_scans"
        
        # Use first in-scope URL or construct from target
        if [ ${#IN_SCOPE[@]} -gt 0 ]; then
            target_url="${IN_SCOPE[0]}"
        else
            target_url="https://$TARGET"
        fi

        ffuf -u "$target_url/FUZZ" -w "$wordlist" -t "$threads" -p "$delay" \
             -o "$OUTDIR/ffuf_scans/main_target.json" -of json -s 2>/dev/null
        
        # Verify FFUF output
        if [ ! -s "$OUTDIR/ffuf_scans/main_target.json" ]; then
            echo -e "${YELLOW}[!] No results found for main target${NC}"
            rm -f "$OUTDIR/ffuf_scans/main_target.json"
        else
            echo -e "${GREEN}[+] FFUF scan saved to: $OUTDIR/ffuf_scans/main_target.json${NC}"
            echo -e "${BLUE}[*] Findings:$(jq -r '.results[] | " \(.status)-\(.length)chars \(.url)"' "$OUTDIR/ffuf_scans/main_target.json" 2>/dev/null | wc -l)${NC}"
        fi
    fi
}

# Function to generate HTML report with clickable links
generate_report() {
    echo -e "${GREEN}[+] Generating HTML report...${NC}"
    
    # Prepare data for report with clickable links
    IN_SCOPE_LIST=$(printf "%s\n" "${IN_SCOPE[@]}" | sed 's|.*|<a href="&" target="_blank">&</a>|')
    OUT_SCOPE_LIST=$(printf "%s\n" "${OUT_SCOPE[@]}" | sed 's|.*|<a href="&" target="_blank">&</a>|')
    LIVE_URLS=$(cat "$LIVE_URLS_FILE" 2>/dev/null | sed 's|.*|<a href="&" target="_blank">&</a>|' || echo "No live URLs found")
    SUBS_LIST=$(cat "$SUBS_FILE" 2>/dev/null | sed 's|.*|<a href="https://&" target="_blank">&</a>|' || echo "No subdomains found")
    
    # Prepare FFUF results if they exist
    FFUF_RESULTS=""
    if [ -f "$OUTDIR/ffuf_scans/main_target.json" ]; then
        FFUF_RESULTS=$(jq -r '.results[]? | "\(.status)-\(.length)chars <a href=\"\(.url)\" target=\"_blank\">\(.url)</a>"' "$OUTDIR/ffuf_scans/main_target.json" 2>/dev/null || echo "No findings")
    else
        FFUF_RESULTS="No FFUF scan performed on main target"
    fi
    
    cat > "$HTML_REPORT" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ScopeRecon Report for $TARGET</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
    <style>
        body { padding: 20px; font-family: Arial, sans-serif; }
        .report-header { background-color: #6f42c1; color: white; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        .card { margin-bottom: 20px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        #pdf-export { margin-bottom: 20px; }
        pre { background-color: #f8f9fa; padding: 15px; border-radius: 4px; overflow-x: auto; white-space: pre-wrap; }
        a { color: #0d6efd; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .badge { font-size: 0.9em; }
        .in-scope { background-color: #28a745; }
        .out-scope { background-color: #dc3545; }
    </style>
</head>
<body>
    <div class="container-fluid">
        <div class="report-header">
            <h1 class="text-center">ScopeRecon Report</h1>
            <h3 class="text-center">Target: $TARGET</h3>
            <p class="text-center">Generated on $(date) by ScopeRecon v2.2</p>
        </div>

        <button id="pdf-export" class="btn btn-danger">Export as PDF</button>

        <div class="row">
            <div class="col-md-4">
                <div class="card text-white bg-primary">
                    <div class="card-body text-center">
                        <h5 class="card-title">Subdomains</h5>
                        <h2 class="card-text">$SUBS_COUNT</h2>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card text-white bg-success">
                    <div class="card-body text-center">
                        <h5 class="card-title">Live URLs</h5>
                        <h2 class="card-text">$LIVE_COUNT</h2>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card text-white bg-info">
                    <div class="card-body text-center">
                        <h5 class="card-title">Scope Summary</h5>
                        <h4 class="card-text">
                            <span class="badge in-scope">In-Scope: ${#IN_SCOPE[@]}</span>
                            <span class="badge out-scope">Out-Scope: ${#OUT_SCOPE[@]}</span>
                        </h4>
                    </div>
                </div>
            </div>
        </div>

        <div class="card">
            <div class="card-header">
                <h3>Scope Details</h3>
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-6">
                        <h4>In-Scope URLs <span class="badge in-scope">${#IN_SCOPE[@]}</span></h4>
                        <pre>$IN_SCOPE_LIST</pre>
                    </div>
                    <div class="col-md-6">
                        <h4>Out-of-Scope URLs <span class="badge out-scope">${#OUT_SCOPE[@]}</span></h4>
                        <pre>$OUT_SCOPE_LIST</pre>
                    </div>
                </div>
            </div>
        </div>

        <div class="card">
            <div class="card-header">
                <h3>All Subdomains <span class="badge bg-primary">$SUBS_COUNT</span></h3>
            </div>
            <div class="card-body">
                <pre>$SUBS_LIST</pre>
            </div>
        </div>

        <div class="card">
            <div class="card-header">
                <h3>Live URLs <span class="badge bg-success">$LIVE_COUNT</span></h3>
            </div>
            <div class="card-body">
                <pre>$LIVE_URLS</pre>
            </div>
        </div>

        <div class="card">
            <div class="card-header">
                <h3>FFUF Scan Results <span class="badge bg-warning">$(ls "$OUTDIR/ffuf_scans"/*.json 2>/dev/null | wc -l)</span></h3>
            </div>
            <div class="card-body">
                <pre>$FFUF_RESULTS</pre>
            </div>
        </div>

        <div class="text-center mt-4 text-muted">
            <p>Report generated by ScopeRecon - Targeted Subdomain Finder for Bug Bounty</p>
        </div>
    </div>

    <script>
        document.getElementById('pdf-export').addEventListener('click', () => {
            const element = document.body;
            const opt = {
                margin: 10,
                filename: 'scoperecon_${TARGET}_report.pdf',
                image: { type: 'jpeg', quality: 0.98 },
                html2canvas: { scale: 2 },
                jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' }
            };
            
            // Show loading state
            const btn = document.getElementById('pdf-export');
            btn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status"></span> Generating PDF...';
            
            // Generate PDF
            html2pdf().set(opt).from(element).save().then(() => {
                btn.innerHTML = 'Export as PDF';
            });
        });
    </script>
</body>
</html>
EOF

    # Generate PDF if wkhtmltopdf is installed
    if command -v wkhtmltopdf &>/dev/null; then
        echo -e "${GREEN}[+] Generating PDF report...${NC}"
        wkhtmltopdf --quiet "$HTML_REPORT" "$OUTDIR/report.pdf" 2>/dev/null || \
        echo -e "${YELLOW}[!] PDF generation failed (install wkhtmltopdf for PDF reports)${NC}"
    fi

    # Open report in default browser with better handling
    echo -e "${GREEN}[+] Attempting to open report in browser...${NC}"
    if which xdg-open >/dev/null 2>&1; then
        xdg-open "$HTML_REPORT" >/dev/null 2>&1 || \
        echo -e "${YELLOW}[!] Could not open automatically. Please open manually:${NC}\n    firefox $HTML_REPORT"
    elif which open >/dev/null 2>&1; then
        open "$HTML_REPORT" >/dev/null 2>&1 || \
        echo -e "${YELLOW}[!] Could not open automatically. Please open manually:${NC}\n    open -a 'Google Chrome' $HTML_REPORT"
    else
        echo -e "${YELLOW}[!] Please open the report manually in your browser:${NC}"
        echo -e "    firefox $HTML_REPORT"
        echo -e "    google-chrome $HTML_REPORT"
        echo -e "    brave $HTML_REPORT"
    fi
}

# Main execution
get_scope
subdomain_discovery
validate_live_urls
dir_bruteforce
generate_report

echo -e "\n${PURPLE}${BOLD}[+] Reconnaissance completed!${NC}"
echo -e "${GREEN}Report generated in:${NC} ${BLUE}$OUTDIR/${NC}"
echo -e "${GREEN}To view your report:${NC}"
echo -e "1. Open the HTML report in your browser:"
echo -e "   ${BLUE}firefox $OUTDIR/report.html${NC}"
echo -e "   ${BLUE}google-chrome $OUTDIR/report.html${NC}"
echo -e "2. Or serve it with a simple web server:"
echo -e "   ${BLUE}cd $OUTDIR && python3 -m http.server 8000${NC}"
echo -e "   Then visit ${BLUE}http://localhost:8000/report.html${NC}"
[ -f "$OUTDIR/report.pdf" ] && echo -e "3. PDF version available: ${BLUE}$OUTDIR/report.pdf${NC}"
