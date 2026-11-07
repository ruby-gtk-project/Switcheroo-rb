# Component identification — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` (unchanged) |
| Port | `ruby` @ `fb196babe2113d47395c5efc48bf491b447190cc` |
| Scope | whole app (26 shipped `lib/` units) |

## Re-checked this round

The only commit since the last identification pass (`fb196ba`) adds
`io.gitlab.adhami3310.Converter.json` at the repo root and edits
`PORTING.md`. Neither is a `lib/*.rb` widget file, and the manifest is JSON
packaging metadata, not a GTK component — it introduces no new widget, no
new CSS class, no new signal and no new action. `ls lib/*.rb | wc -l` is
still 26, `test/drive_main_window.rb`'s own closing check ("the 26
components driven are the 26 the port ships") still passes (re-run this
round, see `test-parity.md`). The unit list below is unchanged from the
last round and is carried forward rather than re-derived from scratch,
because nothing that would change it happened.

## What changed since the last census

The prior census (`d15487b`, upstream `ae72daf` unchanged) enumerated 26
units against `data/resources/blueprints/window.blp`, the two widget-level
blueprints (`image-thumbnail.blp`, `image-rest.blp`) and the Rust source
behind each. Upstream has not moved. On the port side, two commits landed
since the last identification pass (`d1ca7f4`, `c409c40`) and neither adds,
removes or splits a `lib/*.rb` unit — confirmed directly:

```
$ ls lib/*.rb | wc -l
26          # excludes lib/main.rb and the lib/switcheroo/ gem-launcher tree
```

matching `COMPONENTS` in `test/drive_main_window.rb` (26 entries) and the
drive run's own closing check, re-run this round (see `test-parity.md`):
`the 26 components driven are the 26 the port ships`.

## Unit list (confirmed unchanged, 26)

application, main/config/translations (behaviour units, no widget),
app_window, drag_overlay, welcome_page, loading_page, invalid_image_page,
converting_page, convert_page, all_images_page, image_thumbnail, image_rest,
primary_menu, shortcuts_dialog, error_dialog, stop_converting_dialog,
about_dialog, style, magick, file_type, file_chooser, input_file, temp_dir,
color, settings, plus `lib/translations.rb` — matching the file-mapping
table in `PORTING.md`'s "Done" section (that table is an accurate file map;
see `accountability-ensurance.md` for why the surrounding prose is not
reliable as a status claim).

No upstream widget, dialog, page or menu was found this round with no
`lib/` file at all. The open question at this level is never "is it
ported" — every upstream unit names a port file — it is "does what is in
that file match", which `component-parity.md` answers.

## Standing blind spot, re-confirmed

`lib/` has a subdirectory the self-check does not see:
`lib/switcheroo/application.rb`, `lib/switcheroo/rb.rb` and
`lib/switcheroo/rb/version.rb` (the `kettle-jem` gem-release scaffolding).
`Dir.children` in `test/drive_main_window.rb` is non-recursive, so these
three files are invisible to the "every component the port ships was
opened" check. They are gem-release plumbing, not UI, so this is not a
missing-component finding — but it is a real gap in *how* that check would
notice a genuine UI component someone added under a subdirectory by
mistake. Carried forward, unchanged since the last round.

## Builder-fragment attribute drift — re-checked, now closed

The last round flagged `lib/convert_page.rb`'s quality-row `GtkAdjustment`
fragment for carrying two properties (`value`, `page-increment`) that
upstream's `window.blp:151-154` `Adjustment percentage` block does not set.
Re-read this round:

```
$ sed -n '/def quality_markup/,/XML$/p' lib/convert_page.rb
  <object class="GtkAdjustment" id="percentage">
    <property name="lower">#{QUALITY_MINIMUM}</property>
    <property name="upper">#{QUALITY_MAXIMUM}</property>
    <property name="step-increment">1</property>
  </object>
```

`value` and `page-increment` are gone; the fragment now declares exactly
upstream's three properties. Closed since `d1ca7f4`. Carried into
`component-parity.md` as a closed row, not a new finding — this document
only re-confirms the builder XML matches the blueprint attribute-for-
attribute.
