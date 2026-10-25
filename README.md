<p align="center">
  <img src="resources/icon.png" alt="Globemaster" width="200">
</p>

<p align="center">
  <b>A menu bar app that switches input sources with a single Command key press</b>: no extra shortcuts to learn.
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
</p>

Globemaster is a native macOS menu bar app. It turns the two Command keys into input source
switches, in the way Eisu and Kana keys work on a Japanese keyboard, while every ⌘ shortcut keeps
working as usual.

## How it works

- **Left ⌘** pressed and released alone → **Eisu (alphanumeric)**
- **Right ⌘** pressed and released alone → **Kana**

A Command key only switches the input source when it is pressed and released on its own. Shortcuts
such as ⌘+C continue to work as normal.

Once launched, a ⌘ icon appears in the menu bar and key remapping is enabled automatically. Select
"Quit" from the menu to exit the app and disable key remapping.

## Requirements

- macOS 26.2 or later
- Accessibility permission

## Installation

1. Place `Globemaster.app` in `/Applications`
2. Launch the app
3. Allow Globemaster in **System Settings > Privacy & Security > Accessibility**

## Building

1. Open `Globemaster.xcodeproj` in Xcode
2. Build and run with `⌘R`

To build a DMG, run `scripts/build-dmg.sh`; it writes `build/Globemaster.dmg`.

## App icon

The icon is a layered [Icon Composer](https://developer.apple.com/icon-composer/) file with Default
and Dark appearances: a machined metal bezel around a glass lens, with a ⌘ in the lens and one red
indicator lamp. The ⌘ stands for the keys the app remaps, and the lens for input sources.

`Globemaster/Resources/Globemaster.icon` is generated from the layer sources in `design/icon/src/`:

```sh
python3 scripts/generate-icon-layers.py   # layer SVGs
python3 scripts/build-icon-bundle.py      # Globemaster.icon
scripts/render-icon.sh <output-dir>       # preview PNGs with Icon Composer's ictool
```

## Repository layout

| Path | Contents |
| --- | --- |
| `Globemaster/` | The app target |
| `Globemaster/Resources/Globemaster.icon` | The app icon (Icon Composer) |
| `design/icon/src/` | Layer SVGs the icon is built from |
| `scripts/` | DMG packaging and icon generation |
| `resources/` | Images used by this README |

## License

[MIT](LICENSE)
