#!/bin/bash
# SessionStart hook for Claude Code on the web.
# Installs what the Speak project needs so validate / build / tests work in a cloud session.
set -euo pipefail

# Only run in remote (claude.ai/code) sessions; local sessions keep their own setup.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
WEB="$ROOT/speak/website"
SOE="$WEB/ops/speak-soe"

echo "[session-start] npm ci: speak/website"
(cd "$WEB" && npm ci --no-audit --no-fund --loglevel=error)

echo "[session-start] npm ci: speak/website/ops/speak-soe"
(cd "$SOE" && npm ci --no-audit --no-fund --loglevel=error)

# audio/ (ElevenLabs mp3s, ~2800 files) is intentionally not in version control.
# Without it, validate_site.mjs / build.mjs fail by default. In a cloud session we
# opt in to the explicit dev-only escape hatch so content/UI work can still be checked.
if [ ! -d "$WEB/audio" ]; then
  echo "[session-start] speak/website/audio/ 不存在（音频不入版本库）→ 设置 SPEAK_ALLOW_MISSING_AUDIO=1，validate/build 只警告不失败；此环境构建的 dist/ 不可部署"
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    echo 'export SPEAK_ALLOW_MISSING_AUDIO=1' >> "$CLAUDE_ENV_FILE"
  fi
fi

echo "[session-start] done"
