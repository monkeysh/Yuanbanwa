# scripts/

Audio + content pipeline. All scripts read from `scripts/.env` (gitignored).

## Setup

```bash
cp scripts/.env.example scripts/.env
# Then paste your ElevenLabs API key into the .env file.
```

---

## `elevenlabs-generate.py` — Native-speaker TTS

Generates per-sentence mp3 clips for every scene with the configured voices,
then patches `scenes.json` so the app picks them up.

### Typical run

```bash
# Render all scenes with all voices (default speed 0.9, slow + clear).
python3 scripts/elevenlabs-generate.py

# Just one voice / scene.
python3 scripts/elevenlabs-generate.py --voices bella --scenes starbucks

# Re-render existing files (default skips them).
python3 scripts/elevenlabs-generate.py --force

# Plan only.
python3 scripts/elevenlabs-generate.py --dry-run

# Tweaked render: slower (0.85) + steadier (stability 0.7).
python3 scripts/elevenlabs-generate.py --speed 0.85 --stability 0.7
```

After files are written, regenerate the Xcode project so the new clips are
bundled, then build:

```bash
/tmp/xcodegen/xcodegen/bin/xcodegen generate
xcodebuild ... build
```

### Output layout

```
Speak/Resources/audio/
├── bella/
│   ├── self-intro_01.mp3
│   ├── self-intro_02.mp3
│   ├── starbucks_01.mp3
│   └── ...
└── alice/
    ├── self-intro_01.mp3
    └── ...
```

Each sentence in `scenes.json` gets:

```json
{
  "en": "Can I have a grande latte, please?",
  ...,
  "audio": {
    "bella": "bella/starbucks_01.mp3",
    "alice": "alice/starbucks_01.mp3"
  }
}
```

The app's `AudioLibrary` reads `sentence.audio[voice.rawValue]` and falls back
to TTS when the key is missing. So partial coverage is safe — half-recorded
scenes still work.

---

## How to add a new voice (e.g. a child voice)

ElevenLabs has thousands of voices in their Voice Library. Adding one to our
app takes 5 minutes:

### 1. Add the voice to your ElevenLabs account

- Visit <https://elevenlabs.io/app/voice-library>
- Search "child" / "kid" / "young" / etc.
- Click a voice → preview → **"Add to Voices"** (free, no extra cost)
- Note the voice's name and voice ID (visible in Voices page after adding)

### 2. Register it in the script

Edit `scripts/elevenlabs-generate.py`, add to the `VOICES` dict:

```python
VOICES = {
    "bella": {"voice_id": "hpp4J3VqNfWAUOO0d1Us", "label": "Bella · US · ..."},
    "alice": {"voice_id": "Xb7hH8MSUJpSbSDYk0k2", "label": "Alice · UK · ..."},
    "lily":  {"voice_id": "<paste-the-new-voice-id>", "label": "Lily · child voice"},
}
```

### 3. Add the case to Swift

Edit `Speak/Audio/AudioLibrary.swift`:

```swift
enum VoicePreference: String, CaseIterable, Codable {
    case bella
    case alice
    case lily   // ← new

    var displayName: String {
        switch self {
        case .bella: return "美式 · Bella"
        case .alice: return "英式 · Alice"
        case .lily:  return "童声 · Lily"
        }
    }

    var fallbackLocale: String {
        switch self {
        case .bella, .lily: return "en-US"
        case .alice:        return "en-GB"
        }
    }
}
```

And `Speak/Views/Screens/MeScreen.swift` voice picker — add another button.

### 4. Generate + ship

```bash
python3 scripts/elevenlabs-generate.py --voices lily
/tmp/xcodegen/xcodegen/bin/xcodegen generate
# build + run
```

---

## `split-recording.py` — Slice human recordings (legacy, kept just in case)

For when teachers or voice actors send back long-form recordings instead of
per-sentence clips. Uses ffmpeg silencedetect.

```bash
python3 scripts/split-recording.py path/to/recording.m4a --voice <key> --scene <id>
```

See script `--help` for options. Most of the time `elevenlabs-generate.py`
is the right tool now.

---

## `build-script-pdf.py` — Re-generate the recording-script PDF

If `录音脚本/录音脚本.md` changes:

```bash
python3 scripts/build-script-pdf.py
```
