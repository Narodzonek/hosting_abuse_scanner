#!/bin/bash
set -euo pipefail

# --- abuse_scanner.sh ---
# Version: 1.1
# Author: Damian Narodzonek
# License: MIT
# Description: A script to analyze the contents of a hosting account for potential abuses.
#              Detects large files, suspicious patterns, and potential security threats.

# --- CONFIGURATION SECTION (DEFAULT VALUES) ---
ARCHIVE_SIZE_THRESHOLD_MB=100
MEDIA_SIZE_THRESHOLD_MB=100
LARGE_FILE_THRESHOLD_MB=1024
MAX_DIRECTORIES_TO_SHOW=10
ENABLE_PHISHING_DETECTION=false

# --- SUSPICIOUS PATTERNS ---
# Directories that might indicate warez or illegal content
SUSPICIOUS_DIR_NAMES=("filmy" "movies" "seriale" "gry" "games" "cracks" "warez" "muzyka" "music")

# File patterns commonly found in warez releases
WAREZ_PATTERNS=("1080p" "720p" "x264" "BDRip" "WEB-DL" ".PL.")

# File extensions associated with warez
SUSPICIOUS_EXTENSIONS=("nfo" "sfv")

# --- SECURITY THREAT PATTERNS ---
# Keywords that might indicate phishing attempts
PHISHING_KEYWORDS=("login" "password" "verify" "account" "update" "secure" "bank" "paypal")

# Known web shell filenames
WEB_SHELL_NAMES=("c99.php" "r57.php" "b374k.php" "webshell.php" "shell.php")

# User agents of common hacking tools
MALICIOUS_USER_AGENTS=("sqlmap" "nikto" "nmap" "havij" "morfeus")

# --- GLOBAL VARIABLES ---
TEMP_DIR=""

# --- SUPPORT FUNCTIONS ---

# Display help information
show_help() {
cat << EOF
Using: ./$(basename "$0") [OPTIONS]

This script analyzes the current directory for potential abuses of hosting regulations.
It detects large files, suspicious patterns, and potential security threats.

OPTIONS:
    --th-archive        MB      Sets the threshold in MB for archive files (default: ${ARCHIVE_SIZE_THRESHOLD_MB})
    --th-media          MB      Sets the threshold in MB for media files (default: ${MEDIA_SIZE_THRESHOLD_MB})
    --th-big-file       MB      Sets the threshold in MB for generally large files (default: ${LARGE_FILE_THRESHOLD_MB})
    --top               N       Sets how many items to display TOP directory listings (default: ${MAX_DIRECTORIES_TO_SHOW})
    --output-file       FILE    Saves the report to the specified file.
    --phishing          BOOL    Enable phishing detection (true/false, default: ${ENABLE_PHISHING_DETECTION})
    --settings                  Display current configuration settings.
    -h, --help                  Displays this message and terminates the action.

Example:
    ./$(basename "$0") --th-archive 100 --th-media 100 --th-big-file 50 --top 5
    ./$(basename "$0") --phishing true --output-file report.txt
EOF
}

# Display current configuration settings
show_settings() {
cat << EOF
Current Configuration Settings:
==============================

File Size Thresholds:
    Archive files: ${ARCHIVE_SIZE_THRESHOLD_MB} MB
    Media files: ${MEDIA_SIZE_THRESHOLD_MB} MB
    Large files: ${LARGE_FILE_THRESHOLD_MB} MB

Display Settings:
    Max directories to show: ${MAX_DIRECTORIES_TO_SHOW}

Detection Settings:
    Phishing detection: ${ENABLE_PHISHING_DETECTION}

Suspicious Patterns:
    Directory names: ${SUSPICIOUS_DIR_NAMES[*]}
    Warez patterns: ${WAREZ_PATTERNS[*]}
    Suspicious extensions: ${SUSPICIOUS_EXTENSIONS[*]}
    Web shell names: ${WEB_SHELL_NAMES[*]}
    Malicious user agents: ${MALICIOUS_USER_AGENTS[*]}
EOF
}

# Display a spinning animation while scanning
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    echo -n "Scanning in progress, please wait...  "
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
    echo "Scanning completed."
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            --th-archive) ARCHIVE_SIZE_THRESHOLD_MB="$2"; shift; shift;;
            --th-media) MEDIA_SIZE_THRESHOLD_MB="$2"; shift; shift;;
            --th-big-file) LARGE_FILE_THRESHOLD_MB="$2"; shift; shift;;
            --top) MAX_DIRECTORIES_TO_SHOW="$2"; shift; shift;;
            --output-file) OUTPUT_FILE="$2"; shift; shift;;
            --phishing) ENABLE_PHISHING_DETECTION="$2"; shift; shift;;
            --settings) show_settings; exit 0;;
            -h|--help) show_help; exit 0;; 
            *) echo "Unknown option: $1"; show_help; exit 1;;
        esac
    done
}

