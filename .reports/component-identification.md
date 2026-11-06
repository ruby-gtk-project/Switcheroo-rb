# Component identification — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` |
| Port | `ruby` @ `5ec22388b7dd5ea9ec0c27dbebeac2a8bd86ab46` |
| Scope | whole app (26 shipped `lib/` units, re-audit of the previous census) |

This round does not re-derive the inventory from scratch — the prior census
(`.reports/component-inventory.md`, upstream `ae72daf` unchanged, port
`d15487b`) already enumerated all 26 units file-by-file against
`data/resources/blueprints/window.blp` and the three widget-level blueprints
(`image-thumbnail.blp`, `image-rest.blp`) plus the Rust source behind each.
Upstream has not moved (`ae72daf` both times), so that inventory is still the
correct map of what exists. What changed on the port side since that census
(`d15487b` → `5ec2238`) is a `.po`/`Rakefile`/`update_translation.sh`
re-translation pass and one new spec file — no new or removed widget, no new
`lib/*.rb` unit. Re-confirmed directly:

```
$ ls lib/*.rb | wc -l
26          # excludes lib/main.rb and the lib/switcheroo/ gem-launcher tree
```

matching `COMPONENTS` in `test/drive_main_window.rb` (26 entries) and the
drive run's own closing check, both reconfirmed this round (see
`test-parity.md`).

## What this round checked instead

Rather than re-walk every widget's CSS/signal/action rows (unchanged, per
above), this round re-opened every row `component-parity.md`'s last pass
(`9f4999c`) marked as a gap and verified, file and line, whether the
underlying code had moved since. That is `component-parity.md`'s job and its
findings are there. Two identification-level notes fell out of doing that:

- **`lib/` has a subdirectory the self-check does not see.**
  `lib/switcheroo/application.rb`, `lib/switcheroo/rb.rb` and
  `lib/switcheroo/rb/version.rb` exist (the `kettle-jem` gem-release
  scaffolding added in `30c28b6`/`1184868`). `Dir.children` in
  `test/drive_main_window.rb:1562` is non-recursive, so these three files are
  invisible to the "every component the port ships was opened" check — they
  are not UI components and do not belong in `COMPONENTS` anyway, so this is
  not a missing-component finding, but it is a real blind spot in *how* that
  check would notice a real component added under a subdirectory. Recorded
  here rather than silently relied on; `test-parity.md` carries the
  consequence.
- **The quality-row builder fragment (`lib/convert_page.rb:587-605`) declares
  a `GtkAdjustment` with two properties upstream's `Adjustment percentage`
  block does not have** — `value` and `page-increment`. Upstream
  (`window.blp:151-154`) sets only `lower`, `upper`, `step-increment`. This is
  a component-identification finding (an attribute the scan-by-reading finds,
  not one `component-scan.sh` would flag, since both sides are inside opaque
  builder-XML/blueprint text) and is carried into `component-parity.md` as a
  style/behaviour row.

## Unit list (confirmed unchanged, 26)

application, main/config/translations (behaviour units, no widget),
app_window, drag_overlay, welcome_page, loading_page, invalid_image_page,
converting_page, convert_page, all_images_page, image_thumbnail, image_rest,
primary_menu, shortcuts_dialog, error_dialog, stop_converting_dialog,
about_dialog, style, magick, file_type, file_chooser, input_file, temp_dir,
color, settings — 25 `lib/*.rb` component/behaviour files plus
`lib/translations.rb`, matching the file-mapping table in `PORTING.md`'s
"Done" section, which is accurate as a file map (see `accountability-
ensurance.md` for why its "Done" label is not itself evidence of parity).

No upstream widget, dialog or menu was found this round with no `lib/` file
at all. The open question is never "is it ported" at the identification
level — every upstream unit has a named port file — it is "does what's in that
file match", which is `component-parity.md`.
