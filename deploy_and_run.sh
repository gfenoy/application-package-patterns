#!/bin/bash

# Script to deploy and execute patterns contained in the application-package-patterns repository

set -euo pipefail  # Exit on error

# Configuration
ROOT_URL="${1:-http://localhost:8080/anonymous/ogc-api/}"
GITHUB_BASE_URL="https://raw.githubusercontent.com/eoap/application-package-patterns/main/cwl-workflow"
SERVER_URL="${ROOT_URL}processes"
CWL_DIR="./cwl-workflow"
JSON_DIR="./ogc-processes"
LOG_FILE="deployment.log"

# Colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to display colored messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log "INFO: $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log "SUCCESS: $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log "WARNING: $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log "ERROR: $1"
}

# Function to check if server is accessible
check_server() {
    print_status "Checking server availability..."
    if curl -s --connect-timeout 5 "$SERVER_URL" > /dev/null; then
        print_success "Server accessible at $SERVER_URL"
        return 0
    else
        print_error "Server not accessible at $SERVER_URL"
        return 1
    fi
}

# Function to create workspace
setup_workspace() {
    print_status "Setting up workspace..."
    mkdir -p "$CWL_DIR"
    > "$LOG_FILE"  # Clear log file
    print_success "Directory $CWL_DIR created"
}

# Function to download a CWL file
download_cwl_file() {
    local filename="$1"
    local url="$GITHUB_BASE_URL/$filename"
    local local_path="$CWL_DIR/$filename"
    
    print_status "Downloading $filename..."
    
    if curl -s -f "$url" -o "$local_path"; then
        print_success "✓ $filename downloaded"
        return 0
    else
        print_error "✗ Failed to download $filename"
        return 1
    fi
}

# Function to deploy a CWL file to the server
deploy_cwl_file() {
    local filename="$1"
    local local_path="$CWL_DIR/$filename"
    
    if [[ ! -f "$local_path" ]]; then
        print_error "File $local_path not found"
        return 1
    fi
    
    print_status "Deploying $filename..."
    
    local response
    local http_code
    
    response=$(curl -s -w "\n%{http_code}" -X 'POST' \
        "$SERVER_URL" \
        -H 'accept: application/json' \
        -H 'Content-Type: application/cwl+yaml' \
        --data-binary "@$local_path")
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        print_success "✓ $filename deployed successfully (HTTP $http_code)"
        echo "Response: $response_body" >> "$LOG_FILE"
        return 0
    else
        print_error "✗ Failed to deploy $filename (HTTP $http_code)"
        echo "Error: $response_body" >> "$LOG_FILE"
        return 1
    fi
}

