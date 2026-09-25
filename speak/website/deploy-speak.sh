#!/usr/bin/env bash
# Deploy speak.yuanbanwa.top to the Aliyun VPS.
# Usage: bash deploy-speak.sh [--dry-run] [--no-backup]
#
# `npm run build` creates a fresh dist/ from the explicit production contract.
# rsync mirrors only dist/, so --delete also removes forgotten test pages and
# other files that are not part of the verified build.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="yuanbanwa-server"  # SSH alias in ~/.ssh/config → root@121.43.54.252
REMOTE_PATH="/www/wwwroot/speak.yuanbanwa.top"
PORT="22"
DRY_RUN=0
NO_BACKUP=0

# Production payload whitelist. Adding a local file does not publish it unless
# it is explicitly listed here (or is an MP3 under an approved speaker).
ROOT_FILES=(
  index.html
  scenes.json
  terms.html
  privacy.html
)
ASSET_FILES=(
  assets/app-icon-180.png
)
AUDIO_SPEAKERS=(
  rosie
  chris
)

BUILD_DIR="$SCRIPT_DIR/dist"

usage() {
  cat <<'EOF'
Usage:
  bash deploy-speak.sh [options]

Options:
  --host <host>     SSH target, default yuanbanwa-server
  --path <path>     Remote deploy directory, default /www/wwwroot/speak.yuanbanwa.top
  --port <port>     SSH port, default 22
  --dry-run         rsync --dry-run — print what would change without uploading
  --no-backup       Do not snapshot the remote dir before syncing
  -h, --help        Show this help
EOF
}

