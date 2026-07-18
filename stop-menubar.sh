#!/usr/bin/env bash
set -euo pipefail
pkill -x "Poise" 2>/dev/null || true
echo "Poise stopped."
