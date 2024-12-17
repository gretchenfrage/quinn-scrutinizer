#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

# Define output directory for grouped failures
grouped_dir="./grouped"
mkdir -p "$grouped_dir"

echo -e "${GREEN}[ INFO  ]${NC} Grouping failing tests"

# Check each subdirectory under "runs"
for dir in runs/*; do
    status_file="$dir/status"
    output_file="$dir/output"

    # Ensure the status file exists
    if [ ! -f "$status_file" ]; then
        continue
    fi

    # Read the status file and check if the run had a failure (non-zero status)
    read -r status < "$status_file"
    if ! [[ "$status" =~ ^-?[0-9]+$ ]] || [ "$status" -eq 0 ]; then
        continue  # Skip runs without failures
    fi

    # Ensure the output file exists and contains failures
    if [ -f "$output_file" ]; then
        # Extract failing test names
        failed_tests=$(awk '/failures:/ {flag=1; next} /^[^ ]/ {flag=0} flag {print substr($0, 5)}' "$output_file")
        
        # Process each failing test
        while IFS= read -r test; do
            if [[ -n "$test" ]]; then  # Only process non-empty lines
                # Replace colons with underscores in the test name
                sanitized_test=$(echo "$test" | sed 's/:/_/g')

                # Create the destination directory: grouped/$failing_test
                destination_dir="$grouped_dir/$sanitized_test"
                mkdir -p "$destination_dir"

                # Copy the output file into the destination directory
                run_name=$(basename "$dir")
                cp "$output_file" "$destination_dir/$run_name"
            fi
        done <<< "$failed_tests"
    fi
done

echo -e "${GREEN}[ INFO  ]${NC} Grouping complete. Outputs organized in '$grouped_dir'."

zip -r grouped.zip grouped

