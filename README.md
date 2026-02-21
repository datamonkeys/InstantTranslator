# InstantTranslator

https://github.com/user-attachments/assets/005f94c7-b8b8-4977-883d-f5888ac81843

A lightweight macOS menu bar app that instantly translates selected text or fixes grammar using Claude AI.

Select any text, press a shortcut, and the translation replaces your selection in-place. No copy-pasting, no switching apps.

## Features

<img width="517" height="586" alt="Screenshot 2026-02-20 at 14 22 10" src="https://github.com/user-attachments/assets/883673d4-87e2-4bf1-96e2-b965cc8bba6b" />
<img width="307" height="324" alt="Screenshot 2026-02-20 at 14 22 57" src="https://github.com/user-attachments/assets/67c9a54f-48c4-47ba-920d-2843119e1dd6" />

- **Instant Translation** &mdash; Select text anywhere, press `⌥⇧T`, and it gets translated and pasted back automatically
- **Grammar Fix** &mdash; Press `⌥⇧G` to fix grammar and spelling in selected text
- **Paste & Translate** &mdash; Translate or fix text already in your clipboard from the menu bar
- **18 Languages** &mdash; English, Portuguese, Spanish, French, German, Italian, Chinese, Japanese, Korean, Russian, Arabic, Hindi, Dutch, Swedish, Polish, Turkish, Vietnamese
- **Auto-detect** &mdash; Automatically detects the source language; if already in the target language, translates to English instead
- **Menu Bar App** &mdash; Runs quietly in the menu bar, no Dock icon

## Requirements

- macOS 13 (Ventura) or later
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated

## Setup

1. Install the Claude CLI:
   ```bash
   brew install anthropics/claude/claude
   ```

2. Authenticate:
   ```bash
   claude setup-token
   ```

3. Build and run:
   ```bash
   chmod +x Scripts/build.sh
   ./Scripts/build.sh
   open InstantTranslator.app
   ```

4. Grant **Accessibility** permission when prompted (System Settings > Privacy & Security > Accessibility)

## Usage

| Shortcut | Action |
|----------|--------|
| `⌥⇧T` | Translate selected text |
| `⌥⇧G` | Fix grammar in selected text |

You can also right-click the menu bar icon for **Paste and Translate** or **Paste and Fix Grammar** options.

### Changing the target language

Click the menu bar icon > **Settings** to change the target language.

## How it works

InstantTranslator uses the Claude Code CLI with the `claude-haiku-4-5` model for fast, low-latency responses. When triggered:

1. Copies selected text via simulated `⌘C`
2. Sends it to Claude Haiku for translation/correction
3. Writes the result to the clipboard
4. Pastes it back via simulated `⌘V`

## Installing to Applications

```bash
cp -r InstantTranslator.app /Applications/
```

## Tech Stack

- Swift 5.9, SwiftUI
- Swift Package Manager
- Carbon framework (global hotkeys)
- Claude Code CLI (AI backend)

## License

MIT