# Validate that a value is a positive integer
validate_positive_integer() {
    local value="$1"
    local name="$2"
    
    if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -eq 0 ]; then
        echo "Error: $name must be a positive integer, got: $value"
        exit 1
    fi
}

# Validate boolean value
validate_boolean() {
    local value="$1"
    local name="$2"
    
    if [[ "$value" != "true" && "$value" != "false" ]]; then
        echo "Error: $name must be 'true' or 'false', got: $value"
        exit 1
    fi
}

# Perform the actual scanning operations
perform_scan() {
    local total_size_file="$1"
    local total_files_file="$2"
    local archive_files_file="$3"
    local media_files_file="$4"
    local large_files_file="$5"
    local top_by_size_file="$6"
    local top_by_count_file="$7"
    local suspicious_findings_file="$8"

    (
        # --- Basic Statistics ---
        du -sh . > "$total_size_file" 2>/dev/null || echo "0" > "$total_size_file"
        find . -type f -printf . 2>/dev/null | wc -c > "$total_files_file" || echo "0" > "$total_files_file"
        
        # --- Large File Analysis ---
        # Find large archive and backup files
        find . -type f -size +${ARCHIVE_SIZE_THRESHOLD_MB}M \( \
            -iname "*.zip" -o -iname "*.tar" -o -iname "*.gz" -o -iname "*.tgz" -o \
            -iname "*.rar" -o -iname "*.7z" -o -iname "*.sql" -o -iname "*.bak" -o \
            -name "*backup*" \) -exec du -h {} + 2>/dev/null | sort -rh > "$archive_files_file" || touch "$archive_files_file"

        # Find large media and executable files
        find . -type f -size +${MEDIA_SIZE_THRESHOLD_MB}M \( \
            -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" -o \
            -iname "*.mp3" -o -iname "*.wav" -o -iname "*.flac" -o -iname "*.iso" -o \
            -iname "*.img" -o -iname "*.exe" -o -iname "*.msi" \) -exec du -h {} + 2>/dev/null | sort -rh > "$media_files_file" || touch "$media_files_file"

        # Find any other large files
        find . -type f -size +${LARGE_FILE_THRESHOLD_MB}M -exec du -h {} + 2>/dev/null | sort -rh > "$large_files_file" || touch "$large_files_file"
        
        # --- Directory Analysis ---
        # Create directory statistics file
        find . -type f -printf '%h\t%s\n' 2>/dev/null | \
            awk -F'\t' '{ s[$1]+=$2; c[$1]++ } END { for (d in s) printf "%d\t%d\t%s\n", s[d]/1024, c[d], d }' > "$TEMP_DIR/dir_stats.txt" 2>/dev/null || touch "$TEMP_DIR/dir_stats.txt"

        # Top directories by size
        sort -nr -k1 "$TEMP_DIR/dir_stats.txt" 2>/dev/null | head -n "$MAX_DIRECTORIES_TO_SHOW" > "$top_by_size_file" || touch "$top_by_size_file"

        # Top directories by file count
        sort -nr -k2 "$TEMP_DIR/dir_stats.txt" 2>/dev/null | head -n "$MAX_DIRECTORIES_TO_SHOW" | awk -F'\t' '{print $2 "\t" $1 "\t" $3}' > "$top_by_count_file" || touch "$top_by_count_file"
        
        # --- Suspicious Pattern Detection ---
        # Find suspicious directory names
        local dir_find_args=()
        for name in "${SUSPICIOUS_DIR_NAMES[@]}"; do dir_find_args+=(-o -iname "$name"); done
        find . -type d \( "${dir_find_args[@]:1}" \) -exec echo "Suspicious directory name: {}" \; 2>/dev/null > "$suspicious_findings_file" || touch "$suspicious_findings_file"
        
        # Find files with suspicious extensions
        find . -type f \( -iname "*.nfo" -o -iname "*.sfv" \) -exec du -h {} + 2>/dev/null | awk '{size=$1; $1=""; printf "File with a suspicious extension: %s (%s)\n", $0, size}' >> "$suspicious_findings_file" || true
        
        # Find video files with warez patterns
        local warez_find_args=()
        for pattern in "${WAREZ_PATTERNS[@]}"; do warez_find_args+=(-o -iname "*$pattern*"); done
        find . -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) -a \( "${warez_find_args[@]:1}" \) -exec du -h {} + 2>/dev/null | awk '{size=$1; $1=""; printf "File matching pattern \"warez\": %s (%s)\n", $0, size}' >> "$suspicious_findings_file" || true

        # Find potential phishing files (only if enabled)
        if [[ "$ENABLE_PHISHING_DETECTION" == "true" ]]; then
            find . -type f \( -iname "*login*" -o -iname "*password*" -o -iname "*verify*" -o -iname "*account*" -o -iname "*secure*" -o -iname "*bank*" -o -iname "*paypal*" \) \
                -not -path "*/wp-admin/*" -not -path "*/wp-includes/*" -not -path "*/administrator/*" -not -path "*/vendor/*" -not -path "*/.git/*" -not -path "*/node_modules/*" \
                -exec echo "Potential phishing file (keyword in name): {}" \; 2>/dev/null >> "$suspicious_findings_file" || true
        fi

        # Find known web shell filenames
        find . -type f \( -iname "c99.php" -o -iname "r57.php" -o -iname "b374k.php" -o -iname "webshell.php" -o -iname "shell.php" \) -exec echo "Potential web shell detected: {}" \; 2>/dev/null >> "$suspicious_findings_file" || true

        # Find malicious user agents in access logs
        local ua_grep_pattern
        ua_grep_pattern=$(IFS="|"; echo "${MALICIOUS_USER_AGENTS[*]}")
        find . -type f -name "access_log" -exec grep -iE "$ua_grep_pattern" {} + 2>/dev/null | awk '{print "Suspicious user agent in " FILENAME ": " $0}' >> "$suspicious_findings_file" || true
    ) &
    spinner $!
}

