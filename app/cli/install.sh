#!/usr/bin/env bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

PLATFORM=
ARCH=
VERSION=
RELEASES_URL="https://github.com/plandex-ai/plandex/releases/download"

 # Ensure cleanup happens on exit and on specific signals
trap cleanup EXIT
trap cleanup INT TERM

cleanup () {
  cd "${SCRIPT_DIR}"
  rm -rf plandex_install_tmp
}

# Set platform
case "$(uname -s)" in
 Darwin)
   PLATFORM='darwin'
   ;;

 Linux)
   PLATFORM='linux'
   ;;

 FreeBSD)
   PLATFORM='freebsd'
   ;;

 CYGWIN*|MINGW*|MSYS*)
   PLATFORM='windows'
   ;;

 *)
   echo "Platform may or may not be supported. Will attempt to install."
   PLATFORM='linux'
   ;;
esac

if [[ "$PLATFORM" == "windows" ]]; then
  echo "🚨 Windows is only supported via WSL. It doesn't work in the Windows CMD prompt or PowerShell."
  echo "How to install WSL 👉 https://learn.microsoft.com/en-us/windows/wsl/about"
  exit 1
fi

# Set arch
if [[ "$(uname -m)" == 'x86_64' ]]; then
  ARCH="amd64"
elif [[ "$(uname -m)" == 'arm64' || "$(uname -m)" == 'aarch64' ]]; then
  ARCH="arm64"
fi

if [[ "$(cat /proc/1/cgroup 2> /dev/null | grep docker | wc -l)" > 0 ]] || [ -f /.dockerenv ]; then
  IS_DOCKER=true
else
  IS_DOCKER=false
fi

