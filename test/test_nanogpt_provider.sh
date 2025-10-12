#!/bin/bash

# Test script for NanoGPT provider integration
# This script tests that NanoGPT is properly configured as a provider option

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

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

# Test that NanoGPT provider is properly defined
test_nanogpt_provider_constants() {
    log "Testing NanoGPT provider constants..."
    
    # Check if NanoGPT constants are defined in the Go code
    if grep -q "ModelProviderNanoGPT.*ModelProvider.*=.*\"nanogpt\"" app/shared/ai_models_providers.go; then
        log "✅ NanoGPT provider constant found"
    else
        error "❌ NanoGPT provider constant not found"
        return 1
    fi
    
    if grep -q "NanoGPTBaseUrl.*=.*\"https://nano-gpt.com/api/v1\"" app/shared/ai_models_providers.go; then
        log "✅ NanoGPT base URL constant found"
    else
        error "❌ NanoGPT base URL constant not found"
        return 1
    fi
    
    if grep -q "NanoGPTApiKeyEnvVar.*=.*\"NANOGPT_API_KEY\"" app/shared/ai_models_providers.go; then
        log "✅ NanoGPT API key environment variable constant found"
    else
        error "❌ NanoGPT API key environment variable constant not found"
        return 1
    fi
}

# Test that NanoGPT is included in provider lists
test_nanogpt_in_provider_lists() {
    log "Testing NanoGPT in provider lists..."
    
    # Check if NanoGPT is in AllModelProviders
    if grep -A 20 "var AllModelProviders" app/shared/ai_models_providers.go | grep -q "ModelProviderNanoGPT"; then
        log "✅ NanoGPT found in AllModelProviders"
    else
        error "❌ NanoGPT not found in AllModelProviders"
        return 1
    fi
    
    # Check if NanoGPT is in JSON schema
    if grep -q "\"nanogpt\"" app/cli/schema/json-schemas/definitions/model-providers.schema.json; then
        log "✅ NanoGPT found in JSON schema"
    else
        error "❌ NanoGPT not found in JSON schema"
        return 1
    fi
}

# Test that NanoGPT provider configuration exists
test_nanogpt_provider_config() {
    log "Testing NanoGPT provider configuration..."
    
    # Check if NanoGPT configuration exists in BuiltInModelProviderConfigs
    if grep -A 10 "ModelProviderNanoGPT:" app/shared/ai_models_providers.go | grep -q "Provider:.*ModelProviderNanoGPT"; then
        log "✅ NanoGPT provider configuration found"
    else
        error "❌ NanoGPT provider configuration not found"
        return 1
    fi
}

# Test that NanoGPT is available as provider for models
test_nanogpt_model_providers() {
    log "Testing NanoGPT as model provider..."
    
    # Check if NanoGPT is listed as a provider for GPT models
    if grep -A 5 "gpt-4.1" app/shared/ai_models_available.go | grep -q "ModelProviderNanoGPT"; then
        log "✅ NanoGPT found as provider for GPT models"
    else
        error "❌ NanoGPT not found as provider for GPT models"
        return 1
    fi

    # Check if NanoGPT is listed as a provider for Claude models
    if grep -A 5 "claude-3.5-sonnet" app/shared/ai_models_available.go | grep -q "ModelProviderNanoGPT"; then
        log "✅ NanoGPT found as provider for Claude models"
    else
        error "❌ NanoGPT not found as provider for Claude models"
        return 1
    fi
}

# Test that install script includes NanoGPT option
test_install_script_nanogpt() {
    log "Testing install script NanoGPT integration..."
    
    # Check if NanoGPT is mentioned in provider options
    if grep -q "NanoGPT.*Single API key for multiple AI providers" app/cli/install.sh; then
        log "✅ NanoGPT option found in install script"
    else
        error "❌ NanoGPT option not found in install script"
        return 1
    fi
    
    # Check if setup_nanogpt function exists
    if grep -q "setup_nanogpt ()" app/cli/install.sh; then
        log "✅ setup_nanogpt function found in install script"
    else
        error "❌ setup_nanogpt function not found in install script"
        return 1
    fi
    
    # Check if NANOGPT_API_KEY is in the search list
    if grep -A 10 "key_vars=(" app/cli/install.sh | grep -q "NANOGPT_API_KEY"; then
        log "✅ NANOGPT_API_KEY found in install script search list"
    else
        error "❌ NANOGPT_API_KEY not found in install script search list"
        return 1
    fi
}

# Test install script syntax
test_install_script_syntax() {
    log "Testing install script syntax..."
    
    if bash -n app/cli/install.sh; then
        log "✅ Install script syntax is valid"
    else
        error "❌ Install script has syntax errors"
        return 1
    fi
}

# Main test function
main() {
    log "=== NanoGPT Provider Integration Test Started at $(date) ==="
    
    # Run all tests
    test_nanogpt_provider_constants
    test_nanogpt_in_provider_lists
    test_nanogpt_provider_config
    test_nanogpt_model_providers
    test_install_script_nanogpt
    test_install_script_syntax
    
    log "=== All NanoGPT Provider Integration Tests Passed! ==="
}

# Run the tests
main "$@"
