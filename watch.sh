#!/usr/bin/env bash

# Define the path to your monitoring script (assuming it's called 'monitor.sh' and is executable)
monitor_script="./scan.sh"

# Clear the screen for the initial run
clear

# Use watch to repeatedly execute the monitoring script
# -n 10: Set interval to 10 seconds
# -t: Turn off header
# -c: Use terminal colours
watch -n 1 -t -c "$monitor_script"
