#!/bin/bash
# install.sh — Add study-claude to your shell
#
# Usage: bash ~/dev/tools/claude-dopamine-sprint/scripts/install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_LINE="source \"${SCRIPT_DIR}/study-claude.sh\""
SHELL_RC="$HOME/.zshrc"

# Detect shell
if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == *zsh* ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ -n "${BASH_VERSION:-}" ]] || [[ "$SHELL" == *bash* ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

echo "Installing study-claude..."
echo "  Shell config: $SHELL_RC"
echo "  Source line:   $SOURCE_LINE"
echo ""

# Check if already installed
if grep -qF "study-claude.sh" "$SHELL_RC" 2>/dev/null; then
    echo "Already installed in $SHELL_RC. Nothing to do."
    exit 0
fi

# Append
echo "" >> "$SHELL_RC"
echo "# ADHD Study Claude — one-command learning launcher" >> "$SHELL_RC"
echo "$SOURCE_LINE" >> "$SHELL_RC"

echo "Installed! Restart your terminal or run:"
echo "  source $SHELL_RC"
echo ""
echo "Then type: study-claude"