# Set Version
if [[ -z "${PLANDEX_VERSION}" ]]; then
  VERSION=$(curl -sL https://plandex.ai/v2/cli-version.txt)
else
  VERSION=$PLANDEX_VERSION
  echo "Using custom version $VERSION"
fi


search_api_keys () {
  echo ""
  echo "$(printf '%*s' "$(tput cols)" '' | tr ' ' -)"
  echo ""
  echo "🔍 Searching for API keys..."
  echo ""
  
  # Define API keys to search for
  declare -A api_keys=(
    ["OPENAI_API_KEY"]="OpenAI"
    ["ANTHROPIC_API_KEY"]="Anthropic"
    ["GEMINI_API_KEY"]="Google AI Studio"
    ["AZURE_OPENAI_API_KEY"]="Azure OpenAI"
    ["DEEPSEEK_API_KEY"]="DeepSeek"
    ["PERPLEXITY_API_KEY"]="Perplexity"
    ["OPENROUTER_API_KEY"]="OpenRouter"
  )
  
  # Files to search
  search_files=(
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.zshrc"
    "$HOME/.zshenv"
    "$HOME/.profile"
    "$HOME/.env"
    "$HOME/.env.local"
    "$(pwd)/.env"
    "$(pwd)/.env.local"
  )
  
  # Provider-specific config files
  provider_configs=(
    "$HOME/.claude/config"
    "$HOME/.openai/config"
    "$HOME/.anthropic/config"
    "$HOME/.deepseek/config"
    "$HOME/.perplexity/config"
    "$HOME/.azure/config"
    "$HOME/.gemini/config"
    "$HOME/.openrouter/config"
  )
  
  # Combine all search locations
  all_search_files=("${search_files[@]}" "${provider_configs[@]}")
  
  # Arrays to track found and missing keys
  declare -A found_keys
  declare -A missing_keys
  
  # Initialize all keys as missing
  for key in "${!api_keys[@]}"; do
    missing_keys[$key]="${api_keys[$key]}"
  done
  
  # Search in environment variables first
  for key in "${!api_keys[@]}"; do
    if [ -n "${!key}" ]; then
      found_keys[$key]="${api_keys[$key]}"
      unset missing_keys[$key]
    fi
  done
  
  # Search in files
  for file in "${all_search_files[@]}"; do
    if [ -f "$file" ]; then
      for key in "${!api_keys[@]}"; do
        if grep -q "^[[:space:]]*export[[:space:]]\+$key=" "$file" 2>/dev/null || \
           grep -q "^[[:space:]]*$key=" "$file" 2>/dev/null; then
          if [ -z "${found_keys[$key]}" ]; then
            found_keys[$key]="${api_keys[$key]}"
            unset missing_keys[$key]
          fi
        fi
      done
    fi
  done
  
  # Print results
  echo "✅ Found API keys:"
  if [ ${#found_keys[@]} -eq 0 ]; then
    echo "   None found"
  else
    for key in "${!found_keys[@]}"; do
      echo "   ✓ $key (${found_keys[$key]})"
    done
  fi
  
  echo ""
  echo "❌ Missing API keys:"
  if [ ${#missing_keys[@]} -eq 0 ]; then
    echo "   All supported providers have API keys configured!"
  else
    for key in "${!missing_keys[@]}"; do
      echo "   ✗ $key (${missing_keys[$key]})"
    done
    
    echo ""
    echo "$(printf '%*s' "$(tput cols)" '' | tr ' ' -)"
    echo ""
    echo "📖 How to get missing API keys:"
    echo ""
    
    # Provide instructions for each missing key
    for key in "${!missing_keys[@]}"; do
      case "$key" in
        "OPENAI_API_KEY")
          echo "🔹 OpenAI API Key:"
          echo "   Visit: https://platform.openai.com/api-keys"
          echo "   1. Sign in to your OpenAI account"
          echo "   2. Navigate to API Keys section"
          echo "   3. Click 'Create new secret key'"
          echo "   4. Copy the key and add to your environment:"
          echo "      export OPENAI_API_KEY='your-key-here'"
          echo ""
          ;;
        "ANTHROPIC_API_KEY")
          echo "🔹 Anthropic API Key:"
          echo "   Visit: https://console.anthropic.com/settings/keys"
          echo "   1. Sign in to your Anthropic account"
          echo "   2. Go to API Keys settings"
          echo "   3. Click 'Create Key'"
          echo "   4. Copy the key and add to your environment:"
          echo "      export ANTHROPIC_API_KEY='your-key-here'"
          echo ""
          ;;
        "GEMINI_API_KEY")
          echo "🔹 Google AI Studio API Key (Gemini):"
          echo "   Visit: https://aistudio.google.com/app/apikey"
          echo "   1. Sign in with your Google account"
          echo "   2. Click 'Create API Key'"
          echo "   3. Select or create a Google Cloud project"
          echo "   4. Copy the key and add to your environment:"
          echo "      export GEMINI_API_KEY='your-key-here'"
          echo ""
          ;;
        "AZURE_OPENAI_API_KEY")
          echo "🔹 Azure OpenAI API Key:"
          echo "   Visit: https://portal.azure.com"
          echo "   1. Sign in to Azure Portal"
          echo "   2. Navigate to your Azure OpenAI resource"
          echo "   3. Go to 'Keys and Endpoint' section"
          echo "   4. Copy KEY 1 or KEY 2 and add to your environment:"
          echo "      export AZURE_OPENAI_API_KEY='your-key-here'"
          echo "   Note: You'll also need AZURE_API_BASE and AZURE_API_VERSION"
          echo ""
          ;;
        "DEEPSEEK_API_KEY")
          echo "🔹 DeepSeek API Key:"
          echo "   Visit: https://platform.deepseek.com/api_keys"
          echo "   1. Sign in to your DeepSeek account"
          echo "   2. Navigate to API Keys section"
          echo "   3. Click 'Create API Key'"
          echo "   4. Copy the key and add to your environment:"
          echo "      export DEEPSEEK_API_KEY='your-key-here'"
          echo ""
          ;;
        "PERPLEXITY_API_KEY")
          echo "🔹 Perplexity API Key:"
          echo "   Visit: https://www.perplexity.ai/settings/api"
          echo "   1. Sign in to your Perplexity account"
          echo "   2. Navigate to API settings"
          echo "   3. Generate a new API key"
          echo "   4. Copy the key and add to your environment:"
          echo "      export PERPLEXITY_API_KEY='your-key-here'"
          echo ""
          ;;
        "OPENROUTER_API_KEY")
          echo "🔹 OpenRouter API Key:"
          echo "   Visit: https://openrouter.ai/keys"
          echo "   1. Sign in to your OpenRouter account"
          echo "   2. Navigate to Keys section"
          echo "   3. Click 'Create Key'"
          echo "   4. Copy the key and add to your environment:"
          echo "      export OPENROUTER_API_KEY='your-key-here'"
          echo ""
          ;;
      esac
    done
    
    echo "💡 To persist your API keys, add them to your shell profile (~/.bashrc, ~/.zshrc, etc.)"
    echo "   or create a .env file in your project directory."
    echo ""
    echo "📚 For more details, visit: https://docs.plandex.ai/models/model-providers"
  fi
  
  echo ""
  echo "$(printf '%*s' "$(tput cols)" '' | tr ' ' -)"
  echo ""
}

welcome_plandex () {
  echo ""
  echo "$(printf '%*s' "$(tput cols)" '' | tr ' ' -)"
  echo ""
  echo "🚀 Plandex v$VERSION • Quick Install"
  echo ""
  echo "$(printf '%*s' "$(tput cols)" '' | tr ' ' -)"
  echo ""
}

