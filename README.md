<p align="center">
  <img src="Resources/icon-preview.png" width="128" height="128" alt="WinDot app icon — a white ⌘. glyph on a pink-to-orange rounded square">
</p>

<h1 align="center">WinDot</h1>

<p align="center"><strong>A GIF and emoji picker for macOS, one keystroke away — anywhere you can type.</strong></p>

<p align="center">
  <a href="https://github.com/jackharvest/WinDot/releases/latest"><img src="https://img.shields.io/github/v/release/jackharvest/WinDot?label=download&color=fb7a5a" alt="Latest release"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue" alt="macOS 13 or later">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License"></a>
</p>

WinDot is a free, open-source macOS menu bar app that recreates Windows' **Win+.** GIF picker. Press **⌘.** anywhere — Slack, Messages, Teams, Discord, a browser, Reddit, whatever you're typing into — and a small panel pops up right at the corner of your window, ready to search GIFs, pick an emoji, and paste it in for you.

## The problem

macOS ships a native emoji picker (**⌃⌘Space**), but nothing for GIFs. Windows has had one built in for years (**Win+.**). Teams, Signal, and most browsers/Reddit have no built-in GIF picker on Mac at all, so you're stuck alt-tabbing to a browser tab, searching, downloading, and dragging a file in. WinDot brings the Windows-style workflow to macOS: one hotkey, search, click, done.

## Features

- **⌘.** global hotkey, matching Windows' Win+. muscle memory
- **Quick tab**: frequently-used emoji and recent GIFs in one combo view, keyboard-navigable (arrow keys + Enter)
- **GIF tab**: live GIPHY search with infinite scroll and animated previews
- **Emoji tab**: ~250 curated emoji across categories, with usage-ranked "Frequently Used"
- Docks itself to the bottom-right corner of whichever window you hailed it from
- Clipboard-safe: your existing clipboard is untouched — WinDot snapshots it, pastes, then restores it
- Mouse-wheel and trackpad support for scrolling the GIF row, not just trackpad swipes
- Refocuses the app you came from automatically on close
- Light/Dark/System appearance override, configurable default tab, launch at login

## Requirements

- macOS 13 (Ventura) or later
- A free [GIPHY API key](https://developers.giphy.com/dashboard/) for GIF search (WinDot walks you through adding one on first use — emoji search works with no key at all)

## Installing

### Option 1: Download the DMG (easiest)

1. Grab the latest `WinDot-x.y.z.dmg` from [Releases](https://github.com/jackharvest/WinDot/releases/latest).
2. Open it and drag **WinDot** onto the **Applications** shortcut.
3. Open WinDot from your Applications folder.

WinDot isn't notarized by Apple (no paid developer account behind this), so on first open, macOS Gatekeeper will refuse to launch it as "from an unidentified developer." Right-click (or Control-click) **WinDot.app** in Applications and choose **Open**, then confirm — you only need to do this once.

On first launch, macOS will prompt for **Accessibility** access (needed so WinDot can find the window you're typing into and dock itself to the right corner) — grant it in **System Settings > Privacy & Security > Accessibility**. If you skip it, WinDot still works, it just falls back to opening near your mouse cursor instead of the window corner.

### Option 2: Build from source

No Xcode required — just the Swift toolchain that ships with Command Line Tools:

```sh
git clone https://github.com/jackharvest/WinDot.git
cd WinDot
./build.sh
cp -R WinDot.app /Applications/
open /Applications/WinDot.app
```

## Usage

Press **⌘.** anywhere to open the picker:

- **Quick tab** (default) — type to search, or browse your frequently-used emoji and recent GIFs. Arrow keys move the selection, Enter pastes it, Esc closes the panel.
- **GIF tab** — full GIPHY search with infinite scroll.
- **Emoji tab** — full categorized emoji browser.
- Click any result (or hit Enter on a selection) to paste it into whatever you were typing in and close the panel.

The **⌘.** icon in the menu bar opens the same menu bar app's settings:

- **Default Tab** — which tab opens when you press ⌘.
- **Appearance** — System / Light / Dark
- **Launch at Login**
- **Open Config File** — where your GIPHY API key lives
- **Open Accessibility Settings** / **Reset Accessibility Permission** — if window-corner docking ever stops working after an update (see [Troubleshooting](#troubleshooting))
- **Uninstall WinDot…** — one-click, fully reversible removal
- **Quit WinDot**

## Uninstalling

Use the **Uninstall WinDot…** menu item above — it unregisters the login item, deletes the saved config, and moves WinDot.app to the Trash (recoverable until you empty it). If WinDot won't launch for some reason, you can undo everything by hand instead:

1. Open **System Settings > General > Login Items**, remove WinDot if it's listed.
2. Open **System Settings > Privacy & Security > Accessibility**, remove WinDot if it's listed.
3. Delete `/Applications/WinDot.app`.
4. Optionally delete its saved settings: `rm -rf ~/.config/gifpicker`

## Troubleshooting

**The panel opens near my mouse instead of docking to my window's corner.** WinDot needs Accessibility permission to read the frontmost window's frame. Because WinDot is ad-hoc signed (no paid Apple Developer account), reinstalling a new version can silently invalidate a previously-granted permission — it'll still show as checked in System Settings, but the underlying grant is stale. Use **Reset Accessibility Permission** in the menu bar menu to clear and re-prompt for it.

**GIF search shows nothing / an error.** You need a free [GIPHY API key](https://developers.giphy.com/dashboard/) — WinDot's GIF tab shows a one-time setup card to paste it in. Emoji search and the Quick tab's emoji row work with no key at all.

## How it works

WinDot registers **⌘.** as a global hotkey via Carbon's `RegisterEventHotKey`, reads the frontmost app's focused-window frame via the Accessibility API to position a borderless `NSPanel`, and on pick, snapshots your clipboard, writes the GIF/emoji to it, synthesizes ⌘V into the app you were in, then restores your original clipboard shortly after. GIF search goes through the [GIPHY API](https://developers.giphy.com/); everything else (emoji data, usage ranking, recent GIFs, your API key) is stored locally — WinDot has no telemetry and no other network calls.

## License

MIT, see [LICENSE](LICENSE).
