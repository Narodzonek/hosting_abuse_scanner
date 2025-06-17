# Hosting Abuse Scanner 🚀

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A simple yet powerful command-line tool written in Bash to quickly scan hosting accounts for potential terms of service 
violations, such as unauthorized backups, warez, or excessive resource usage.

It can also be used for private purposes to analyze space usage on the hosting service.

## Why This Script? 🤔

Manually searching hosting accounts with tools like `du` or `ncdu` for violations is time-consuming and inefficient. 
This script automates the process by generating a single, clean report that summarizes all potential issues. 

## Key Features 🛠️

* **Large File Analysis**: Identifies archives, media files, and other large files exceeding a specified threshold.
* **In-depth Directory Analysis**: Creates "Top 10" lists for directories with the largest size and the highest file count (inodes).
* **Violation Pattern Detection**: Actively searches for files and directories that match known violation patterns (e.g., warez, suspicious folder names).
* **Fully Configurable**: Allows for easy adjustment of thresholds and parameters via command-line flags.
* **Clean & Readable Reports**: Generates a clear summary ready to be copied and pasted.

## Usage 💻

1.  **Clone the repository**
    ```bash
    git clone [https://github.com/](https://github.com/)Narodzonek/hosting-abuse-scanner.git
    cd hosting-abuse-scanner
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
        ./abuse_scanner.sh --top 5 --prog-archiwum 50
        ```
    * Display the help message:
        ```bash
        ./abuse_scanner.sh --help
        ```

## Sample Report 📊
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
376        | 2.4 M      |  ./domains/[example.com/public_html/administrator/language/en-GB](https://example.com/public_html/administrator/language/en-GB)
...

5. POTENTIALLY SUSPICIOUS FILES AND DIRECTORIES DETECTED
==================================================================
Suspicious directory name: ./movies
File matching "warez" pattern: ./movies/My.Great.Movie.2025.PL.1080p.mkv (12.4 G)

--- End of Report ---
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.