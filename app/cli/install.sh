#!/usr/bin/env bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

PLATFORM=
ARCH=
VERSION=
RELEASES_URL="https://github.com/plandex-ai/plandex/releases/download"
SETUP_TYPE=

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

prompt_setup_type () {
  echo ""
  echo "🔧 How would you like to use Plandex?"
  echo ""
  echo "  1) Plandex Cloud (hosted service - being deprecated)"
  echo "  2) Local Mode (self-hosted on your machine)"
  echo "  3) Just install the CLI (configure later)"
  echo ""
  read -p "Enter your choice [1-3]: " setup_choice
  echo ""
  
  case $setup_choice in
    1)
      echo "ℹ️  Note: Plandex Cloud is winding down as of 10/3/2025."
      echo "   We recommend using Local Mode instead."
      echo ""
      SETUP_TYPE="cloud"
      ;;
    2)
      SETUP_TYPE="local"
      ;;
    3)
      SETUP_TYPE="cli-only"
      ;;
    *)
      echo "❌ Invalid choice. Defaulting to CLI-only installation."
      SETUP_TYPE="cli-only"
      ;;
  esac
}

install_docker () {
  echo ""
  echo "🐳 Checking Docker installation..."
  
  if command -v docker >/dev/null 2>&1; then
    echo "✅ Docker is already installed"
    
    # Check if docker daemon is running
    if ! docker ps >/dev/null 2>&1; then
      echo "⚠️  Docker daemon is not running. Please start Docker and try again."
      return 1
    fi
    
    return 0
  fi
  
  echo ""
  echo "Docker is not installed. Docker is required for local mode."
  echo ""
  read -p "Would you like to install Docker now? [y/N]: " install_docker_choice
  
  if [[ ! "$install_docker_choice" =~ ^[Yy]$ ]]; then
    echo "❌ Docker installation skipped. You'll need to install Docker manually to use local mode."
    echo "   Visit https://docs.docker.com/get-docker/ for installation instructions."
    return 1
  fi
  
  echo ""
  echo "📦 Installing Docker..."
  
  if [[ "$PLATFORM" == "darwin" ]]; then
    echo ""
    echo "🍎 For macOS, please install Docker Desktop manually:"
    echo "   👉 https://docs.docker.com/desktop/install/mac-install/"
    echo ""
    echo "After installing Docker Desktop, run this installer again."
    return 1
  elif [[ "$PLATFORM" == "linux" ]]; then
    # Check if we can use sudo
    if ! hash sudo 2>/dev/null; then
      echo "❌ sudo is required to install Docker. Please install Docker manually."
      echo "   Visit https://docs.docker.com/engine/install/ for installation instructions."
      return 1
    fi
    
    # Install Docker on Linux
    echo "Installing Docker Engine on Linux..."
    
    # Update package index
    sudo apt-get update -qq || sudo yum check-update -q || true
    
    # Install Docker using the convenience script
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
    rm /tmp/get-docker.sh
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    # Start Docker service
    sudo systemctl start docker 2>/dev/null || sudo service docker start 2>/dev/null || true
    sudo systemctl enable docker 2>/dev/null || true
    
    echo ""
    echo "✅ Docker installed successfully!"
    echo ""
    echo "⚠️  IMPORTANT: You may need to log out and back in for Docker permissions to take effect."
    echo "   Or run: newgrp docker"
    echo ""
    
    return 0
  else
    echo "❌ Automatic Docker installation is not supported on this platform."
    echo "   Please install Docker manually: https://docs.docker.com/get-docker/"
    return 1
  fi
}

