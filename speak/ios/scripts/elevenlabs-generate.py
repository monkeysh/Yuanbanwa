#!/usr/bin/env python3
"""
Batch-generate native-speaker mp3 clips with ElevenLabs and patch
scenes.json so the app picks them up.

Run from the project root:

    python3 scripts/elevenlabs-generate.py
    python3 scripts/elevenlabs-generate.py --voices bella       # one voice
    python3 scripts/elevenlabs-generate.py --scenes starbucks   # one scene
    python3 scripts/elevenlabs-generate.py --dry-run            # plan only

Reads ELEVENLABS_API_KEY from scripts/.env.
"""

from __future__ import annotations
import argparse
import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SCENES_JSON = REPO_ROOT / "Speak" / "Resources" / "scenes.json"
AUDIO_ROOT = REPO_ROOT / "Speak" / "Resources" / "audio"
ENV_FILE = REPO_ROOT / "scripts" / ".env"


# Audio file naming. The 初级 tier — which has been around since v0.1 —
# keeps the original `<voice>/<scene>_<idx>.mp3` naming so we don't have
# to re-render the existing 892 clips. New tiers slot in their level
# name as a middle segment: `<voice>/<scene>_<level>_<idx>.mp3`.
def audio_rel_path(voice_key: str, scene_id: str, level: str, idx: int) -> str:
    if level == "beginner":
        return f"{voice_key}/{scene_id}_{idx:02d}.mp3"
    return f"{voice_key}/{scene_id}_{level}_{idx:02d}.mp3"

# Voice catalogue. Adding a new voice = add an entry here + a `case` in
# AudioLibrary.swift (the JSON keys auto-flow to the app).
VOICES = {
    "bella": {
        "voice_id": "hpp4J3VqNfWAUOO0d1Us",
        "label": "Bella · US female · Professional, Bright, Warm",
    },
    "alice": {
        "voice_id": "Xb7hH8MSUJpSbSDYk0k2",
        "label": "Alice · UK female · Clear, Engaging Educator",
    },
    "chris": {
        "voice_id": "iP95p4xoKVk53GoZ742B",
        "label": "Chris · US male · Charming, Down-to-Earth",
    },
    "george": {
        "voice_id": "JBFqnCBsd6RMkjVDRZzb",
        "label": "George · UK male · Warm, Captivating Storyteller",
    },
}

# Default render parameters tuned for learning content (clear + paced).
# speed 0.8 after user feedback that 0.9 felt rushed for learners — the
# 0.8 setting lingers on content words, gives vowel time to breathe, and
# matches the cadence of a patient tutor reading aloud. Higher stability
# (0.65) reinforces this by trading a little expressiveness for a more
# even, deliberate delivery.
DEFAULT_SETTINGS = {
    "stability": 0.65,
    "similarity_boost": 0.75,
    "style": 0.0,
    "use_speaker_boost": True,
    "speed": 0.8,
}
MODEL_ID = "eleven_multilingual_v2"


def load_api_key() -> str:
    if not ENV_FILE.exists():
        sys.exit(f"missing {ENV_FILE} — copy scripts/.env.example and fill in your key")
    for line in ENV_FILE.read_text().splitlines():
        line = line.strip()
        if line.startswith("ELEVENLABS_API_KEY="):
            return line.split("=", 1)[1].strip().strip('"')
    sys.exit("ELEVENLABS_API_KEY not found in scripts/.env")


