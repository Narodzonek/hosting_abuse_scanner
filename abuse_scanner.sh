#!/bin/bash

# --- abuse_scanner.sh ---
# Version: 1.0
# Author: Damian Narodzonek
# License: MIT
# Description: A script to analyze the contents of a hosting account for potential abuses.

# --- CONFIGURATION SECTION (DEFAULT VALUES) ---
THRESHOLD_ARCHIVE_MB=100
THRESHOLD_MEDIA_MB=100
THRESHOLD_LARGE_FILE_MB=1024
TOP_N_DIRECTORIES=10

# --- TODO: Expand with additional name extensions, directories, files, etc.
SUSPICIOUS_DIR_NAMES=("filmy" "movies" "seriale" "gry" "games" "cracks" "warez" "muzyka" "music")
WAREZ_PATTERNS=("1080p" "720p" "x264" "BDRip" "WEB-DL" ".PL.")
SUSPICIOUS_EXTENSIONS=("nfo" "sfv")

# --- SUPPORT FUNCTIONS ---

show_help() {
cat << EOF
Using: ./$(basename "$0") [OPTIONS]

This script analyzes the current directory for potential abuses of hosting regulations.

OPTIONS:
    --th-archive        MB      Sets the threshold in MB for archive files (default: ${THRESHOLD_ARCHIVE_MB})
    --th-media          MB      Sets the threshold in MB for media files (default: ${THRESHOLD_MEDIA_MB})
    --th-big-file       MB      Sets the threshold in MB for generally large files (default: ${THRESHOLD_LARGE_FILE_MB})
    --top               N       Sets how many items to display TOP directory listings (default: ${TOP_N_DIRECTORIES})
    -h, --help                  Displays this message and terminates the action.

Example:
    ./$(basename "$0") --th-archive 100 --th-media 100 --th-big-file 50 --top 5
EOF
}

spinner() {
    local pid=$1; local delay=0.1; local spinstr='|/-\'; echo -n "Scanning in progress, please wait...  "; while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do local temp=${spinstr#?}; printf " [%c]  " "$spinstr"; local spinstr=$temp${spinstr%"$temp"}; sleep $delay; printf "\b\b\b\b\b\b"; done; printf "\b\b\b\b"; echo "Scanning completed."
}

# --- PARSING COMMAND LINE ARGUMENTS ---
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --th-archive) THRESHOLD_ARCHIVE_MB="$2"; shift; shift;;
        --th-media) THRESHOLD_MEDIA_MB="$2"; shift; shift;;
        --th-big-file) THRESHOLD_LARGE_FILE_MB="$2"; shift; shift;;
        --top) TOP_N_DIRECTORIES="$2"; shift; shift;;
        -h|--help) show_help; exit 0;; 
        *) echo "Unknown option: $1"; show_help; exit 1;;
    esac
done

# --- MAIN PART OF SEARCH SCRIPT ---
(
    du -sh . > /tmp/total_size.txt
    find . -type f | wc -l > /tmp/total_files.txt
    find . -type f -size +${THRESHOLD_ARCHIVE_MB}M \( -iname "*.zip" -o -iname "*.tar" -o -iname "*.gz" -o -iname "*.tgz" -o -iname "*.rar" -o -iname "*.7z" -o -iname "*.sql" -o -iname "*.bak" -o -name "*backup*" \) -exec du -h {} + | sort -rh > /tmp/archive_files.txt
    find . -type f -size +${THRESHOLD_MEDIA_MB}M \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.mp3" -o -iname "*.wav" -o -iname "*.flac" -o -iname "*.iso" -o -iname "*.img" -o -iname "*.exe" -o -iname "*.msi" \) -exec du -h {} + | sort -rh > /tmp/media_files.txt
    find . -type f -size +${THRESHOLD_LARGE_FILE_MB}M -exec du -h {} + | sort -rh > /tmp/large_files.txt
    du -ak . | sort -nr | head -n 100 | while read size_kb path; do [ -d "$path" ] && echo "$size_kb $(find "$path" -type f | wc -l) $path"; done | head -n $TOP_N_DIRECTORIES > /tmp/top_by_size.txt
    find . -type f -printf '%h\n' | sort | uniq -c | sort -nr | head -n $TOP_N_DIRECTORIES | while read count path; do echo "$count $(du -sk "$path" | awk '{print $1}') $path"; done > /tmp/top_by_count.txt
    dir_find_args=(); for name in "${SUSPICIOUS_DIR_NAMES[@]}"; do dir_find_args+=(-o -iname "$name"); done
    find . -type d \( "${dir_find_args[@]:1}" \) -exec echo "Suspicious directory name: {}" \; > /tmp/suspicious_findings.txt
    ext_find_args=(); for ext in "${SUSPICIOUS_EXTENSIONS[@]}"; do ext_find_args+=(-o -iname "*.$ext"); done
    find . -type f \( "${ext_find_args[@]:1}" \) -exec du -h {} + | awk '{size=$1; $1=""; printf "File with a suspicious extension: %s (%s)\n", $0, size}' >> /tmp/suspicious_findings.txt
    warez_find_args=(); for pattern in "${WAREZ_PATTERNS[@]}"; do warez_find_args+=(-o -iname "*$pattern*"); done
    find . -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) -a \( "${warez_find_args[@]:1}" \) -exec du -h {} + | awk '{size=$1; $1=""; printf "File matching pattern \"warez\": %s (%s)\n", $0, size}' >> /tmp/suspicious_findings.txt
) &

