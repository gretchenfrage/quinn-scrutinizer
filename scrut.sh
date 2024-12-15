#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}[ INFO  ]${NC} starting"

# Gather list of executables
executables=$(cd quinn && cargo test --no-run 2>&1 | grep 'Executable' | awk -F'[()]' '{print $2}')

run_executables() {
    local exec_status=0
    for executable in $executables; do
        # Run each executable with specified arguments
        echo "Running $executable"
        (cd quinn && ./$executable --test-threads 1) 2>&1
        exec_status=$?
        if [ $exec_status -ne 0 ]; then
            return $exec_status
        fi
    done
    return 0
}

run_tests() {
    while true; do
        # Get current timestamp with millisecond precision
        timestamp=$(date +"%Y-%m-%d-%H-%M-%S-%3N")
        # Generate a random 16 digit lower-hexadecimal number, removing all spaces and newlines
        rand=$(hexdump -n 8 -e '4/4 "%08x" 1 "\n"' /dev/urandom | sed 's/[[:space:]]//g')
        # Create directory path
        dir="runs/$timestamp-$rand"
        echo -e "${GREEN}[ INFO  ]${NC} doing $dir"
        mkdir -p "$dir"

        # Call the new function to run executables
        run_executables >"$dir/output" 2>&1
        # Capture the exit status
        status=$?
        echo $status > "$dir/status"

        # Remove the output file if status is 0, otherwise log the warning
        if [ "$status" -eq 0 ]; then
            rm "$dir/output"
        else
            echo -e " ^--${YELLOW}[ WARN  ]${NC} error in $dir"
        fi
    done
}

# Start 10 instances of run_tests in the background
for i in {1..10}; do
    run_tests &
done

# Wait for all background jobs to finish
wait