search_api_keys () {
  echo ""
  echo "🔑 Would you like to search your system for existing API keys?"
  echo "   This will search common locations for API keys from providers like:"
  echo "   - OpenRouter, OpenAI, Anthropic, Google, Azure, DeepSeek, Perplexity"
  echo ""
  read -p "Search for API keys? [y/N]: " search_choice
  
  if [[ ! "$search_choice" =~ ^[Yy]$ ]]; then
    echo "⏭️  API key search skipped."
    return
  fi
  
  echo ""
  echo "🔍 Searching for API keys in common locations..."
  
  local found_keys=()
  
  # Search in shell profile files
  local profile_files=(
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.zshrc"
    "$HOME/.profile"
    "$HOME/.config/fish/config.fish"
  )
  
  # Search in env files
  local env_files=(
    "$HOME/.env"
    "$HOME/.envrc"
  )
  
  # API key patterns to search for
  local key_vars=(
    "OPENROUTER_API_KEY"
    "OPENAI_API_KEY"
    "ANTHROPIC_API_KEY"
    "GEMINI_API_KEY"
    "GOOGLE_API_KEY"
    "AZURE_OPENAI_API_KEY"
    "DEEPSEEK_API_KEY"
    "PERPLEXITY_API_KEY"
  )
  
  # First check current environment
  for key_var in "${key_vars[@]}"; do
    if [ -n "${!key_var}" ]; then
      found_keys+=("$key_var")
    fi
  done
  
  # Search in profile files
  for file in "${profile_files[@]}" "${env_files[@]}"; do
    if [ -f "$file" ]; then
      for key_var in "${key_vars[@]}"; do
        if grep -q "export $key_var=" "$file" 2>/dev/null; then
          # Check if not already in found_keys
          if [[ ! " ${found_keys[@]} " =~ " ${key_var} " ]]; then
            found_keys+=("$key_var")
          fi
        fi
      done
    fi
  done
  
  if [ ${#found_keys[@]} -eq 0 ]; then
    echo "❌ No API keys found in common locations."
    echo ""
    echo "💡 You can set API keys manually later by adding them to your shell profile:"
    echo "   export OPENROUTER_API_KEY=your_key_here"
    echo ""
    return
  fi
  
  echo ""
  echo "✅ Found the following API keys in your environment:"
  for key in "${found_keys[@]}"; do
    echo "   • $key"
  done
  
  echo ""
  echo "💡 These API keys are available in your environment and will be used by Plandex."
  echo ""
}

setup_local_mode () {
  echo ""
  echo "🚀 Setting up Plandex in Local Mode..."
  echo ""
  
  # Check if git is installed
  if ! command -v git >/dev/null 2>&1; then
    echo "❌ git is required for local mode setup but is not installed."
    echo "   Please install git and try again."
    return 1
  fi
  
  # Install Docker if needed
  if ! install_docker; then
    echo ""
    echo "❌ Docker installation failed or was skipped."
    echo "   You can install Docker manually and run the setup again later."
    return 1
  fi
  
  # Check if docker-compose is available
  if ! command -v docker-compose >/dev/null 2>&1; then
    if ! docker compose version >/dev/null 2>&1; then
      echo "❌ docker-compose is required but not available."
      echo "   Please install docker-compose and try again."
      return 1
    fi
  fi
  
  # Search for API keys
  search_api_keys
  
  # Ask if user wants to start the server now
  echo ""
  echo "📋 Local mode setup instructions:"
  echo ""
  echo "   1. Clone the Plandex repository:"
  echo "      git clone https://github.com/plandex-ai/plandex.git"
  echo ""
  echo "   2. Start the local server:"
  echo "      cd plandex/app && ./start_local.sh"
  echo ""
  echo "   3. In a new terminal, sign in to your local server:"
  echo "      plandex sign-in"
  echo ""
  echo "   4. When prompted, select 'Local mode host' and confirm http://localhost:8099"
  echo ""
  echo "📚 Full documentation: https://docs.plandex.ai/hosting/self-hosting/local-mode-quickstart"
  echo ""
  
  read -p "Would you like to clone and start the server now? [y/N]: " start_server_choice
  
  if [[ "$start_server_choice" =~ ^[Yy]$ ]]; then
    echo ""
    echo "📦 Cloning Plandex repository..."
    
    local install_dir="$HOME/plandex-server"
    if [ -d "$install_dir" ]; then
      echo "⚠️  Directory $install_dir already exists."
      read -p "Use existing directory? [y/N]: " use_existing
      if [[ ! "$use_existing" =~ ^[Yy]$ ]]; then
        read -p "Enter a different directory path: " install_dir
      fi
    fi
    
    if [ ! -d "$install_dir" ]; then
      git clone https://github.com/plandex-ai/plandex.git "$install_dir"
    fi
    
    echo ""
    echo "🚀 Starting Plandex server..."
    echo "   The server will run in the background."
    echo "   To stop it later, run: cd $install_dir/app && docker compose down"
    echo ""
    
    cd "$install_dir/app"
    ./start_local.sh &
    
    echo ""
    echo "✅ Server is starting! Give it a few seconds to initialize."
    echo ""
    echo "   Next steps:"
    echo "   1. Wait for server startup (check with: docker ps)"
    echo "   2. Run: plandex sign-in"
    echo "   3. Select 'Local mode host' when prompted"
    echo ""
  fi
}

welcome_plandex
check_existing_installation
download_plandex

# Prompt for setup type if running interactively
if [ -t 0 ]; then
  prompt_setup_type
  
  case $SETUP_TYPE in
    local)
      setup_local_mode
      ;;
    cloud)
      echo ""
      echo "☁️  For Plandex Cloud, run 'plandex sign-in' and follow the prompts."
      echo ""
      ;;
    cli-only)
      echo ""
      echo "⚡️ CLI-only installation complete!"
      echo ""
      ;;
  esac
else
  # Non-interactive installation (e.g., piped from curl)
  SETUP_TYPE="cli-only"
fi

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