# Generate and display the final report
generate_report() {
    local total_size_file="$1"
    local total_files_file="$2"
    local archive_files_file="$3"
    local media_files_file="$4"
    local large_files_file="$5"
    local top_by_size_file="$6"
    local top_by_count_file="$7"
    local suspicious_findings_file="$8"

    # Read files with error handling
    local TOTAL_SIZE
    TOTAL_SIZE=$(cat "$total_size_file" 2>/dev/null | awk '{print $1}' || echo "0")
    local TOTAL_FILES
    TOTAL_FILES=$(cat "$total_files_file" 2>/dev/null || echo "0")
    local ARCHIVE_FILES
    ARCHIVE_FILES=$(cat "$archive_files_file" 2>/dev/null || echo "")
    local MEDIA_FILES
    MEDIA_FILES=$(cat "$media_files_file" 2>/dev/null || echo "")
    local LARGE_FILES
    LARGE_FILES=$(cat "$large_files_file" 2>/dev/null || echo "")
    local TOP_BY_SIZE
    TOP_BY_SIZE=$(cat "$top_by_size_file" 2>/dev/null || echo "")
    local TOP_BY_COUNT
    TOP_BY_COUNT=$(cat "$top_by_count_file" 2>/dev/null || echo "")
    local SUSPICIOUS_FINDINGS
    SUSPICIOUS_FINDINGS=$(cat "$suspicious_findings_file" 2>/dev/null || echo "")

    echo ""
    echo "--- Report of Account Usage ---"
    echo "Date of report generation: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Scanned path: $(pwd)"
    echo "--------------------------------------------------"
    echo ""
    echo "SUMMARY:"
    echo "Total size: $TOTAL_SIZE"
    echo "Total number of files: $TOTAL_FILES"
    echo ""
    
    if [ -n "$ARCHIVE_FILES" ]; then
        echo "1. Identified archive/backup files (larger than ${ARCHIVE_SIZE_THRESHOLD_MB} MB):"
        echo "$ARCHIVE_FILES" | awk '{size=$1; $1=""; sub(/^ +/, "", $0); sub(/^\.\//, "", $0); print size "\t" $0}'
        echo ""
    fi
    
    if [ -n "$MEDIA_FILES" ]; then
        echo "2. Identified media files/images/installers (larger than ${MEDIA_SIZE_THRESHOLD_MB} MB):"
        echo "$MEDIA_FILES" | awk '{size=$1; $1=""; sub(/^ +/, "", $0); sub(/^\.\//, "", $0); print size "\t" $0}'
        echo ""
    fi
    
    if [ -n "$LARGE_FILES" ]; then
        echo "3. Identified individual files larger than ${LARGE_FILE_THRESHOLD_MB} MB:"
        echo "$LARGE_FILES" | awk '{size=$1; $1=""; sub(/^ +/, "", $0); sub(/^\.\//, "", $0); print size "\t" $0}'
        echo ""
    fi
    
    if [ -n "$TOP_BY_SIZE" ] || [ -n "$TOP_BY_COUNT" ]; then
        echo "4. DEEP DIRECTORY ANALYSIS"
        echo "=================================================================="
        echo ""
    fi
    
    if [ -n "$TOP_BY_SIZE" ]; then
        echo "A. Directories with the largest size (Top ${MAX_DIRECTORIES_TO_SHOW}):"
        echo "------------------------------------------------------------------"
        printf "%-10s | %-13s | %s\n" "SIZE" "FILES" "PATH"
        echo "------------------------------------------------------------------"
        echo "$TOP_BY_SIZE" | awk -F'\t' '{size_kb=$1; count=$2; path=$3; sub(/^\.\//, "", path); size_hr = sprintf("%.1f G", size_kb/1024/1024); if (size_kb < 1024*1024) size_hr = sprintf("%.1f M", size_kb/1024); if (size_kb < 1024) size_hr = sprintf("%d K", size_kb); printf "%-10s | %-13s | %s\n", size_hr, count, path;}'
        echo ""
    fi
    
    if [ -n "$TOP_BY_COUNT" ]; then
        echo "B. Directories with the most files (Top ${MAX_DIRECTORIES_TO_SHOW}):"
        echo "------------------------------------------------------------------"
        printf "%-13s | %-10s | %s\n" "FILES" "SIZE" "PATH"
        echo "------------------------------------------------------------------"
        echo "$TOP_BY_COUNT" | awk -F'\t' '{count=$1; size_kb=$2; path=$3; sub(/^\.\//, "", path); size_hr = sprintf("%.1f G", size_kb/1024/1024); if (size_kb < 1024*1024) size_hr = sprintf("%.1f M", size_kb/1024); if (size_kb < 1024) size_hr = sprintf("%d K", size_kb); printf "%-13s | %-10s | %s\n", count, size_hr, path;}'
        echo ""
    fi
    
    if [ -n "$SUSPICIOUS_FINDINGS" ]; then
        echo "5. Potentially suspicious files and directories detected"
        echo "=================================================================="
        echo "$SUSPICIOUS_FINDINGS"
        echo ""
    fi
    
    echo "--- End of Report ---"
}

