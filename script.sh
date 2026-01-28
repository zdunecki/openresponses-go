#!/bin/bash
set -e

# Configuration
UPSTREAM_REPO="openai/openai-go"
TARGET_MODULE="github.com/zdunecki/openresponses-go"
PACKAGE_TO_EXTRACT="./responses"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Add Go bin to PATH
export PATH="$PATH:$(go env GOPATH)/bin"

# Files/directories to preserve (not delete during cleanup)
PRESERVE=(
    "license"
    "script.sh"
    ".github"
    ".goreleaser.yaml"
    ".git"
)

# Get the latest tag from upstream
get_latest_tag() {
    # Try gh CLI first, fallback to curl
    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
        gh api "repos/${UPSTREAM_REPO}/tags" --jq '.[0].name'
    else
        curl -s "https://api.github.com/repos/${UPSTREAM_REPO}/tags" | grep -m1 '"name"' | cut -d'"' -f4
    fi
}

# Check if tag already exists in our repo
tag_exists() {
    local tag=$1
    git tag -l "$tag" | grep -q "^${tag}$"
}

# Clean directory except preserved files
clean_directory() {
    echo "Cleaning directory..."
    cd "$SCRIPT_DIR"

    for item in *; do
        local preserve=false
        for p in "${PRESERVE[@]}"; do
            if [[ "$item" == "$p" ]]; then
                preserve=true
                break
            fi
        done
        if [[ "$preserve" == false ]]; then
            echo "  Removing: $item"
            rm -rf "$item"
        fi
    done

    # Also clean hidden files, checking against preserve list
    for item in .[!.]*; do
        local preserve=false
        for p in "${PRESERVE[@]}"; do
            if [[ "$item" == "$p" ]]; then
                preserve=true
                break
            fi
        done
        if [[ "$preserve" == false ]]; then
            echo "  Removing: $item"
            rm -rf "$item"
        fi
    done
}

# Cleanup temporary files
cleanup_temp() {
    echo "Cleaning up temporary files..."
    rm -rf /tmp/openai-go /tmp/openresponses-extracted
}

# Clone upstream repo at specific tag
clone_upstream() {
    local tag=$1
    echo "Cloning ${UPSTREAM_REPO} at tag ${tag}..."

    # Clean up any existing temp directories first
    cleanup_temp

    git clone --depth 1 --branch "$tag" "https://github.com/${UPSTREAM_REPO}.git" /tmp/openai-go
}

# Extract the responses package
extract_package() {
    echo "Extracting ${PACKAGE_TO_EXTRACT} package..."
    cd /tmp/openai-go
    gopkgcp -pkg "$PACKAGE_TO_EXTRACT" -o /tmp/openresponses-extracted -mod "$TARGET_MODULE" -v
    cd "$SCRIPT_DIR"

    # Move extracted files to current directory
    cp -r /tmp/openresponses-extracted/* .
}

# Main execution
main() {
    local tag=${1:-$(get_latest_tag)}

    if [[ -z "$tag" ]]; then
        echo "Error: Could not determine tag. Please provide a tag as argument."
        echo "Usage: $0 [tag]"
        exit 1
    fi

    echo "========================================="
    echo "OpenResponses-Go Sync Script"
    echo "========================================="
    echo "Upstream repo: ${UPSTREAM_REPO}"
    echo "Target module: ${TARGET_MODULE}"
    echo "Tag: ${tag}"
    echo "========================================="

    # Check if tag already exists
    if tag_exists "$tag"; then
        echo "Tag ${tag} already exists. Nothing to do."
        exit 0
    fi

    # Clean directory
    clean_directory

    # Clone and extract
    clone_upstream "$tag"
    extract_package

    # Build to verify
    echo "Building to verify extraction..."
    go build ./...

    echo "Running tests..."
    go test ./... || echo "Some tests failed (this may be expected without API keys)"

    # Cleanup
    cleanup_temp

    echo "========================================="
    echo "Successfully extracted from ${tag}"
    echo "========================================="
}

main "$@"
