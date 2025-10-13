#!/bin/bash

# Test which models are available on NanoGPT subscription
# This script makes tiny test requests to different models to see which ones return 200 vs 402

NANOGPT_API_KEY="${NANOGPT_API_KEY}"
ENDPOINT="https://nano-gpt.com/api/subscription/v1/chat/completions"

# Test models
MODELS=(
    "claude-sonnet-4-5-20250929"
    "claude-sonnet-4-20250514"
    "claude-3-5-haiku-20241022"
    "gpt-4.1"
    "gpt-4.1-mini"
    "o4-mini"
    "o4-mini-high"
    "o4-mini-medium"
    "o4-mini-low"
    "gemini-2.5-pro"
    "gemini-2.5-flash"
    "gemini-pro-1.5"
    "deepseek-v3"
    "deepseek-r1"
    "glm-4.6"
)

echo "Testing NanoGPT subscription model availability..."
echo "=================================================="
echo ""

for model in "${MODELS[@]}"; do
    echo -n "Testing $model... "
    
    response=$(curl -s -w "\n%{http_code}" -X POST "$ENDPOINT" \
        -H "Authorization: Bearer $NANOGPT_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$model\",
            \"messages\": [{\"role\": \"user\", \"content\": \"hi\"}],
            \"max_tokens\": 5
        }")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" = "200" ]; then
        echo "✅ AVAILABLE (200)"
    elif [ "$http_code" = "402" ]; then
        echo "❌ NOT AVAILABLE (402 - Insufficient balance)"
    else
        echo "⚠️  ERROR ($http_code)"
        echo "   Response: $(echo "$body" | jq -c '.' 2>/dev/null || echo "$body")"
    fi
    
    # Small delay to avoid rate limiting
    sleep 0.5
done

echo ""
echo "=================================================="
echo "Test complete!"

