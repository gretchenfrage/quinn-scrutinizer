#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

echo -e "${GREEN}[ INFO  ]${NC} Scanning"
#echo

# Initialize counters
total_files=0
non_zero_status_files=0

# Temporary file to store failed tests
failed_tests_file="failed_tests.log"
> "$failed_tests_file"  # Clear/create the file

# Check each subdirectory under "runs"
for dir in runs/*; do
    status_file="$dir/status"
    output_file="$dir/output"

    if [ ! -f "$status_file" ]; then
        continue  # Skip if it's not a file
    fi

    # Read the status file and parse it as an integer
    read -r status < "$status_file"
    if ! [[ "$status" =~ ^-?[0-9]+$ ]]; then
        echo -e "${RED}[ ERROR ]${NC} Status file does not contain an integer: $status_file"
        exit 1
    fi

    # Increment total_files counter
    ((total_files++))

    if [ "$status" -ne 0 ]; then
        #echo -e "${YELLOW}[ WARNING ]${NC} Non-zero status ($status) in $dir"
        ((non_zero_status_files++))

        # Check and log failed tests
        if [ -f "$output_file" ]; then
            # Extract failed tests
            failed_tests=$(awk '/failures:/ {flag=1; next} /^[^ ]/ {flag=0} flag {print substr($0, 5)}' "$output_file")

            # Loop over each test and print it
            while IFS= read -r test; do
                if [[ -n "$test" ]]; then  # Only process non-empty lines
                    #echo -e " - ${test}"
                    echo "$test" >> "$failed_tests_file"  # Save to the file
                fi
            done <<< "$failed_tests"
        fi
    fi
done

# Calculate the percentage of non-zero statuses
if [ "$total_files" -eq 0 ]; then
    formatted_percentage="0.00"
else
    percentage=$(echo "scale=2; 100 * $non_zero_status_files / $total_files" | bc)
    formatted_percentage=$(printf "%.2f" "$percentage")
fi

echo
echo -e "${GREEN}[ INFO  ]${NC} Total test runs: $total_files"
echo -e "${GREEN}[ INFO  ]${NC} Errored test runs: $non_zero_status_files"
echo -e "${GREEN}[ INFO  ]${NC} Percentage of errored test runs: ${formatted_percentage}%"

# Calculate total disk space used by the runs directory
disk_usage_mb=$(du -sm runs | awk '{print $1}')
echo
echo -e "${GREEN}[ INFO  ]${NC} Total disk usage of 'runs' directory: ${disk_usage_mb} MB"

# Pass the data to Python for processing
if [ "$non_zero_status_files" -gt 0 ]; then
    echo
    echo -e "${GREEN}[ INFO  ]${NC} Failure rates for individual tests:"
    python3 -c "
import sys
from collections import Counter

# Read test names from stdin
test_names = sys.stdin.read().strip().split('\n')

# Count occurrences
test_counts = Counter(test_names)

# Calculate percentages based on total number of runs
total_runs = $total_files
max_test_name_length = max(len(test) for test in test_counts)  # Determine padding for test names
percentage_width = 8  # Fixed width for percentage column
count_width = 6  # Fixed width for raw count column

for test, count in sorted(test_counts.items()):
    percentage = 100 * count / total_runs
    print(f'{test:<{max_test_name_length}} {percentage:>{percentage_width}.5f}% {count:>{count_width}}')
" < "$failed_tests_file"
else
    echo -e "${GREEN}[ INFO  ]${NC} No test failures recorded."
fi