spinner $!
TOTAL_SIZE=$(cat /tmp/total_size.txt | awk '{print $1}'); TOTAL_FILES=$(cat /tmp/total_files.txt); ARCHIVE_FILES=$(cat /tmp/archive_files.txt); MEDIA_FILES=$(cat /tmp/media_files.txt); LARGE_FILES=$(cat /tmp/large_files.txt); TOP_BY_SIZE=$(cat /tmp/top_by_size.txt); TOP_BY_COUNT=$(cat /tmp/top_by_count.txt); SUSPICIOUS_FINDINGS=$(cat /tmp/suspicious_findings.txt)
echo ""; echo "--- Report of Account Usage ---"; echo "Date of report generation: $(date '+%Y-%m-%d %H:%M:%S')"; echo "Scanned path: $(pwd)"; echo "--------------------------------------------------"; echo ""; echo "SUMMARY:"; echo "Total size: $TOTAL_SIZE"; echo "Total number of files: $TOTAL_FILES"; echo ""
if [ -n "$ARCHIVE_FILES" ]; then echo "1. Identified archive/backup files (larger than ${THRESHOLD_ARCHIVE_MB} MB):"; echo "$ARCHIVE_FILES" | awk '{size=$1; $1=""; path=substr($0,2); print size "\t" path}'; echo ""; fi
if [ -n "$MEDIA_FILES" ]; then echo "2. Identified media files/images/installers (larger than ${THRESHOLD_MEDIA_MB} MB):"; echo "$MEDIA_FILES" | awk '{size=$1; $1=""; path=substr($0,2); print size "\t" path}'; echo ""; fi
if [ -n "$LARGE_FILES" ]; then echo "3. Identified individual files larger than ${THRESHOLD_LARGE_FILE_MB} MB:"; echo "$LARGE_FILES" | awk '{size=$1; $1=""; path=substr($0,2); print size "\t" path}'; echo ""; fi
if [ -n "$TOP_BY_SIZE" ] || [ -n "$TOP_BY_COUNT" ]; then echo "4. DEEP DIRECTORY ANALYSIS"; echo "=================================================================="; echo ""; fi
if [ -n "$TOP_BY_SIZE" ]; then echo "A. Directories with the largest size (Top ${TOP_N_DIRECTORIES}):"; echo "------------------------------------------------------------------"; printf "%-10s | %-13s | %s\n" "SIZE" "FILES" "PATH"; echo "------------------------------------------------------------------"; echo "$TOP_BY_SIZE" | awk '{size_kb=$1; count=$2; $1=$2=""; path=substr($0,2); size_hr = sprintf("%.1f G", size_kb/1024/1024); if (size_kb < 1024*1024) size_hr = sprintf("%.1f M", size_kb/1024); if (size_kb < 1024) size_hr = sprintf("%d K", size_kb); printf "%-10s | %-13s | %s\n", size_hr, count, path;}'; echo ""; fi
if [ -n "$TOP_BY_COUNT" ]; then echo "B. Directories with the most files (Top ${TOP_N_DIRECTORIES}):"; echo "------------------------------------------------------------------"; printf "%-13s | %-10s | %s\n" "FILES" "SIZE" "PATH"; echo "------------------------------------------------------------------"; echo "$TOP_BY_COUNT" | awk '{count=$1; size_kb=$2; $1=$2=""; path=substr($0,2); size_hr = sprintf("%.1f G", size_kb/1024/1024); if (size_kb < 1024*1024) size_hr = sprintf("%.1f M", size_kb/1024); if (size_kb < 1024) size_hr = sprintf("%d K", size_kb); printf "%-13s | %-10s | %s\n", count, size_hr, path;}'; echo ""; fi
if [ -n "$SUSPICIOUS_FINDINGS" ]; then echo "5. Potentially suspicious files and directories detected"; echo "=================================================================="; echo "$SUSPICIOUS_FINDINGS"; echo ""; fi
echo "--- End of Report ---"
rm /tmp/{total_size,total_files,archive_files,media_files,large_files,top_by_size,top_by_count,suspicious_findings}.txt