# --- MAIN LOGIC ---
main() {
    local OUTPUT_FILE=""
    
    # Create a secure temporary directory first
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf -- "$TEMP_DIR"' EXIT

    parse_arguments "$@"
    
    # Validate numeric arguments
    validate_positive_integer "$ARCHIVE_SIZE_THRESHOLD_MB" "Archive threshold"
    validate_positive_integer "$MEDIA_SIZE_THRESHOLD_MB" "Media threshold"
    validate_positive_integer "$LARGE_FILE_THRESHOLD_MB" "Large file threshold"
    validate_positive_integer "$MAX_DIRECTORIES_TO_SHOW" "Max directories to show"
    
    # Validate boolean arguments
    validate_boolean "$ENABLE_PHISHING_DETECTION" "Phishing detection"

    # If an output file is specified, redirect all output to it
    if [ -n "$OUTPUT_FILE" ]; then
        exec > "$OUTPUT_FILE"
    fi

    # Define paths for temporary files
    local total_size_file="$TEMP_DIR/total_size.txt"
    local total_files_file="$TEMP_DIR/total_files.txt"
    local archive_files_file="$TEMP_DIR/archive_files.txt"
    local media_files_file="$TEMP_DIR/media_files.txt"
    local large_files_file="$TEMP_DIR/large_files.txt"
    local top_by_size_file="$TEMP_DIR/top_by_size.txt"
    local top_by_count_file="$TEMP_DIR/top_by_count.txt"
    local suspicious_findings_file="$TEMP_DIR/suspicious_findings.txt"

    # --- MAIN PART OF SEARCH SCRIPT ---
    perform_scan "$total_size_file" "$total_files_file" "$archive_files_file" "$media_files_file" "$large_files_file" "$top_by_size_file" "$top_by_count_file" "$suspicious_findings_file"

    generate_report "$total_size_file" "$total_files_file" "$archive_files_file" "$media_files_file" "$large_files_file" "$top_by_size_file" "$top_by_count_file" "$suspicious_findings_file"
    
    # The 'trap' command will automatically clean up the TEMP_DIR on exit
}

# --- SCRIPT ENTRY POINT ---
# All command line arguments are passed to the main function
main "$@"