def synth(api_key: str, voice_id: str, text: str, out_path: Path,
          settings: dict, max_attempts: int = 5) -> int:
    """Call TTS via curl (avoids macOS Python SSL cert hassles), write mp3.
    Retries transient network errors (connection reset, 5xx, timeout) with
    exponential backoff. ElevenLabs drops long-lived connections occasionally;
    the previous implementation would kill the whole batch on the first drop.
    """
    payload = json.dumps({
        "text": text,
        "model_id": MODEL_ID,
        "voice_settings": settings,
    })
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
        f.write(payload)
        payload_path = f.name

    last_err = ""
    try:
        for attempt in range(1, max_attempts + 1):
            result = subprocess.run(
                [
                    "curl", "-sS", "-X", "POST",
                    "--max-time", "90",
                    "--connect-timeout", "15",
                    "-H", f"xi-api-key: {api_key}",
                    "-H", "Content-Type: application/json",
                    "-H", "Accept: audio/mpeg",
                    "--data-binary", f"@{payload_path}",
                    "-o", str(out_path),
                    "-w", "%{http_code}",
                    f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}",
                ],
                capture_output=True, text=True, check=False, timeout=120,
            )
            code = result.stdout.strip()
            if result.returncode == 0 and code == "200":
                return out_path.stat().st_size

            # Permanent auth / bad-request failures — bail loud.
            if code in ("400", "401", "403", "404"):
                body = out_path.read_text(errors="replace") if out_path.exists() else ""
                raise SystemExit(f"HTTP {code} from ElevenLabs:\n{body[:500]}")

            # Transient (connection reset, 5xx, timeout) — back off + retry.
            last_err = f"rc={result.returncode} code={code or 'none'} stderr={result.stderr.strip()[:200]}"
            if attempt < max_attempts:
                sleep_s = 1.5 * (2 ** (attempt - 1))  # 1.5, 3, 6, 12, 24
                print(f"    ⚠ attempt {attempt}/{max_attempts} transient error ({last_err}); retry in {sleep_s:.0f}s")
                time.sleep(sleep_s)

        raise SystemExit(f"synth gave up after {max_attempts} attempts: {last_err}")
    finally:
        os.unlink(payload_path)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--voices", nargs="+", default=list(VOICES.keys()),
                   choices=list(VOICES.keys()),
                   help="Which voices to render (default: all)")
    p.add_argument("--scenes", nargs="+", default=None,
                   help="Filter to these scene IDs (default: all)")
    p.add_argument("--speed", type=float, default=DEFAULT_SETTINGS["speed"],
                   help="0.7 (slowest) – 1.2 (fastest). Default 0.9.")
    p.add_argument("--stability", type=float, default=DEFAULT_SETTINGS["stability"])
    p.add_argument("--force", action="store_true",
                   help="Re-render existing files (default: skip if mp3 already there)")
    p.add_argument("--dry-run", action="store_true",
                   help="Print the plan + char count without calling the API")
    args = p.parse_args()

    api_key = load_api_key()
    catalog = json.loads(SCENES_JSON.read_text(encoding="utf-8"))

    settings = dict(DEFAULT_SETTINGS, speed=args.speed, stability=args.stability)

    # Build the work list. Iterates over tiers — every scene now has at
    # least one tier (we wrap legacy non-tiered scenes as a single
    # 初级 tier in seed-tiers.py), so this is the single source of truth.
    #
    # File naming convention:
    #   - 初级 tier:  <voice>/<scene_id>_<idx>.mp3      (existing files keep names)
    #   - any other:  <voice>/<scene_id>_<level>_<idx>.mp3
    todo = []
    total_chars = 0
    for scene in catalog["scenes"]:
        if args.scenes and scene["id"] not in args.scenes:
            continue
        tiers = scene.get("tiers") or [{
            "level": "beginner",
            "sentences": scene.get("sentences", []),
        }]
        for tier in tiers:
            level = tier["level"]
            for idx, sentence in enumerate(tier["sentences"], start=1):
                for voice_key in args.voices:
                    voice = VOICES[voice_key]
                    rel_path = audio_rel_path(voice_key, scene["id"], level, idx)
                    out_path = AUDIO_ROOT / rel_path
                    exists = out_path.exists()
                    if exists and not args.force:
                        continue
                    todo.append({
                        "scene_id": scene["id"],
                        "tier_level": level,
                        "sentence_idx_zero_based": idx - 1,
                        "voice_key": voice_key,
                        "voice_id": voice["voice_id"],
                        "text": sentence["en"],
                        "rel_path": rel_path,
                        "out_path": out_path,
                    })
                    total_chars += len(sentence["en"])

    print(f"Plan: {len(todo)} clips · {total_chars:,} characters · speed={args.speed}")
    if not todo:
        print("Nothing to do (use --force to re-render).")
        # Still patch scenes.json so existing files get linked.
    if args.dry_run:
        for item in todo[:6]:
            print(f"  {item['voice_key']:6s}  {item['scene_id']}/{item['sentence_idx_zero_based']+1:02d}  {item['text'][:50]}…")
        if len(todo) > 6:
            print(f"  … + {len(todo) - 6} more")
        return

    # Generate.
    for i, item in enumerate(todo, start=1):
        size = synth(api_key, item["voice_id"], item["text"], item["out_path"], settings)
        print(f"  [{i:>3}/{len(todo)}]  {item['voice_key']}/{item['scene_id']}_{item['sentence_idx_zero_based']+1:02d}  "
              f"({size // 1024} KB)  {item['text'][:50]}")
        # Free tier rate limit is generous; 0.2s between calls is courteous.
        time.sleep(0.2)

    # Patch scenes.json: ensure every sentence has audio[voice] keys for any
    # mp3 that exists on disk. Idempotent — safe to re-run.
    print("\nPatching scenes.json…")
    for scene in catalog["scenes"]:
        tiers = scene.get("tiers") or [{
            "level": "beginner",
            "sentences": scene.get("sentences", []),
        }]
        for tier in tiers:
            level = tier["level"]
            for idx, sentence in enumerate(tier["sentences"], start=1):
                audio = sentence.get("audio") or {}
                for voice_key in VOICES.keys():
                    rel = audio_rel_path(voice_key, scene["id"], level, idx)
                    if (AUDIO_ROOT / rel).exists():
                        audio[voice_key] = rel
                if audio:
                    sentence["audio"] = audio

    SCENES_JSON.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"  → {SCENES_JSON.relative_to(REPO_ROOT)}")
    print("\n✅ Done. Run xcodegen + build to ship the audio in the bundle.")


if __name__ == "__main__":
    main()
