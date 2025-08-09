#!/bin/bash
# Color definitions and printing utilities

# Color codes
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export RED='\033[0;31m'
export NC='\033[0m' # No Color

# Print colored text
print_color() {
    local color=$1
    local text=$2
    
    # Safe indirect variable expansion
    case "$color" in
        "GREEN") printf "${GREEN}%s${NC}\n" "$text" ;;
        "YELLOW") printf "${YELLOW}%s${NC}\n" "$text" ;;
        "BLUE") printf "${BLUE}%s${NC}\n" "$text" ;;
        "RED") printf "${RED}%s${NC}\n" "$text" ;;
        *) printf "%s\n" "$text" ;;
    esac
}

# Print error and exit
error_exit() {
    print_color "RED" "❌ $1" >&2
    exit "${2:-1}"
}

# Print warning
warn() {
    print_color "YELLOW" "⚠️  $1" >&2
}

# Print info
info() {
    print_color "BLUE" "$1"
}

# Print success
success() {
    print_color "GREEN" "✅ $1"
}