# Switcheroo-rb — Port Status

## Upstream

Switcheroo (io.gitlab.adhami3310.Converter) — batch image converter. Upstream
is Rust/gtk-rs + libadwaita. This port implements it in Ruby (GTK4 +
Libadwaita via ruby-gnome). Spec for upstream behavior is the `origin/main`
ref of this same repository; `origin/main` is read-only reference material
and is never checked out or merged into `ruby`.

## Done

Components implemented and observed working (`lib` path — upstream source
file):

- see `.reports/` component inventory and parity reports for the per-file
  mapping of all 26 components covered by the drive run below; this file
  does not re-enumerate them individually to avoid drifting out of sync with
  those reports, which are the source of truth checked each round.

## Runtime

Drive command:

```
nix develop --command xvfb-run -a ruby test/drive_main_window.rb
```

Result: drive_ok=true, 328 passed / 0 failed, 26 components covered.

Spec suite: 75 passed / 0 failed.

## Not started

No upstream user-facing component is missing a `lib/*.rb` counterpart (see
Blockers). Packaging (Flatpak manifest) is the only major undelivered piece
and is tracked there, not here, since it is not a widget/component port.

## Open gaps

The last audit in `.reports/` reported 4 gap(s), clean=false. Gaps are
behavioural/packaging in nature (see Blockers), not missing components.

## Blockers

- Component presence: None. Every user-facing component upstream declares
  has a `lib/*.rb` counterpart; this was confirmed again this round. The
  stale "tree content not carried" note from a prior inventory (COPYING,
  doap, PRESS.md, screenshots, update_translation.sh) was corrected — all of
  these are now present in the tree.
- `image_thumbnail.rb`'s `size_allocate()` vfunc cannot be reproduced: Ruby
  GTK widget vfuncs are not dispatched in this binding.
- The transparency-colour accessible label is announced via a toast rather
  than set via `update_property`, because the binding raises
  `NotImplementedError` for that accessibility call.
- There is no GResource bundle; assets are read from `data/` directly. This
  is a correspondence, not a gap.
- The Flatpak manifest is not started: there is no Ruby SDK extension and no
  flatpak-builder/GNOME runtime available in this environment.
- Driving coverage gap: the all-images page, drop-target reveal, clipboard
  paste, and the full ZIP/PDF conversion pipeline are not yet exercised by
  `test/drive_main_window.rb` or `spec/`.