# Function to execute a workflow with AMQP retry logic
execute_workflow() {
    local pattern_number="$1"
    local process_id="pattern-$pattern_number"
    local json_file="$JSON_DIR/pattern-$pattern_number.json"
    local max_retries=3
    local retry_count=0
    
    print_status "Executing workflow $process_id..."
    
    # Check if specific JSON file exists
    if [[ ! -f "$json_file" ]]; then
        print_error "JSON file not found: $json_file"
        return 1
    fi
    
    print_status "Using parameters from: $json_file"
    
    while [[ $retry_count -lt $max_retries ]]; do
        local response
        local http_code
        
        response=$(curl -s -w "\n%{http_code}" -X 'POST' \
            "$SERVER_URL/$process_id/execution" \
            -H 'accept: */*' \
            -H 'Prefer: respond-async;return=representation' \
            -H 'Content-Type: application/json' \
            --data-binary "@$json_file")
        
        http_code=$(echo "$response" | tail -n1)
        response_body=$(echo "$response" | head -n -1)
        
        if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
            print_success "✓ Workflow $process_id launched successfully (HTTP $http_code)"
            echo "Execution response: $response_body" >> "$LOG_FILE"
            
            # Extract job ID if available
            local job_id
            job_id=$(echo "$response_body" | grep -o '"jobID":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "")
            if [[ -n "$job_id" ]]; then
                print_status "Job ID: $job_id"
                
                # Initial status check with messages
                check_job_status "$job_id"
                
                # Silent monitoring loop
                status=$(get_job_status_silent "$job_id")
                while [[ "$status" != "successful" && "$status" != "failed" && "$status" != "error" && "$status" != "unknown" ]]; do
                    print_status "Job still in progress (status: $status), waiting 10 seconds..."
                    sleep 10  # Wait before checking again
                    status=$(get_job_status_silent "$job_id")
                done
                print_success "Job finished with status: $status"
            fi
            
            return 0
        else
            # Check if it's an AMQP error
            if [[ "$response_body" == *"The service failed to send message through AMQP"* ]]; then
                retry_count=$((retry_count + 1))
                if [[ $retry_count -lt $max_retries ]]; then
                    print_warning "AMQP error detected (attempt $retry_count/$max_retries). Waiting 10 seconds before retry..."
                    echo "AMQP retry $retry_count: $response_body" >> "$LOG_FILE"
                    sleep 10
                    continue
                else
                    print_error "✗ Max retries reached for AMQP error on workflow $process_id"
                fi
            fi
            
            print_error "✗ Failed to execute workflow $process_id (HTTP $http_code)"
            echo "Execution error: $response_body" >> "$LOG_FILE"
            return 1
        fi
    done
    
    return 1
}

# Function to check job status (silent version that only returns the status)
get_job_status_silent() {
    local job_id="$1"
    local job_status_url="${ROOT_URL}jobs/$job_id"
    
    local response
    local http_code
    
    response=$(curl -s -w "\n%{http_code}" -X 'GET' \
        "$job_status_url" \
        -H 'accept: application/json')
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        # Extract status from response
        local status
        status=$(echo "$response_body" | grep -o '"status":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "unknown")
        
        # Log the full response for detailed information
        echo "Job status response: $response_body" >> "$LOG_FILE"
        
        # Return only the status
        echo "$status"
        return 0
    else
        echo "Status check error: $response_body" >> "$LOG_FILE"
        echo "unknown"
        return 1
    fi
}

# Function to check job status (verbose version with messages)
check_job_status() {
    local job_id="$1"
    local status
    
    print_status "Checking status for job: $job_id..."
    
    status=$(get_job_status_silent "$job_id")
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        print_success "Job status retrieved"
        print_status "Job $job_id status: $status"
        return 0
    else
        print_error "Failed to retrieve job status for $job_id"
        return 1
    fi
}

# Function to delete a deployed process
delete_process() {
    local process_id="$1"
    local delete_url="http://localhost:8080/anonymous/ogc-api/processes/$process_id"
    
    print_status "Deleting process: $process_id..."
    
    local response
    local http_code
    
    response=$(curl -s -w "\n%{http_code}" -X 'DELETE' \
        "$delete_url" \
        -H 'accept: application/json')
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        print_success "Process $process_id deleted successfully (HTTP $http_code)"
        echo "Delete response: $response_body" >> "$LOG_FILE"
        return 0
    else
        print_error "Failed to delete process $process_id (HTTP $http_code)"
        echo "Delete error: $response_body" >> "$LOG_FILE"
        return 1
    fi
}

# Main function
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    CWL Deployment and Execution       ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    # List of CWL files to download
    local cwl_files=(
        "pattern-1.cwl"
        "pattern-2.cwl"
        "pattern-3.cwl"
        "pattern-4.cwl"
        "pattern-5.cwl"
        "pattern-6.cwl"
        "pattern-7.cwl"
        "pattern-8.cwl"
        "pattern-9.cwl"
        "pattern-10.cwl"
        "pattern-11.cwl"
        "pattern-12.cwl"
    )
    
    # Setup workspace
    setup_workspace
    
    # Check if JSON directory exists
    if [[ ! -d "$JSON_DIR" ]]; then
        print_error "JSON directory not found: $JSON_DIR"
        print_error "Please ensure the application-package-patterns repository is cloned locally"
        exit 1
    fi
    
    # Check server availability
    if ! check_server; then
        print_error "Cannot proceed without server access"
        exit 1
    fi
    
    echo
    print_status "=== PHASE 1: LISTING CWL FILES ==="
    
    local downloaded_files=()
    
    for file in "${cwl_files[@]}"; do
        downloaded_files+=("$file")
    done
    
    echo
    print_status "=== PHASE 2: DEPLOYING CWL FILES ==="
    
    local deployed_files=()
    local failed_deployments=()
    
    for file in "${downloaded_files[@]}"; do
        if deploy_cwl_file "$file"; then
            deployed_files+=("$file")
        else
            failed_deployments+=("$file")
        fi
    done
    
    echo
    print_status "=== PHASE 3: EXECUTING WORKFLOWS ==="
    
    local executed_workflows=()
    local failed_executions=()
    
    # Execute only numbered patterns that were successfully deployed
    for file in "${deployed_files[@]}"; do
        if [[ "$file" =~ ^pattern-([0-9]+)\.cwl$ ]]; then
            local pattern_num="${BASH_REMATCH[1]}"
            if execute_workflow "$pattern_num"; then
                executed_workflows+=("pattern-$pattern_num")
            else
                failed_executions+=("pattern-$pattern_num")
            fi
        fi
    done
    
    echo
    print_status "=== PHASE 4: CLEANING UP DEPLOYED PROCESSES ==="
    
    local deleted_processes=()
    local failed_deletions=()
    
    # Delete all successfully deployed processes
    for file in "${deployed_files[@]}"; do
        if [[ "$file" =~ ^pattern-([0-9]+)\.cwl$ ]]; then
            local pattern_num="${BASH_REMATCH[1]}"
            local process_id="pattern-$pattern_num"
            if delete_process "$process_id"; then
                deleted_processes+=("$process_id")
            else
                failed_deletions+=("$process_id")
            fi
        fi
    done
    
    echo
    print_status "=== SUMMARY ==="
    echo
    print_status "Files downloaded: ${#downloaded_files[@]}"
    print_status "Files deployed: ${#deployed_files[@]}"
    print_status "Workflows executed: ${#executed_workflows[@]}"
    print_status "Processes deleted: ${#deleted_processes[@]}"
    
    if [[ ${#failed_downloads[@]} -gt 0 ]]; then
        print_warning "Download failures: ${failed_downloads[*]}"
    fi
    
    if [[ ${#failed_deployments[@]} -gt 0 ]]; then
        print_warning "Deployment failures: ${failed_deployments[*]}"
    fi
    
    if [[ ${#failed_executions[@]} -gt 0 ]]; then
        print_warning "Execution failures: ${failed_executions[*]}"
    fi
    
    if [[ ${#failed_deletions[@]} -gt 0 ]]; then
        print_warning "Deletion failures: ${failed_deletions[*]}"
    fi
    
    if [[ ${#executed_workflows[@]} -gt 0 ]]; then
        echo
        print_success "Successfully executed workflows:"
        for workflow in "${executed_workflows[@]}"; do
            echo "  ✓ $workflow"
        done
    fi
    
    if [[ ${#deleted_processes[@]} -gt 0 ]]; then
        echo
        print_success "Successfully deleted processes:"
        for process in "${deleted_processes[@]}"; do
            echo "  ✓ $process"
        done
    fi
    
    echo
    print_status "Detailed logs available in: $LOG_FILE"
    print_status "CWL files available in: $CWL_DIR"
}

# Signal handling for cleanup on interruption
cleanup() {
    print_warning "Script interrupted by user"
    exit 1
}

trap cleanup SIGINT SIGTERM

# Check dependencies
if ! command -v curl &> /dev/null; then
    print_error "curl is not installed. Please install it before proceeding."
    exit 1
fi

# Execute main script
main "$@"
