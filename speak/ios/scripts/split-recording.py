#!/usr/bin/env python3
"""
Split a long teacher recording into per-sentence clips using ffmpeg's
silencedetect. Run once per recording (8 scenes × 2 teachers = 16 runs).

Usage:
  python3 split-recording.py <input.m4a> --voice adai|xiaohe --scene <scene-id>

Output:
  Speak/Resources/audio/<voice>/<scene>_01.m4a
  Speak/Resources/audio/<voice>/<scene>_02.m4a
  ...

Also prints a JSON snippet you can paste into scenes.json as the
`audioAdai` / `audioXiaohe` fields per sentence.
"""

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SCENES_JSON = REPO_ROOT / "Speak" / "Resources" / "scenes.json"
AUDIO_ROOT = REPO_ROOT / "Speak" / "Resources" / "audio"


def expected_sentences(scene_id: str) -> list[str]:
    """Return the target sentence list from scenes.json, in order."""
    data = json.loads(SCENES_JSON.read_text(encoding="utf-8"))
    for s in data["scenes"]:
        if s["id"] == scene_id:
            return [sent["en"] for sent in s["sentences"]]
    raise SystemExit(f"scene '{scene_id}' not found in scenes.json")


def detect_silences(audio_path: Path, min_silence: float, noise_db: float) -> list[tuple[float, float]]:
    """
    Returns list of (silence_start, silence_end) in seconds.
    Uses `ffmpeg -af silencedetect` and parses stderr.
    """
    cmd = [
        "ffmpeg", "-nostdin", "-i", str(audio_path),
        "-af", f"silencedetect=noise={noise_db}dB:d={min_silence}",
        "-f", "null", "-",
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    lines = proc.stderr.splitlines()

    starts: list[float] = []
    ends: list[float] = []
    for line in lines:
        m = re.search(r"silence_start:\s*([\d.]+)", line)
        if m:
            starts.append(float(m.group(1)))
            continue
        m = re.search(r"silence_end:\s*([\d.]+)", line)
        if m:
            ends.append(float(m.group(1)))
    # Pair them (silence_start, silence_end). FFmpeg emits start before end for each silence.
    return list(zip(starts, ends))


def get_duration(audio_path: Path) -> float:
    cmd = [
        "ffprobe", "-v", "quiet", "-print_format", "json", "-show_format", str(audio_path),
    ]
    out = subprocess.check_output(cmd, text=True)
    return float(json.loads(out)["format"]["duration"])


def compute_cuts(silences: list[tuple[float, float]], total_duration: float) -> list[tuple[float, float]]:
    """
    Turn silences into speech segments. Each segment starts at the previous
    silence midpoint (or 0) and ends at the next silence midpoint (or total).
    """
    cuts: list[tuple[float, float]] = []
    last = 0.0
    for (sil_start, sil_end) in silences:
        if sil_start <= last:
            continue
        midpoint = (sil_start + sil_end) / 2
        cuts.append((last, sil_start + 0.05))  # trail 50ms of speech
        last = max(midpoint, sil_end - 0.1)    # start next clip just before audio resumes
    if last < total_duration - 0.1:
        cuts.append((last, total_duration))
    return cuts


def slice_clips(audio_path: Path, cuts: list[tuple[float, float]],
                out_dir: Path, scene: str) -> list[Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    for i, (start, end) in enumerate(cuts, start=1):
        out = out_dir / f"{scene}_{i:02d}.m4a"
        duration = end - start
        if duration <= 0.4:
            continue  # skip very short spurious cuts
        cmd = [
            "ffmpeg", "-y", "-nostdin", "-loglevel", "error",
            "-i", str(audio_path),
            "-ss", f"{start:.3f}", "-t", f"{duration:.3f}",
            "-c:a", "aac", "-b:a", "96k",
            str(out),
        ]
        subprocess.run(cmd, check=True)
        written.append(out)
    return written


def main():
    p = argparse.ArgumentParser()
    p.add_argument("input", type=Path, help="Path to recorded m4a/wav file")
    p.add_argument("--voice", required=True, choices=["adai", "xiaohe"])
    p.add_argument("--scene", required=True, help="Scene ID from scenes.json, e.g. starbucks")
    p.add_argument("--noise-db", type=float, default=-35.0,
                   help="silencedetect noise threshold (dB, lower = more aggressive)")
    p.add_argument("--min-silence", type=float, default=0.8,
                   help="Minimum silence duration to split on (seconds)")
    p.add_argument("--dry-run", action="store_true",
                   help="Print cut plan without writing files")
    args = p.parse_args()

    if not args.input.exists():
        sys.exit(f"missing: {args.input}")

    targets = expected_sentences(args.scene)
    total = get_duration(args.input)
    silences = detect_silences(args.input, args.min_silence, args.noise_db)
    cuts = compute_cuts(silences, total)

    print(f"Detected {len(silences)} silences, {len(cuts)} speech segments")
    print(f"Expected {len(targets)} sentences for scene '{args.scene}'")
    if len(cuts) != len(targets):
        print(f"⚠️  Mismatch. Try --noise-db -30 or --min-silence 0.6 if too few,")
        print(f"   or --min-silence 1.2 if too many. Dry-run first with --dry-run.")

    print("\nCut plan:")
    for i, (start, end) in enumerate(cuts, start=1):
        label = targets[i - 1] if i <= len(targets) else "(overflow)"
        print(f"  {i:02d}  {start:6.2f}s – {end:6.2f}s  ({end-start:5.2f}s)  {label[:48]}")

    if args.dry_run:
        return

    out_dir = AUDIO_ROOT / args.voice
    written = slice_clips(args.input, cuts, out_dir, args.scene)
    print(f"\n✅ Wrote {len(written)} clips to {out_dir}/")

    # Print the JSON patch so you can paste into scenes.json.
    field = "audioAdai" if args.voice == "adai" else "audioXiaohe"
    print(f"\n--- paste into the scene's sentences (under `{field}`): ---")
    for i, path in enumerate(written[:len(targets)], start=1):
        rel = f"{args.voice}/{path.name}"
        print(f'  [{i-1}] "{field}": "{rel}"')


if __name__ == "__main__":
    main()
