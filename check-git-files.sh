#!/bin/bash

# Script to check which files will be included in the Git repository

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Check if Git is initialized
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Git repository not initialized. Run ./git-setup.sh first.${NC}"
    exit 1
fi

# Show files that will be included
log "Files that will be included in the Git repository:"
echo -e "${BLUE}"
git ls-files
echo -e "${NC}"

# Count files
FILE_COUNT=$(git ls-files | wc -l)
log "Total files to be included: $FILE_COUNT"

# Show files that will be ignored
log "Files that will be ignored by Git:"
echo -e "${YELLOW}"
git status --ignored | grep -A 1000 "Ignored files:" | tail -n +2
echo -e "${NC}"

log "To initialize and push to GitHub, run: ./git-setup.sh"
