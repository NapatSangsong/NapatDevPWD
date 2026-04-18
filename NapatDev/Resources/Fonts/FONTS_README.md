# Fonts

Drop these OFL-licensed TTFs here so the app can pick them up. Until then the
app falls back to system fonts.

Download from:

- **Instrument Sans** — https://fonts.google.com/specimen/Instrument+Sans
  - Keep: `InstrumentSans-Regular.ttf`, `InstrumentSans-Medium.ttf`,
    `InstrumentSans-SemiBold.ttf`, `InstrumentSans-Bold.ttf`
- **JetBrains Mono** — https://fonts.google.com/specimen/JetBrains+Mono
  - Keep: `JetBrainsMono-Regular.ttf`, `JetBrainsMono-Medium.ttf`

After adding the `.ttf` files here, add them under the target's **Info → Custom
Target Properties → Fonts provided by application** (`UIAppFonts` on iOS,
`ATSApplicationFontsPath` on macOS) — XcodeGen will regenerate this entry if you
list them in `project.yml` under each target's `info`.
