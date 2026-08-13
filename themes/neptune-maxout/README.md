# Neptune Maxout KlipperScreen theme

This theme uses the HDR Performance Neptune Maxout charcoal, black, and red visual identity. It includes dedicated 1024 x 600 landscape and 600 x 1024 portrait artwork, so the complete **Neptune MAXOUT** logo stays visible in every Pad 7 orientation.

The HDR rotation control automatically switches between `background-landscape.png` and `background-portrait.png` before KlipperScreen restarts. The active copy remains `background.png`, which keeps the theme compatible with standard KlipperScreen theme loading.

The installer copies the complete `material-dark` icon set from the installed KlipperScreen version before adding the Neptune Maxout badge. The stylesheet then gives those icons a subtle red glow and places them in rounded, raised red/black controls with clear focused, pressed, disabled, warning, and success states. This keeps every standard KlipperScreen panel and future icon compatible with the version installed on the Pad.

The theme also includes an original short retro toy-laser chirp. Its installer connects the sound to KlipperScreen's central button factory, enables the CM4 Pad 7 HDMI speaker path when required, and retains the normal CB1 speaker output. See `docs/17-pad7-sound.md` for testing and recovery.

Install from the repository root:

```text
./tools/install-neptune-maxout-theme.sh
```

Revert at any time from **Settings > Appearance > Colorized** or **Material Dark**, or run:

```text
./tools/install-neptune-maxout-theme.sh --restore-material-dark
```
