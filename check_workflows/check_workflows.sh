#!/bin/bash

# Define environment variables
export GH_TOKEN=$TOKEN # GitHub token used for authentication
export GH_HOST="github.com" # GitHub host URL
export REPO_OWNER=$OWNER # Owner of the repository
export REPO_NAME=$REPO # Name of the repository

# Path to the file storing the PID
export pid_file="/var/run/check_workflows.pid"

# Check if the PID file exists
if [ -f "$pid_file" ]; then
    # Get the PID from the file
    old_pid=$(cat "$pid_file")
    
    # Check if the process is still running
    if ps -p "$old_pid" > /dev/null; then

        # Generate a timestamp
        timestamp=$(date +"%Y-%m-%d %H:%M:%S")

        echo "$timestamp - Previous instance of the cron job is still running. Exiting." >> /var/log/check_workflows.log
        exit 0
    fi
fi

# Store the PID of the current process
echo $$ > "$pid_file"

# Function where queue count is 0
function handle_queue_empty() {
    # Get the count of queued workflows
    local count="$1"

    #Generate a timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    echo "$timestamp - No workflows are in the queue. Count: $count" >> /var/log/check_workflows.log
}

# Function to handle case where queue count is more than 0
function handle_queue_not_empty() {
    # Get the count of queued workflows
    local count="$1"
    local scale_count=$((count + 1))

    # Generate a timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Output the timestamp and the count of queued workflows to the log file
    echo "$timestamp - Number of queued workflows: $count" >> /var/log/check_workflows.log

    # Sleep for 10 minutes to prevent excessive API calls and constant scaling actions.
    echo "$timestamp - Scaling to $scale_count and waiting 10 minutes..." >> /var/log/check_workflows.log
    sleep 10m

    # Generate a new timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$timestamp - Done waiting. Exiting." >> /var/log/check_workflows.log
}

# Run the appropriate function based on the queue count
queued_count=$(gh api \
                -H "Accept: application/vnd.github+json" \
                -H "X-GitHub-Api-Version: 2022-11-28" \
                "/repos/$REPO_OWNER/$REPO_NAME/actions/runs?status=queued" | jq '.total_count')
if [ "$queued_count" -eq 0 ]; then
    handle_queue_empty "$queued_count"
else
    handle_queue_not_empty "$queued_count"
fi

# Remove the PID file
rm "$pid_file"

# Exit the script
exit 0