download_plandex () {
  ENCODED_TAG="cli%2Fv${VERSION}"

  url="${RELEASES_URL}/${ENCODED_TAG}/plandex_${VERSION}_${PLATFORM}_${ARCH}.tar.gz"

  mkdir -p plandex_install_tmp
  cd plandex_install_tmp

  echo "📥 Downloading Plandex tarball"
  echo ""
  echo "👉 $url"
  echo ""
  curl -s -L -o plandex.tar.gz "${url}"

  tar zxf plandex.tar.gz 1> /dev/null

  should_sudo=false

  if [ "$PLATFORM" == "darwin" ] || $IS_DOCKER ; then
    if [[ -d /usr/local/bin ]]; then
      if ! mv plandex /usr/local/bin/ 2>/dev/null; then
        echo "Permission denied when attempting to move Plandex to /usr/local/bin."
        if hash sudo 2>/dev/null; then
          should_sudo=true
          echo "Attempting to use sudo to complete installation."
          sudo mv plandex /usr/local/bin/
          if [[ $? -eq 0 ]]; then
            echo "✅ Plandex is installed in /usr/local/bin"
            echo ""
          else
            echo "Failed to install Plandex using sudo. Please manually move Plandex to a directory in your PATH."
            exit 1
          fi
        else
          echo "sudo not found. Please manually move Plandex to a directory in your PATH."
          exit 1
        fi
      else
        echo "✅ Plandex is installed in /usr/local/bin"
      fi
    else
      echo >&2 'Error: /usr/local/bin does not exist. Create this directory with appropriate permissions, then re-install.'
      exit 1
    fi
  else
    if [ $UID -eq 0 ]
    then
      # we are root
      mv plandex /usr/local/bin/
    elif hash sudo 2>/dev/null;
    then
      # not root, but can sudo
      sudo mv plandex /usr/local/bin/
      should_sudo=true
    else
      echo "ERROR: This script must be run as root or be able to sudo to complete the installation."
      exit 1
    fi

    echo "✅ Plandex is installed in /usr/local/bin"
  fi

  # create 'pdx' alias, but don't overwrite existing pdx command
  if [ ! -x "$(command -v pdx)" ]; then
    echo "🎭 Creating pdx alias..."
    LOC=$(which plandex)
    BIN_DIR=$(dirname "$LOC")

    if [ "$should_sudo" = true ]; then
      sudo ln -s "$LOC" "$BIN_DIR/pdx" && \
        echo "✅ Successfully created 'pdx' alias with sudo." || \
        echo "⚠️ Failed to create 'pdx' alias even with sudo. Please create it manually."
    else
      ln -s "$LOC" "$BIN_DIR/pdx" && \
        echo "✅ Successfully created 'pdx' alias." || \
        echo "⚠️ Failed to create 'pdx' alias. Please create it manually."
    fi
  fi
}

check_existing_installation () {
  if command -v plandex >/dev/null 2>&1; then
    existing_version=$(plandex version 2>/dev/null || echo "unknown")
    # Check if version starts with 1.x.x
    if [[ "$existing_version" =~ ^1\. ]]; then
      echo "Found existing Plandex v1.x installation ($existing_version). Renaming to 'plandex1' before installing v2..."
      
      # Get the location of existing binary
      existing_binary=$(which plandex)
      binary_dir=$(dirname "$existing_binary")
      
      # Rename plandex to plandex1
      if ! mv "$existing_binary" "${binary_dir}/plandex1" 2>/dev/null; then
        sudo mv "$existing_binary" "${binary_dir}/plandex1"
      fi
      
      # Rename pdx to pdx1 if it exists
      if [ -L "${binary_dir}/pdx" ]; then
        if ! mv "${binary_dir}/pdx" "${binary_dir}/pdx1" 2>/dev/null; then
          sudo mv "${binary_dir}/pdx" "${binary_dir}/pdx1"
        fi
        echo "Renamed 'pdx' alias to 'pdx1'"
      fi
      
      echo "Your v1.x installation is now accessible as 'plandex1' and 'pdx1'"
    fi
  fi
}

welcome_plandex
check_existing_installation
download_plandex

echo ""
echo "🎉 Installation complete"
echo ""
echo "$(printf '%*s' "$(tput cols)" '' | tr ' ' -)"
echo ""
echo "⚡️ Run 'plandex' or 'pdx' in any project directory and start building!"
echo ""
echo "$(printf '%*s' "$(tput cols)" '' | tr ' ' -)"
echo ""
echo "📚 Need help? 👉 https://docs.plandex.ai"
echo ""
echo "👋 Join a community of AI builders 👉 https://discord.gg/plandex-ai"
echo ""
echo "$(printf '%*s' "$(tput cols)" '' | tr ' ' -)"
echo ""

# Search for API keys and provide guidance
search_api_keys

