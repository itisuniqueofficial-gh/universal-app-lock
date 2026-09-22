# App icon — source of truth

`icon.png` in this directory is the **master launcher icon** and the single source of
truth for Universal App Lock's icon.

- Current master: `icon.png` (PNG, 1254×1254). A master of ≥512×512 is required; this
  file satisfies that. **Do not modify or delete the master** unless technically required.

## Planned generation pipeline (NOT run yet — later phase)

A future build-generation script/tool will derive all Android launcher resources from this
single master:

- `mipmap-mdpi` / `hdpi` / `xhdpi` / `xxhdpi` / `xxxhdpi` legacy icons
- adaptive icon (`mipmap-anydpi-v26` foreground/background)
- round icon

No icon variants are generated or hand-maintained in this phase, by design. The Flutter
scaffold currently ships the default generated `ic_launcher.png` densities under
`android/app/src/main/res/`; these will be replaced by the generated set from this master.
