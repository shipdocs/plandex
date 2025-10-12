#!/bin/bash

# Test script for install script interactive functionality
# This script tests that the NanoGPT option works in the install script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Test that the configure_provider function shows NanoGPT option
test_configure_provider_menu() {
    log "Testing configure_provider menu options..."
    
    # Extract the configure_provider function and test it
    # We'll simulate the interactive part by checking the menu text
    
    # Check if the menu shows NanoGPT option
    if grep -A 20 "configure_provider ()" app/cli/install.sh | grep -q "NanoGPT.*Single API key for multiple AI providers"; then
        log "✅ NanoGPT option displayed in menu"
    else
        error "❌ NanoGPT option not displayed in menu"
        return 1
    fi
    
    # Check if the menu shows correct choice range
    if grep -A 30 "configure_provider ()" app/cli/install.sh | grep -q "Enter your choice \[1-4\]"; then
        log "✅ Menu shows correct choice range [1-4]"
    else
        error "❌ Menu does not show correct choice range [1-4]"
        return 1
    fi
    
    # Check if case statement handles option 2 for NanoGPT
    if grep -A 10 "case \$provider_choice in" app/cli/install.sh | grep -A 2 "2)" | grep -q "setup_nanogpt"; then
        log "✅ Case statement correctly handles NanoGPT option"
    else
        error "❌ Case statement does not handle NanoGPT option correctly"
        return 1
    fi
}

# Test that setup_nanogpt function has correct structure
test_setup_nanogpt_function() {
    log "Testing setup_nanogpt function structure..."
    
    # Check if function exists and has correct structure
    if grep -A 50 "setup_nanogpt ()" app/cli/install.sh | grep -q "NanoGPT provides access to multiple AI models"; then
        log "✅ setup_nanogpt function has correct description"
    else
        error "❌ setup_nanogpt function missing or has incorrect description"
        return 1
    fi
    
    # Check if it mentions the correct URL
    if grep -A 50 "setup_nanogpt ()" app/cli/install.sh | grep -q "https://nano-gpt.com"; then
        log "✅ setup_nanogpt function mentions correct URL"
    else
        error "❌ setup_nanogpt function does not mention correct URL"
        return 1
    fi
    
    # Check if it sets the correct environment variable
    if grep -A 50 "setup_nanogpt ()" app/cli/install.sh | grep -q "NANOGPT_API_KEY"; then
        log "✅ setup_nanogpt function uses correct environment variable"
    else
        error "❌ setup_nanogpt function does not use correct environment variable"
        return 1
    fi
    
    # Check if it exports the variable for current session
    if grep -A 50 "setup_nanogpt ()" app/cli/install.sh | grep -q "export NANOGPT_API_KEY="; then
        log "✅ setup_nanogpt function exports variable for current session"
    else
        error "❌ setup_nanogpt function does not export variable for current session"
        return 1
    fi
}

# Test that the function structure is consistent with OpenRouter
test_function_consistency() {
    log "Testing function consistency with OpenRouter setup..."
    
    # Both functions should have similar structure
    local openrouter_lines=$(grep -A 50 "setup_openrouter ()" app/cli/install.sh | wc -l)
    local nanogpt_lines=$(grep -A 50 "setup_nanogpt ()" app/cli/install.sh | wc -l)
    
    # They should be roughly similar in length (within 10 lines)
    local diff=$((openrouter_lines - nanogpt_lines))
    if [ ${diff#-} -le 10 ]; then
        log "✅ setup_nanogpt function has similar structure to setup_openrouter"
    else
        warn "⚠️  setup_nanogpt function length differs significantly from setup_openrouter ($diff lines)"
    fi
    
    # Both should handle existing API key check
    if grep -A 50 "setup_nanogpt ()" app/cli/install.sh | grep -q "Found existing.*API_KEY"; then
        log "✅ setup_nanogpt function checks for existing API key"
    else
        error "❌ setup_nanogpt function does not check for existing API key"
        return 1
    fi
}

# Main test function
main() {
    log "=== Install Script Interactive Test Started at $(date) ==="
    
    # Run all tests
    test_configure_provider_menu
    test_setup_nanogpt_function
    test_function_consistency
    
    log "=== All Install Script Interactive Tests Passed! ==="
}

# Run the tests
main "$@"
