#!/bin/bash

# Start the services in detached mode
docker compose up --detach

# Function to display logs in the background
display_logs() {
    docker compose logs --follow
}

# Start displaying logs in the background
display_logs &

# Store the background process ID
background_pid=$!

# Function to monitor logs until a specific string appears
tail_logs_until_string() {
    completion_string="$1"

    # Loop until completion string is found
    while true; do
        # Tail logs of all services and grep for completion string
        docker compose logs --tail=0 --follow | grep -q "$completion_string" && break
        # Sleep for a short while before checking again
        sleep 1
    done

    # Print a message indicating the completion string is found
    echo "Completion string found. Stopping log display."
    
    # Stop the background process
    kill "$background_pid"
    exit 0
}

# Call the function to monitor logs until the completion string appears
tail_logs_until_string "Gogs executable found! Starting..."
