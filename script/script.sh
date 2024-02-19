#!/usr/bin/env sh

# Clone the specific Git repository
git clone https://github.com/EpicMandM/gogs.git /gogs

# Ensure cd succeeds
if cd /gogs; then
    go test -v -cover ./...
    go build -o /gogs/gogs .
    mv ./gogs /app
else
    echo "Failed to change directory to /gogs. Exiting."
    exit 1
fi
