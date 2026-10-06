# Happening artwork

Original typographic branding with abstract map contours and an arrival route. These assets are not gameplay screenshots and contain no copied game art. Covered by the repository's MIT license.

- `cover.png`: 1600 × 900 listing cover; editable source `cover.svg`.
- `icon.png`: 512 × 512 monogram; editable source `icon.svg`.

The SVGs use Liberation Sans with a sans-serif fallback. PNG exports were rendered with `rsvg-convert`:

```sh
rsvg-convert --width 1600 --height 900 --output artwork/cover.png artwork/cover.svg
rsvg-convert --width 512 --height 512 --output artwork/icon.png artwork/icon.svg
```

Artwork stays outside the mod package's explicit file allowlist.
