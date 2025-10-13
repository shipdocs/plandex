# NanoGPT Subscription - Available Models Analysis

## Summary

Your NanoGPT subscription includes **open-source and smaller models only**. Premium models like Claude Sonnet 4/4.5, GPT-4.1 full, and Gemini are **NOT included** and return 402 "Insufficient balance" errors.

## ✅ Models Available on Your Subscription

### Anthropic
- **Claude 3.5 Haiku** (`claude-3-5-haiku-20241022`)
  - Fast, efficient, good for simple tasks
  - **CONFIRMED WORKING** (200 response, cost: 0)

### OpenAI
- **GPT-4.1-mini** (`gpt-4.1-mini`)
  - Fast for simple naming/commits
  - **CONFIRMED WORKING** (200 response)
  
- **o4-mini** (`o4-mini`)
  - Good for structured tasks
  - **CONFIRMED WORKING** (200 response)
  
- **o4-mini variants** (`o4-mini-high`, `o4-mini-medium`, `o4-mini-low`)
  - Likely available (not fully tested due to long thinking times)

### DeepSeek
- **DeepSeek Chat** (`deepseek-chat`)
  - Fast, capable coding model
  - **CONFIRMED WORKING** (200 response)
  
- **DeepSeek R1** (`deepseek-r1`)
  - Strong reasoning model with visible/hidden reasoning modes
  - **CONFIRMED WORKING** (200 response)
  
- **DeepSeek V3.1 variants**
  - `deepseek-ai/DeepSeek-V3.1`
  - `deepseek-ai/DeepSeek-V3.1-Terminus`
  - `deepseek-ai/DeepSeek-V3.1:thinking`
  - Listed in subscription endpoint (not tested)



## ❌ Models NOT Available (402 Errors)

### Anthropic
- **Claude Sonnet 4.5** (`claude-sonnet-4-5-20250929`)
  - Returns 402 "Insufficient balance"
  
- **Claude Sonnet 4** (`claude-sonnet-4-20250514`)
  - Returns 402 "Insufficient balance"

### OpenAI
- **GPT-4.1** (full version)
  - Returns 402 "Insufficient balance"

### Google
- **Gemini models**
  - Not listed in subscription endpoint
  - Likely not available

### Zhipu AI
- **GLM-4.6** (`glm-4.6`)
  - Returns 402 "Insufficient balance"
  - Listed in subscription endpoint but not actually available

- **GLM-4.6 Thinking** (`glm-4.6:thinking`)
  - Returns 402 "Insufficient balance"
  - Listed in subscription endpoint but not actually available

## Optimal Model Pack Configuration

Based on available models and their capabilities:

### Current Working Configuration
```json
{
  "planner": "deepseek/r1:hidden",
  "architect": "deepseek/r1:hidden",
  "coder": "deepseek/v3",
  "summarizer": "anthropic/claude-3.5-haiku",
  "builder": "deepseek/r1:hidden",
  "wholeFileBuilder": "deepseek/r1:hidden",
  "names": "openai/gpt-4.1-mini",
  "commitMessages": "openai/gpt-4.1-mini",
  "autoContinue": "anthropic/claude-3.5-haiku"
}
```

### Rationale
- **Planner/Architect**: DeepSeek R1 (hidden reasoning) - Strong reasoning for planning
- **Coder**: DeepSeek V3 - Fast, capable coding model
- **Builder**: DeepSeek R1 (hidden reasoning) - Reasoning for complex file building
- **Summarizer**: Claude 3.5 Haiku - Fast, efficient for simple tasks
- **Names/Commits**: GPT-4.1-mini - Fast for simple naming tasks
- **AutoContinue**: Claude 3.5 Haiku - Fast, cheap

### Future Configuration (Once GLM-4.6 is integrated)
```json
{
  "planner": "zhipu/glm-4.6",
  "architect": "zhipu/glm-4.6",
  "coder": "zhipu/glm-4.6",
  "summarizer": "anthropic/claude-3.5-haiku",
  "builder": "deepseek/r1:hidden",
  "wholeFileBuilder": "deepseek/r1:hidden",
  "names": "openai/gpt-4.1-mini",
  "commitMessages": "openai/gpt-4.1-mini",
  "autoContinue": "anthropic/claude-3.5-haiku"
}
```

**Why DeepSeek for advanced tasks:**
- DeepSeek R1 has strong reasoning capabilities
- DeepSeek V3 is fast and capable for coding
- Both confirmed working on your subscription at no cost

## Testing Results

### Test Script
Created `test-nanogpt-models.sh` to systematically test model availability.

### Key Findings
1. **Subscription endpoint** (`https://nano-gpt.com/api/subscription/v1`) only lists open-source/cheaper models
2. **Balance endpoint** (`https://nano-gpt.com/api/v1`) lists all models but charges per-use
3. **402 errors** indicate model not included in subscription, not a technical issue
4. **Cost: 0** in response indicates subscription coverage (no per-use charges)

## Recommendations

### Short Term
1. Use the current working configuration with DeepSeek models
2. This provides strong performance for most tasks
3. All models are confirmed working on your subscription

### Long Term
1. **Add GLM-4.6 to Plandex** - Requires completing the model definition integration
2. **Consider subscription upgrade** if you need Claude Sonnet 4.5 or GPT-4.1 full
3. **Monitor NanoGPT pricing** for changes to subscription tiers

## Technical Notes

### Model Integration Status
- ✅ DeepSeek models: Fully integrated in Plandex
- ✅ Claude 3.5 Haiku: Fully integrated in Plandex
- ✅ OpenAI o4-mini/GPT-4.1-mini: Fully integrated in Plandex
- ⚠️ GLM-4.6: Added to codebase but needs server rebuild to work
  - Added `ModelPublisherZhipu` constant
  - Added GLM-4.6 model definition with variants
  - Server built successfully but model lookup failing (needs debugging)

### Files Modified
- `app/shared/ai_models_available.go` - Added GLM-4.6 model definition
- `app/shared/ai_models_providers.go` - Added Zhipu publisher
- `app/shared/ai_models_credentials.go` - Added Zhipu to multi-provider list
- `model-packs/nanogpt-subscription-available.json` - Optimal model pack

### Next Steps to Enable GLM-4.6
1. Debug why `BuiltInBaseModelsById` lookup is failing for GLM-4.6
2. Verify model ID format matches what's expected
3. Test model pack with GLM-4.6 once integrated
4. Update default model pack if GLM-4.6 performs well

