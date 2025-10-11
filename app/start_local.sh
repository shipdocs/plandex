#!/usr/bin/env bash

# Get the absolute path to the script's directory, regardless of where it's run from
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Change to the app directory if we're not already there
cd "$SCRIPT_DIR"

echo "Checking dependencies..."

if ! [ -x "$(command -v git)" ]; then
    echo 'Error: git is not installed.' >&2
    echo 'Please install git before running this setup script.' >&2
    exit 1
fi

if ! [ -x "$(command -v docker)" ]; then
    echo 'Error: docker is not installed.' >&2
    echo '' >&2
    echo 'Docker is required to run Plandex in local mode.' >&2
    echo '' >&2
    echo 'To install Docker:' >&2
    echo '  • Linux: curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh' >&2
    echo '  • macOS: Download Docker Desktop from https://docs.docker.com/desktop/install/mac-install/' >&2
    echo '  • Or run the Plandex installer again and select local mode setup.' >&2
    echo '' >&2
    exit 1
fi

# Check if Docker daemon is running
if ! docker ps >/dev/null 2>&1; then
    echo 'Error: Docker daemon is not running.' >&2
    echo '' >&2
    echo 'Please start Docker and try again:' >&2
    echo '  • macOS: Start Docker Desktop' >&2
    echo '  • Linux: sudo systemctl start docker' >&2
    echo '' >&2
    exit 1
fi

if ! [ -x "$(command -v docker-compose)" ]; then
    docker compose 2>&1 > /dev/null
    if [[ $? -ne 0 ]]; then
        echo 'Error: docker-compose is not installed.' >&2
        echo 'Please install docker-compose before running this setup script.' >&2
        exit 1
    fi
fi

echo "✅ All dependencies are installed"
echo ""
echo "Starting the local Plandex server and database..."
echo ""

docker compose pull plandex-server
docker compose up
