#!/bin/bash

# GitHub workflow management scripts
# Set these environment variables before running:
# export GITHUB_TOKEN="your_token_here"
# export GITHUB_REPO="owner/repo"

TOKEN="${GITHUB_TOKEN}"
REPO="${GITHUB_REPO:-superpeiss/ios-app-5d25f5ba-e3e4-47b4-83ee-9b4f219b170c}"
API_BASE="https://api.github.com/repos/$REPO"

if [ -z "$TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable is not set"
    echo "Usage: export GITHUB_TOKEN='your_token_here'"
    exit 1
fi

# Function to trigger workflow
trigger_workflow() {
    echo "Triggering workflow..."
    curl -k -X POST \
        "$API_BASE/actions/workflows/ios-build.yml/dispatches" \
        -H "Authorization: token $TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -d '{"ref":"main"}'
    echo "Workflow triggered!"
}

# Function to get latest run status
get_latest_run() {
    echo "Fetching latest workflow run..."
    curl -k -s "$API_BASE/actions/runs" \
        -H "Authorization: token $TOKEN" \
        -H "Accept: application/vnd.github.v3+json" | \
        grep -E '"id"|"status"|"conclusion"|"html_url"' | head -20
}

# Function to get run details by ID
get_run_details() {
    RUN_ID=$1
    echo "Fetching details for run $RUN_ID..."
    curl -k -s "$API_BASE/actions/runs/$RUN_ID/jobs" \
        -H "Authorization: token $TOKEN" \
        -H "Accept: application/vnd.github.v3+json" | \
        grep -B 3 '"conclusion"' | grep -E '"name"|"conclusion"|"status"'
}

# Function to download build logs
download_logs() {
    RUN_ID=$1
    OUTPUT_FILE=${2:-"build_logs.zip"}
    echo "Downloading logs for run $RUN_ID..."
    curl -k -L -s "$API_BASE/actions/runs/$RUN_ID/logs" \
        -H "Authorization: token $TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -o "$OUTPUT_FILE"
    echo "Logs saved to $OUTPUT_FILE"
}

# Function to get artifacts
get_artifacts() {
    RUN_ID=$1
    echo "Fetching artifacts for run $RUN_ID..."
    curl -k -s "$API_BASE/actions/runs/$RUN_ID/artifacts" \
        -H "Authorization: token $TOKEN" \
        -H "Accept: application/vnd.github.v3+json"
}

# Main menu
case "$1" in
    trigger)
        trigger_workflow
        ;;
    status)
        get_latest_run
        ;;
    details)
        get_run_details "$2"
        ;;
    logs)
        download_logs "$2" "$3"
        ;;
    artifacts)
        get_artifacts "$2"
        ;;
    *)
        echo "Usage: $0 {trigger|status|details RUN_ID|logs RUN_ID [OUTPUT_FILE]|artifacts RUN_ID}"
        exit 1
        ;;
esac
