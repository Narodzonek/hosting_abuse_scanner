# Hosting Abuse Scanner 🚫🤬🛡️🛠️

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A simple yet powerful command-line tool written in Bash to quickly scan hosting accounts for potential terms of service 
violations, such as unauthorized backups, warez, or excessive resource usage.

It can also be used for private purposes to analyze space usage on the hosting service.

## Why This Script? 

Manually searching hosting accounts with tools like `du` or `ncdu` for violations is time-consuming and inefficient. 
This script automates the process by generating a single, clean report that summarizes all potential issues. 

## Key Features 

* **Large File Analysis**: Identifies archives, media files, and other large files exceeding a specified threshold.
* **In-depth Directory Analysis**: Creates "Top 10" lists for directories with the largest size and the highest file count (inodes).
* **Violation Pattern Detection**: Actively searches for files and directories that match known violation patterns (e.g., warez, suspicious folder names).
* **Phishing and Web Shell Detection**: Identifies potential phishing kits and common web shells by filename.
* **Access Log Analysis**: Scans access logs for traces of malicious bots and scanning tools.
* **Fully Configurable**: Allows for easy adjustment of thresholds and parameters via command-line flags.
* **Clean & Readable Reports**: Generates a clear summary ready to be copied and pasted or saved to a file.

## Usage 

The script is designed to be run directly on the server within the directory you wish to scan.

1.  **Download the script**
    Navigate to the user's home directory (or any directory you want to scan) and use one of the following commands to download the script:

    * **Using `wget` (recommended):**
        ```bash
        wget https://raw.githubusercontent.com/Narodzonek/hosting_abuse_scanner/main/abuse_scanner.sh
        ```
    * **Using `curl` (alternative):**
        ```bash
        curl -o abuse_scanner.sh https://raw.githubusercontent.com/Narodzonek/hosting_abuse_scanner/main/abuse_scanner.sh
        ```

2.  **Make the script executable**
    ```bash
    chmod +x abuse_scanner.sh
    ```

3.  **Run the script**
    Navigate to the directory you want to scan and execute the script.

    * Run with default settings:
        ```bash
        ./abuse_scanner.sh
        ```
    * Run with custom parameters:
        ```bash
        ./abuse_scanner.sh --top 5 --th-archive 100 --th-media 50
        ```
    * Save the report to a file:
        ```bash
        ./abuse_scanner.sh --output-file report.txt
        ```
    * Display the help message:
        ```bash
        ./abuse_scanner.sh --help
        ```

## Sample Report 
```
--- Account Usage Report ---
Generated at: 2025-06-11 11:26:48
Scanned path: /home/user
--------------------------------------------------

SUMMARY:
Total size: 724M
Total file count: 50172

1. Identified Archive/Backup Files (larger than 100 MB):
   ...

4. IN-DEPTH DIRECTORY ANALYSIS
==================================================================

A. Largest Directories by Size (Top 10):
------------------------------------------------------------------
SIZE       | FILE COUNT      | PATH
------------------------------------------------------------------
723.6 M    | 50170           |  .
...

B. Directories with the Highest File Count (Top 10):
------------------------------------------------------------------
FILE COUNT | SIZE       | PATH
------------------------------------------------------------------
376        | 2.4 M      |  ./domains/example.com/public_html/administrator/language/en-GB
...

5. POTENTIALLY SUSPICIOUS FILES AND DIRECTORIES DETECTED
==================================================================
Suspicious directory name: ./movies
File matching "warez" pattern: ./movies/My.Great.Movie.2025.PL.1080p.mkv (12.4 G)
Potential phishing file (keyword in name): ./public_html/login.html.bak
Potential web shell detected: ./public_html/wp-content/uploads/c99.php
Suspicious user agent in ./logs/access_log: 123.123.123.123 - - [11/Jun/2025:10:00:00 +0200] "GET / HTTP/1.1" 200 1234 "-" "sqlmap/1.5.11"

--- End of Report ---
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.