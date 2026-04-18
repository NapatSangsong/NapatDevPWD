# Napat Dev

A simple personal password manager for macOS. Local-only, no sign-in, no
third-party server, data encrypted at rest with a master-password-derived key.

Based on the Napat Dev design prototype in [`design/`](design/Napat%20Dev.html).

## Status

Working first pass. SwiftUI + CryptoKit, single macOS target. No external
dependencies at runtime; the Xcode project is generated from `project.yml` via
[XcodeGen](https://github.com/yonaskolb/XcodeGen).

## Requirements

- macOS 14 Sonoma or later
- Xcode 15.3+
- Free Apple ID (no paid Developer Program needed for personal use)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — installed automatically
  by `./setup.sh` if Homebrew is present

## Getting started

```sh
./setup.sh                 # installs xcodegen if needed, generates NapatDev.xcodeproj
open NapatDev.xcodeproj
```

Then in Xcode: select the **NapatDev-macOS** target → *Signing & Capabilities*
→ Team → pick your personal Apple ID. Hit ⌘R to launch.

## Project layout

```
NapatDev/
├── App/               @main entry + app-lock state machine
├── Models/            Vault, VaultItem (Codable structs), VaultStore
├── Security/          PBKDF2, AES-GCM, Keychain, biometric auth, clipboard auto-clear
├── Theme/             Design tokens, typography, BrandMark icons
├── Assistant/         Claude API client, tools, chat view-model
├── Views/
│   ├── Unlock/        Onboarding + unlock screens
│   ├── Shared/        FieldRow, PasswordReveal, ItemRow, ItemEditor, ChatView, ProposalCard
│   └── macOS/         NavigationSplitView, menu-bar popover
├── Platform/          macOS-only: LoginItem (SMAppService), GlobalHotkey (Carbon)
├── Resources/         Assets.xcassets (AppIcon, AccentColor), bundled Fonts
└── Supporting/        Entitlements, Secrets.plist (gitignored)
design/                The original Napat Dev.html prototype for reference
tools/                 generate_icon.swift + rendered PNG inputs for AppIcon
```

## How it works

- **Master password** — set on first launch. PBKDF2-HMAC-SHA256 (600 000
  iterations) + random 16-byte salt derives a 32-byte AES-GCM key. Salt and a
  known-plaintext verifier live in Keychain; the derived key is held in
  memory only while the app is unlocked.
- **Vault file** — one `vault.napatvault` file at
  `~/Library/Application Support/NapatDev/`. Full vault serialized to JSON,
  sealed with AES-GCM, written atomically on every change (debounced 400 ms).
- **Scope kept** — login items (title / username / password / website / notes),
  favorites + quick tiles, light + dark themes, biometric unlock.

## Convenience features

- **Clipboard auto-clear (30 s).** Copy a password and the pasteboard wipes
  itself 30 seconds later — unless you've copied something else in between.
- **Touch ID unlock.** *Sidebar → Security → Unlock with Touch ID.* Derived
  key stored in Keychain behind `biometryCurrentSet` access control.
- **Launch at login.** *Sidebar → System → Launch at login* — wraps
  `SMAppService.mainApp`.
- **Menu bar item.** Always-on `MenuBarExtra` icon in the menu bar. Click for
  quick search + one-tap password copy from favorites; also Lock and Quit.
- **Global hotkey.** ⌃⌥⌘P brings the main window forward from anywhere. Uses
  Carbon's `RegisterEventHotKey` — no Accessibility permission required.

## AI assistant (optional)

The **Assistant** toolbar button is a chat UI backed by Claude Haiku 4.5. It
can search your vault, read items, generate passwords, and propose edits.
**Every change Claude proposes is shown as a diff card with Apply / Cancel —
nothing is written without your tap.**

### Enable it

1. Grab an API key at <https://console.anthropic.com/settings/keys>.
2. `cp NapatDev/Supporting/Secrets.plist.example NapatDev/Supporting/Secrets.plist`
3. Open `Secrets.plist` in Xcode (or any text editor) and paste your key into
   `anthropic_api_key`.
4. Rebuild. `Secrets.plist` is gitignored — the key is bundled into the app
   binary but never committed.

If you skip this step the Assistant shows a "No API key configured" notice;
the rest of the app works normally.

### What the assistant can see

Claude can read titles, usernames, websites, notes, **and passwords** — that
was the deliberate tradeoff during planning. Anything Claude reads is sent to
the Anthropic API over TLS. If you change your mind, the one-line way to
neuter it is to mask the `password:` line in `AssistantToolDispatcher.getItem`
in `NapatDev/Assistant/AssistantTools.swift`.

## Security notes

- The vault file is fully encrypted at rest. Without the master password it's
  a useless ciphertext blob.
- The derived key lives in memory only while unlocked; backgrounding the
  window wipes it and requires re-entry.
- **There is no password recovery.** If you forget the master password, you
  lose the vault. Use Settings → "Reset master password…" to start over —
  this erases the vault file.
- The macOS build currently runs *without* the App Sandbox so biometric
  Keychain access works under ad-hoc signing. Fine for a personal local build;
  re-enable the sandbox and sign with a Developer team if you ever ship.

## Tests

No automated tests yet. Manual verification steps:

1. Launch → set a master password → land on an empty vault.
2. Add an item, mark it favorite, reveal/copy the password.
3. Background the app → vault locks → re-enter master password.
4. Toggle Touch ID in the sidebar → lock → unlock by fingerprint.
5. Click the menu bar icon → quick-copy a favorite.
6. Press ⌃⌥⌘P from another app → main window comes forward.
