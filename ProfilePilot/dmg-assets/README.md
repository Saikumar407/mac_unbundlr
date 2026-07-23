# DMG assets

The DMG built by `scripts/create-dmg.sh` uses three optional assets from this
folder. All are generated from vector sources so you can restyle them cheaply.

## Files

| File                 | Purpose                                    | Required by DMG |
|----------------------|--------------------------------------------|-----------------|
| `dmg-background.svg` | Vector source of the Finder-window backdrop | source only     |
| `dmg-background.png` | Rasterised backdrop, 1240×800 (@2×)         | ✅               |
| `VolumeIcon.icns`    | Icon shown when the DMG is mounted          | optional        |
| `AppIcon.icns`       | Copied into the built `.app` at sign time   | ✅ for release   |

## Rasterise the background

On macOS with `librsvg`:

```bash
brew install librsvg
rsvg-convert -w 1240 -h 800 dmg-background.svg -o dmg-background.png
```

Or in Sketch / Figma / Illustrator: export the SVG at 2× (1240×800) as PNG-24.

## Volume icon

Any 512×512 or 1024×1024 PNG can be converted:

```bash
mkdir VolumeIcon.iconset
sips -z 16 16     source.png --out VolumeIcon.iconset/icon_16x16.png
sips -z 32 32     source.png --out VolumeIcon.iconset/icon_16x16@2x.png
sips -z 32 32     source.png --out VolumeIcon.iconset/icon_32x32.png
sips -z 64 64     source.png --out VolumeIcon.iconset/icon_32x32@2x.png
sips -z 128 128   source.png --out VolumeIcon.iconset/icon_128x128.png
sips -z 256 256   source.png --out VolumeIcon.iconset/icon_128x128@2x.png
sips -z 256 256   source.png --out VolumeIcon.iconset/icon_256x256.png
sips -z 512 512   source.png --out VolumeIcon.iconset/icon_256x256@2x.png
sips -z 512 512   source.png --out VolumeIcon.iconset/icon_512x512.png
cp                source.png     VolumeIcon.iconset/icon_512x512@2x.png
iconutil -c icns  VolumeIcon.iconset
rm -rf            VolumeIcon.iconset
```

`iconutil` and `sips` are built-in on macOS — no extra tooling required.

## AppIcon

The primary app icon lives at
`Sources/ProfilePilot/Resources/Assets.xcassets/AppIcon.appiconset/`. Drop the ten
required PNGs (16, 32, 128, 256, 512 at 1× and 2×) into that folder and Xcode
will produce a valid `.icns` at build time.

## Finder window layout

`scripts/create-dmg.sh` uses the `create-dmg` tool to lay out the Finder window
programmatically:

- Window size: 620×400
- App icon at (160, 200)
- Applications alias at (460, 200)
- Icon size: 128 px
- Text size: 13 pt

Edit those numbers in `scripts/create-dmg.sh` if you want a different layout.