die() { echo "Error: $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      [[ $# -ge 2 && -n "$2" ]] || die "--host requires a value"
      HOST="$2"
      shift 2
      ;;
    --path)
      [[ $# -ge 2 && -n "$2" ]] || die "--path requires a value"
      REMOTE_PATH="$2"
      shift 2
      ;;
    --port)
      [[ $# -ge 2 && -n "$2" ]] || die "--port requires a value"
      PORT="$2"
      shift 2
      ;;
    --dry-run) DRY_RUN=1; shift ;;
    --no-backup) NO_BACKUP=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

[[ -n "$HOST" ]] || die "--host is required"
[[ "$HOST" =~ ^[A-Za-z0-9][A-Za-z0-9._@-]*$ ]] || die "--host contains unsafe characters"
[[ -n "$REMOTE_PATH" ]] || die "--path is required"
[[ "$REMOTE_PATH" == /* ]] || die "--path must be an absolute remote path"
[[ "$REMOTE_PATH" =~ ^/[A-Za-z0-9._/-]+$ ]] || die "--path contains unsafe characters"
[[ "$REMOTE_PATH" != *//* ]] || die "--path must not contain repeated slashes"
[[ "$REMOTE_PATH" != */../* && "$REMOTE_PATH" != */.. ]] || die "--path must not contain '..' segments"
[[ "$REMOTE_PATH" != */./* && "$REMOTE_PATH" != */. ]] || die "--path must not contain '.' segments"
[[ "$REMOTE_PATH" == /www/wwwroot/* ]] || die "--path must stay below /www/wwwroot"

[[ "$PORT" =~ ^[0-9]+$ ]] || die "--port must be numeric"
PORT_NUMBER=$((10#$PORT))
(( PORT_NUMBER >= 1 && PORT_NUMBER <= 65535 )) || die "--port must be between 1 and 65535"
PORT="$PORT_NUMBER"

case "$REMOTE_PATH" in
  /|/www|/www/|/www/wwwroot|/www/wwwroot/)
    die "Refusing to deploy to a top-level directory: $REMOTE_PATH" ;;
esac

[[ "$REMOTE_PATH" == *speak* ]] || die "Refusing to deploy to a path that does not look like the speak site: $REMOTE_PATH"

# Validate every approved source before creating the payload. Symlinks are
# rejected so the deploy cannot accidentally copy content from outside the repo.
for file in "${ROOT_FILES[@]}" "${ASSET_FILES[@]}"; do
  [[ -f "$SCRIPT_DIR/$file" ]] || die "Missing file: $file"
  [[ ! -L "$SCRIPT_DIR/$file" ]] || die "Refusing symlink in production payload: $file"
done

shopt -s nullglob
for speaker in "${AUDIO_SPEAKERS[@]}"; do
  audio_dir="$SCRIPT_DIR/audio/$speaker"
  [[ -d "$audio_dir" && ! -L "$audio_dir" ]] || die "Missing or unsafe audio directory: audio/$speaker/"
  audio_files=("$audio_dir"/*.mp3)
  ((${#audio_files[@]} > 0)) || die "No MP3 files found in audio/$speaker/"
  for audio_file in "${audio_files[@]}"; do
    [[ -f "$audio_file" && ! -L "$audio_file" ]] || die "Refusing unsafe audio file: $audio_file"
  done
done
shopt -u nullglob

# Build an isolated, precompiled source tree. The build removes runtime Babel
# and external development React scripts, vendors production React locally,
# and recreates dist/ from scratch on every run.
[[ -f "$SCRIPT_DIR/package.json" && -f "$SCRIPT_DIR/package-lock.json" ]] || die "Missing package metadata; run npm install first"
[[ -d "$SCRIPT_DIR/node_modules" ]] || die "Missing node_modules; run npm ci first"
(cd "$SCRIPT_DIR" && npm run build)

[[ -d "$BUILD_DIR" && ! -L "$BUILD_DIR" ]] || die "Build did not create a safe dist/ directory"
for file in index.html scenes.json terms.html privacy.html build-manifest.json; do
  [[ -f "$BUILD_DIR/$file" && ! -L "$BUILD_DIR/$file" ]] || die "Build output missing or unsafe: $file"
done

# Defense in depth: even if the build script changes later, refuse to deploy
# any path outside the production contract.
while IFS= read -r built_file; do
  rel="${built_file#"$BUILD_DIR/"}"
  case "$rel" in
    index.html|scenes.json|terms.html|privacy.html|build-manifest.json|app.*.js|vendor/react.*.js|vendor/react-dom.*.js|assets/app-icon-180.png|audio/rosie/*.mp3|audio/chris/*.mp3) ;;
    *) die "Unexpected file in production build: $rel" ;;
  esac
  [[ ! -L "$built_file" ]] || die "Refusing symlink in production build: $rel"
done < <(find "$BUILD_DIR" -type f -o -type l | sort)

shopt -s nullglob
app_bundles=("$BUILD_DIR"/app.*.js)
react_bundles=("$BUILD_DIR"/vendor/react.*.js)
react_dom_bundles=("$BUILD_DIR"/vendor/react-dom.*.js)
shopt -u nullglob
(( ${#app_bundles[@]} == 1 )) || die "Expected exactly one app bundle"
(( ${#react_bundles[@]} == 1 )) || die "Expected exactly one React bundle"
(( ${#react_dom_bundles[@]} == 1 )) || die "Expected exactly one React DOM bundle"

echo "Verified production build:"
sed 's/^/  /' "$BUILD_DIR/build-manifest.json"
du -sh "$BUILD_DIR" | sed 's/^/  total: /'

SSH_OPTIONS=(-p "$PORT" -o StrictHostKeyChecking=accept-new)
RSYNC_SSH="ssh -p $PORT -o StrictHostKeyChecking=accept-new"

# Refuse a symlink or non-directory at the destination before rsync --delete.
# This check is read-only, so it is also safe during --dry-run.
ssh "${SSH_OPTIONS[@]}" "$HOST" \
  "if [ -L '$REMOTE_PATH' ]; then echo 'Remote deploy path is a symlink' >&2; exit 1; fi; if [ -e '$REMOTE_PATH' ] && [ ! -d '$REMOTE_PATH' ]; then echo 'Remote deploy path is not a directory' >&2; exit 1; fi"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo
  echo "Dry run — rsync plan:"
  rsync -avzn --delete --no-owner --no-group --itemize-changes \
    -e "$RSYNC_SSH" \
    "$BUILD_DIR/" "$HOST:$REMOTE_PATH/" \
    | sed 's/^/  /'
  exit 0
fi

# Snapshot the remote dir before we touch anything. Cheap (mostly a cp -a
# between two directories on the same filesystem) and reversible via
# `mv $REMOTE_PATH.bak.<ts> $REMOTE_PATH`.
if [[ "$NO_BACKUP" -eq 0 ]]; then
  echo "Creating remote backup snapshot..."
  BACKUP_TS="$(date +%Y%m%d-%H%M%S)"
  BACKUP_PATH="${REMOTE_PATH}.bak.${BACKUP_TS}"
  ssh "${SSH_OPTIONS[@]}" "$HOST" \
    "if [ -d '$REMOTE_PATH' ] && [ -n \"\$(find '$REMOTE_PATH' -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)\" ]; then if [ -e '$BACKUP_PATH' ]; then echo 'Backup path already exists: $BACKUP_PATH' >&2; exit 1; fi; cp -a -- '$REMOTE_PATH' '$BACKUP_PATH'; else echo '  (remote dir empty — skipping backup)'; fi"
fi

echo "Ensuring remote path exists..."
ssh "${SSH_OPTIONS[@]}" "$HOST" "mkdir -p -- '$REMOTE_PATH'"

echo "Syncing files to $HOST:$REMOTE_PATH ..."
rsync -avz --delete --no-owner --no-group \
  -e "$RSYNC_SSH" \
  "$BUILD_DIR/" "$HOST:$REMOTE_PATH/"

echo "Fixing perms + ownership for nginx..."
ssh "${SSH_OPTIONS[@]}" "$HOST" \
  "chmod -R a+rX '$REMOTE_PATH' && chown -R www:www '$REMOTE_PATH'"

echo
echo "Deploy complete: $REMOTE_PATH"
echo "Verify: https://speak.yuanbanwa.top"
