#!/bin/bash

# Setup GitHub Actions self-hosted runner for local Kind cluster
set -e

echo "🏃 Setting up GitHub Actions self-hosted runner..."

# Detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    RUNNER_ARCH="arm64"
    echo "📱 Detected Apple Silicon (M1/M2/M3) Mac"
elif [[ "$ARCH" == "x86_64" ]]; then
    RUNNER_ARCH="x64"
    echo "💻 Detected Intel Mac"
else
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
fi

# Create runner directory
mkdir -p ~/actions-runner && cd ~/actions-runner

# Download correct runner
echo "📥 Downloading runner for $RUNNER_ARCH..."
curl -o actions-runner-osx-${RUNNER_ARCH}-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-${RUNNER_ARCH}-2.311.0.tar.gz
tar xzf ./actions-runner-osx-${RUNNER_ARCH}-2.311.0.tar.gz

echo "✅ Runner downloaded successfully!"
echo ""
echo "🔧 NEXT STEPS:"
echo "1. Go to: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/settings/actions/runners"
echo "2. Click 'New self-hosted runner'"
echo "3. Select 'macOS' and '$RUNNER_ARCH'"
echo "4. Copy ONLY the './config.sh --url...' command from the 'Configure' section"
echo "5. Run it in this terminal (you're already in ~/actions-runner)"
echo "6. Then run: ./run.sh"