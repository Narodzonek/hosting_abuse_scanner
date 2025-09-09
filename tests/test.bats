#!/usr/bin/env bats

# --- test.bats ---
# Test suite for abuse_scanner.sh
# Framework: bats-core
# Author: Test Suite
# Description: Comprehensive unit and integration tests for the hosting abuse scanner

# --- TEST CONFIGURATION ---
SCRIPT_PATH="../abuse_scanner.sh"
TEST_DIR=""
REPORT_FILE=""

# --- HELPER FUNCTIONS ---

# Create a temporary test directory
create_test_dir() {
    TEST_DIR=$(mktemp -d)
    echo "Created test directory: $TEST_DIR"
}

# Clean up test directory
cleanup_test_dir() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
        echo "Cleaned up test directory: $TEST_DIR"
    fi
}

# Create test files with specific content
create_test_file() {
    local file_path="$1"
    local content="$2"
    mkdir -p "$(dirname "$file_path")"
    echo "$content" > "$file_path"
}

# Create suspicious file (warez pattern)
create_suspicious_file() {
    local file_path="$1"
    local size_mb="${2:-1}"
    mkdir -p "$(dirname "$file_path")"
    # Create file with specific size
    dd if=/dev/zero of="$file_path" bs=1M count="$size_mb" 2>/dev/null
}

# Create archive file
create_archive_file() {
    local file_path="$1"
    local size_mb="${2:-150}"
    mkdir -p "$(dirname "$file_path")"
    # Create a dummy archive file
    dd if=/dev/zero of="$file_path" bs=1M count="$size_mb" 2>/dev/null
}

# Create media file
create_media_file() {
    local file_path="$1"
    local size_mb="${2:-150}"
    mkdir -p "$(dirname "$file_path")"
    dd if=/dev/zero of="$file_path" bs=1M count="$size_mb" 2>/dev/null
}

# Create suspicious directory
create_suspicious_directory() {
    local dir_path="$1"
    mkdir -p "$dir_path"
}

# Run the scanner and capture output
run_scanner() {
    set +e  # Disable exit on error for this function
    
    local args="$1"
    local output_file="$TEST_DIR/scanner_output.txt"
    
    # Debug: Function entry
    echo "DEBUG: run_scanner function called with args: $args" >&2
    
    # Debug: Check variables
    echo "DEBUG: TEST_DIR is: $TEST_DIR" >&2
    echo "DEBUG: SCRIPT_PATH is: $SCRIPT_PATH" >&2
    echo "DEBUG: output_file will be: $output_file" >&2
    
    # Initialize output file
    echo "" > "$output_file" 2>/dev/null || {
        echo "ERROR: Cannot create output file" >&2
        echo "/tmp/error_output.txt"
        return 1
    }
    
    # Check if TEST_DIR is set
    if [ -z "$TEST_DIR" ]; then
        echo "ERROR: TEST_DIR not set" > "$output_file"
        echo "$output_file"
        return 1
    fi
    
    # Get absolute path to script (simplified)
    local script_abs_path="$SCRIPT_PATH"
    if [[ ! "$script_abs_path" = /* ]]; then
        script_abs_path="$(pwd)/$SCRIPT_PATH"
    fi
    
    # Debug: Check if script exists and is accessible
    if [ ! -f "$script_abs_path" ]; then
        echo "ERROR: Script not found at $script_abs_path" > "$output_file"
        echo "Current directory: $(pwd)" >> "$output_file"
        echo "Script path: $SCRIPT_PATH" >> "$output_file"
        echo "Absolute script path: $script_abs_path" >> "$output_file"
        echo "Files in current directory:" >> "$output_file"
        ls -la . >> "$output_file" 2>&1
        echo "Files in parent directory:" >> "$output_file"
        ls -la .. >> "$output_file" 2>&1
        return 127
    fi
    
    # Make sure the script is executable
    chmod +x "$script_abs_path" 2>/dev/null || true
    
    # Change to test directory and run script from there
    echo "DEBUG: About to change to directory: $TEST_DIR" >&2
    if ! cd "$TEST_DIR"; then
        echo "ERROR: Cannot change to test directory $TEST_DIR" >> "$output_file"
        echo "ERROR: Cannot change to test directory $TEST_DIR" >&2
        echo "$output_file"
        return 1
    fi
    echo "DEBUG: Successfully changed to directory: $(pwd)" >&2
    
    # Debug: Log what we're about to run
    echo "DEBUG: About to run: $script_abs_path $args" >> "$output_file"
    echo "DEBUG: Current directory: $(pwd)" >> "$output_file"
    echo "DEBUG: Script exists: $([ -f "$script_abs_path" ] && echo "yes" || echo "no")" >> "$output_file"
    echo "DEBUG: Script executable: $([ -x "$script_abs_path" ] && echo "yes" || echo "no")" >> "$output_file"
    
    # Try to run the script directly first, then with bash if needed
    echo "DEBUG: About to execute script" >&2
    if [ -x "$script_abs_path" ]; then
        echo "DEBUG: Running script directly: $script_abs_path $args" >&2
        "$script_abs_path" $args >> "$output_file" 2>&1
        local exit_code=$?
    else
        echo "DEBUG: Running script with bash: bash $script_abs_path $args" >&2
        bash "$script_abs_path" $args >> "$output_file" 2>&1
        local exit_code=$?
    fi
    
    echo "DEBUG: Script execution completed with exit code: $exit_code" >&2
    echo "DEBUG: Exit code: $exit_code" >> "$output_file"
    
    # Note: We don't re-enable set -e here to avoid breaking the test
    # set -e  # Re-enable exit on error
    
    echo "DEBUG: About to return output file: $output_file" >&2
    echo "$output_file"
    return $exit_code
}

# Check if output contains specific text
output_contains() {
    local output_file="$1"
    local search_text="$2"
    grep -F -q "$search_text" "$output_file"
}

# Count occurrences of text in output
count_occurrences() {
    local output_file="$1"
    local search_text="$2"
    grep -c "$search_text" "$output_file" || echo "0"
}

# Show error details for debugging
show_error_details() {
    local output_file="$1"
    echo "=== ERROR DETAILS ==="
    cat "$output_file"
    echo "=== END ERROR DETAILS ==="
}

# --- TEST SETUP AND TEARDOWN ---

setup() {
    create_test_dir
    REPORT_FILE="$TEST_DIR/test_report.txt"
}

teardown() {
    cleanup_test_dir
}

# --- TEST CASES ---

@test "Basic functionality: Script identifies suspicious files in flat structure" {
    # Arrange: Create test files
    create_suspicious_file "$TEST_DIR/movie_1080p.mkv" 200
    create_test_file "$TEST_DIR/normal_file.txt" "This is a normal file"
    create_test_file "$TEST_DIR/another_normal.txt" "Another normal file"
    
    # Act: Run scanner
    local output_file
    output_file=$(run_scanner "--th-media 100")
    local exit_code=$?
    
    # Debug: Show error details if test fails
    if [ $exit_code -ne 0 ]; then
        show_error_details "$output_file"
    fi
    
    # Assert: Check exit code
    [ $exit_code -eq 0 ]
    
    # Assert: Check that suspicious file is detected
    output_contains "$output_file" "movie_1080p.mkv"
    output_contains "$output_file" "File matching pattern \"warez\""
    
    # Assert: Check that normal files are not flagged
    ! output_contains "$output_file" "normal_file.txt"
    ! output_contains "$output_file" "another_normal.txt"
    
    # Assert: Check report structure
    output_contains "$output_file" "Report of Account Usage"
    output_contains "$output_file" "SUMMARY:"
    output_contains "$output_file" "End of Report"
}

@test "Negative test: Script does not report clean files" {
    # Arrange: Create only clean files
    create_test_file "$TEST_DIR/document.pdf" "Clean document"
    create_test_file "$TEST_DIR/image.jpg" "Clean image"
    create_test_file "$TEST_DIR/data.csv" "Clean data"
    create_archive_file "$TEST_DIR/small_backup.zip" 50  # Below threshold
    
    # Act: Run scanner
    local output_file
    output_file=$(run_scanner "--th-archive 100 --th-media 100")
    local exit_code=$?
    
    # Assert: Check exit code
    [ $exit_code -eq 0 ]
    
    # Assert: Check that no suspicious files are reported
    ! output_contains "$output_file" "suspicious"
    ! output_contains "$output_file" "warez"
    ! output_contains "$output_file" "phishing"
    
    # Assert: Check that report is generated
    output_contains "$output_file" "Report of Account Usage"
    output_contains "$output_file" "Total number of files:"
}

@test "Recursion test: Script finds suspicious files in deeply nested directories" {
    # Arrange: Create deeply nested structure
    create_suspicious_file "$TEST_DIR/level1/level2/level3/level4/movie_720p.mkv" 200
    create_test_file "$TEST_DIR/level1/normal.txt" "Normal file"
    create_test_file "$TEST_DIR/level1/level2/normal2.txt" "Another normal file"
    
    # Act: Run scanner
    local output_file
    output_file=$(run_scanner "--th-media 100")
    local exit_code=$?
    
    # Assert: Check exit code
    [ $exit_code -eq 0 ]
    
    # Assert: Check that deeply nested suspicious file is found
    output_contains "$output_file" "movie_720p.mkv"
    output_contains "$output_file" "level4/movie_720p.mkv"
    output_contains "$output_file" "File matching pattern \"warez\""
    
    # Assert: Check that normal files are not flagged
    ! output_contains "$output_file" "normal.txt"
    ! output_contains "$output_file" "normal2.txt"
}

@test "Empty directory test: Script handles empty directory gracefully" {
    # Arrange: Empty directory (already created in setup)
    
    # Act: Run scanner
    local output_file
    output_file=$(run_scanner "")
    local exit_code=$?
    
    # Assert: Check exit code
    [ $exit_code -eq 0 ]
    
    # Assert: Check that report is generated even for empty directory
    output_contains "$output_file" "Report of Account Usage"
    output_contains "$output_file" "Total number of files:"
    output_contains "$output_file" "Total size:"
    
    # Assert: Check that no errors are present
    ! output_contains "$output_file" "error"
    ! output_contains "$output_file" "Error"
    ! output_contains "$output_file" "No such file"
}

@test "Multiple files test: Script correctly lists all suspicious files" {
    # Arrange: Create multiple suspicious files
    create_suspicious_file "$TEST_DIR/movie1_1080p.mkv" 200
    create_suspicious_file "$TEST_DIR/movie2_720p.mp4" 150
    create_suspicious_file "$TEST_DIR/movie3_x264.avi" 180
    create_archive_file "$TEST_DIR/large_backup.zip" 200
    create_media_file "$TEST_DIR/large_video.mp4" 150
    create_test_file "$TEST_DIR/normal.txt" "Normal file"
    
    # Act: Run scanner
    local output_file
    output_file=$(run_scanner "--th-archive 100 --th-media 100")
    local exit_code=$?
    
    # Assert: Check exit code
    [ $exit_code -eq 0 ]
    
    # Assert: Check that all suspicious files are detected
    output_contains "$output_file" "movie1_1080p.mkv"
    output_contains "$output_file" "movie2_720p.mp4"
    output_contains "$output_file" "movie3_x264.avi"
    
    # Assert: Check that large files are detected
    output_contains "$output_file" "large_backup.zip"
    output_contains "$output_file" "large_video.mp4"
    
    # Assert: Count suspicious files
    local warez_count
    warez_count=$(count_occurrences "$output_file" "File matching pattern \"warez\"")
    [ "$warez_count" -eq 3 ]
    
    # Assert: Check that normal file is not flagged
    ! output_contains "$output_file" "normal.txt"
}

@test "Archive detection test: Script identifies large archive files" {
    # Arrange: Create archive files
    create_archive_file "$TEST_DIR/backup.zip" 150
    create_archive_file "$TEST_DIR/data.tar.gz" 120
    create_archive_file "$TEST_DIR/small.zip" 50  # Below threshold
    create_test_file "$TEST_DIR/normal.txt" "Normal file"
    
    # Act: Run scanner
    local output_file
    output_file=$(run_scanner "--th-archive 100")
    local exit_code=$?
    
    # Assert: Check exit code
    [ $exit_code -eq 0 ]
    
    # Assert: Check that large archives are detected
    output_contains "$output_file" "backup.zip"
    output_contains "$output_file" "data.tar.gz"
    output_contains "$output_file" "archive/backup files"
    
    # Assert: Check that small archive is not flagged
    ! output_contains "$output_file" "small.zip"
    
    # Assert: Check that normal file is not flagged
    ! output_contains "$output_file" "normal.txt"
}

@test "Media detection test: Script identifies large media files" {
    # Arrange: Create media files
    create_media_file "$TEST_DIR/video.mp4" 150
    create_media_file "$TEST_DIR/audio.mp3" 120
    create_media_file "$TEST_DIR/small.mp4" 50  # Below threshold
    create_test_file "$TEST_DIR/normal.txt" "Normal file"
    
    # Act: Run scanner
    local output_file
    output_file=$(run_scanner "--th-media 100")
    local exit_code=$?
    
    # Assert: Check exit code
    [ $exit_code -eq 0 ]
    
    # Assert: Check that large media files are detected
    output_contains "$output_file" "video.mp4"
    output_contains "$output_file" "audio.mp3"
    output_contains "$output_file" "media files/images/installers"
    
    # Assert: Check that small media file is not flagged
    ! output_contains "$output_file" "small.mp4"
    
    # Assert: Check that normal file is not flagged
    ! output_contains "$output_file" "normal.txt"
}

@test "Suspicious directory test: Script identifies suspicious directory names" {
    # Arrange: Create suspicious directories
    create_suspicious_directory "$TEST_DIR/movies"
    create_suspicious_directory "$TEST_DIR/games"
    create_suspicious_directory "$TEST_DIR/normal_folder"
    create_test_file "$TEST_DIR/movies/file.txt" "File in suspicious directory"
    create_test_file "$TEST_DIR/normal_folder/file.txt" "File in normal directory"
    
    # Act: Run scanner
    local output_file
    output_file=$(run_scanner "")
    local exit_code=$?
    
    # Assert: Check exit code
    [ $exit_code -eq 0 ]
    
    # Assert: Check that suspicious directories are detected
    output_contains "$output_file" "movies"
    output_contains "$output_file" "games"
    output_contains "$output_file" "Suspicious directory name"
    
    # Assert: Check that normal directory is not flagged as suspicious
    # Note: normal_folder should not appear in suspicious findings section
    ! output_contains "$output_file" "Suspicious directory name: ./normal_folder"
}

@test "Phishing detection test: Script detects phishing files when enabled" {
    # Arrange: Create files with phishing keywords
    create_test_file "$TEST_DIR/login.php" "Login page"
    create_test_file "$TEST_DIR/password_reset.html" "Password reset"
    create_test_file "$TEST_DIR/bank_account.php" "Bank account"
    create_test_file "$TEST_DIR/normal.php" "Normal PHP file"
    
    # Act: Run scanner with phishing detection enabled
    local output_file
    output_file=$(run_scanner "--phishing true")
    local exit_code=$?
    
    # Assert: Check exit code
    [ $exit_code -eq 0 ]
    
    # Assert: Check that phishing files are detected
    output_contains "$output_file" "login.php"
    output_contains "$output_file" "password_reset.html"
    output_contains "$output_file" "bank_account.php"
    output_contains "$output_file" "Potential phishing file"
    
    # Assert: Check that normal file is not flagged
    ! output_contains "$output_file" "normal.php"
}

@test "Phishing detection disabled test: Script does not detect phishing when disabled" {
    # Arrange: Create files with phishing keywords
    create_test_file "$TEST_DIR/login.php" "Login page"
    create_test_file "$TEST_DIR/password_reset.html" "Password reset"
    create_test_file "$TEST_DIR/bank_account.php" "Bank account"
    
    # Act: Run scanner with phishing detection disabled (default)
    local output_file
    output_file=$(run_scanner "")
    local exit_code=$?
    
    # Assert: Check exit code
    [ $exit_code -eq 0 ]
    
    # Assert: Check that phishing files are NOT detected
    ! output_contains "$output_file" "login.php"
    ! output_contains "$output_file" "password_reset.html"
    ! output_contains "$output_file" "bank_account.php"
    ! output_contains "$output_file" "Potential phishing file"
}

@test "Command line arguments test: Script handles various command line options" {
    # Arrange: Create test files
    create_archive_file "$TEST_DIR/test.zip" 150
    create_media_file "$TEST_DIR/test.mp4" 150
    create_suspicious_file "$TEST_DIR/test_1080p.mkv" 200
    
    # Act: Run scanner with custom thresholds
    local output_file
    output_file=$(run_scanner "--th-archive 200 --th-media 200 --top 5")
    local exit_code=$?
    
    # Assert: Check exit code
    [ $exit_code -eq 0 ]
    
    # Assert: Check that files below new thresholds are not flagged
    ! output_contains "$output_file" "test.zip"
    ! output_contains "$output_file" "test.mp4"
    
    # Assert: Check that warez files are still detected (no size threshold)
    output_contains "$output_file" "test_1080p.mkv"
}

@test "Settings display test: Script shows current settings" {
    # Act: Run scanner with --settings option
    local output_file
    output_file=$(run_scanner "--settings")
    local exit_code=$?
    
    # Assert: Check exit code
    [ $exit_code -eq 0 ]
    
    # Assert: Check that settings are displayed
    output_contains "$output_file" "Current Configuration Settings"
    output_contains "$output_file" "File Size Thresholds"
    output_contains "$output_file" "Archive files:"
    output_contains "$output_file" "Media files:"
    output_contains "$output_file" "Large files:"
    output_contains "$output_file" "Phishing detection:"
}

@test "Help display test: Script shows help information" {
    # Act: Run scanner with --help option
    local output_file
    output_file=$(run_scanner "--help")
    local exit_code=$?
    
    # Assert: Check exit code
    [ $exit_code -eq 0 ]
    
    # Assert: Check that help is displayed
    output_contains "$output_file" "Using:"
    output_contains "$output_file" "OPTIONS:"
    output_contains "$output_file" "th-archive"
    output_contains "$output_file" "th-media"
    output_contains "$output_file" "Example:"
}

@test "Error handling test: Script handles invalid arguments gracefully" {
    # Act: Run scanner with invalid argument
    local output_file
    set +e  # Disable exit on error for this test
    output_file=$(run_scanner "--invalid-option")
    local exit_code=$?
    set -e  # Re-enable exit on error
    
    # Assert: Check exit code (should be non-zero for error)
    [ $exit_code -ne 0 ]
    
    # Assert: Check that error message is displayed
    output_contains "$output_file" "Unknown option"
    output_contains "$output_file" "help"
}

@test "Output file test: Script saves report to specified file" {
    # Arrange: Create test files
    create_suspicious_file "$TEST_DIR/test.mkv" 200
    
    # Act: Run scanner with output file
    local output_file
    output_file=$(run_scanner "--output-file $REPORT_FILE")
    local exit_code=$?
    
    # Assert: Check exit code
    [ $exit_code -eq 0 ]
    
    # Assert: Check that report file was created
    [ -f "$REPORT_FILE" ]
    
    # Assert: Check that report content is in the file
    output_contains "$REPORT_FILE" "Report of Account Usage"
    output_contains "$REPORT_FILE" "test.mkv"
}

# --- PERFORMANCE TESTS ---

@test "Performance test: Script handles large number of files efficiently" {
    # Arrange: Create many files
    local file_count=100
    for i in $(seq 1 $file_count); do
        create_test_file "$TEST_DIR/file_$i.txt" "File number $i"
    done
    
    # Add one suspicious file
    create_suspicious_file "$TEST_DIR/suspicious.mkv" 200
    
    # Act: Run scanner and measure time
    local start_time
    start_time=$(date +%s)
    local output_file
    output_file=$(run_scanner "")
    local exit_code=$?
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Assert: Check exit code
    [ $exit_code -eq 0 ]
    
    # Assert: Check that suspicious file is found
    output_contains "$output_file" "suspicious.mkv"
    
    # Assert: Check that performance is reasonable (should complete within 30 seconds)
    [ $duration -lt 30 ]
    
    # Assert: Check that files are counted (should be at least file_count + 1)
    local min_files=$((file_count + 1))
    local actual_files
    actual_files=$(grep "Total number of files:" "$output_file" | grep -o '[0-9]\+' || echo "0")
    [ "$actual_files" -ge "$min_files" ]
}
