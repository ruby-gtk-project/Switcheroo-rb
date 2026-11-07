# Component identification — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` (unchanged) |
| Port | `ruby` @ `c5f0dbd08393214d7614d776155388a4624aaad2` |
| Scope | whole app (26 shipped `lib/` units) |

## Re-checked this round

The only commit since the last identification pass (`fb196ba`) is `c5f0dbd`,
which edits two lines of root `COMPONENT_PARITY.md` (the Flatpak-manifest
status row and the duplicate GResource row — see `accountability-ensurance.md`).
It touches no `lib/*.rb` file, introduces no widget, dialog, menu, action or
CSS class. Re-confirmed directly:

```
$ git show c5f0dbd --stat
 COMPONENT_PARITY.md | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)
$ ls lib/*.rb | wc -l
26
```

matching `COMPONENTS` in `test/drive_main_window.rb` (26 entries, re-run this
round — see `test-parity.md`) and the drive's own closing check: "the 26
components driven are the 26 the port ships".

## Unit list (confirmed unchanged, 26)

application, main/config/translations (behaviour units, no widget),
app_window, drag_overlay, welcome_page, loading_page, invalid_image_page,
converting_page, convert_page, all_images_page, image_thumbnail, image_rest,
primary_menu, shortcuts_dialog, error_dialog, stop_converting_dialog,
about_dialog, style, magick, file_type, file_chooser, input_file, temp_dir,
color, settings, plus `lib/translations.rb` — matching the file-mapping table
in `PORTING.md`'s "Done" section.

No upstream widget, dialog, page, menu item, keyboard shortcut, preference,
action, empty state or error state was found this round with no `lib/`
counterpart. Every upstream unit names a port file; whether what is in that
file *behaves* the same is `component-parity.md`'s question, not this one.

## Standing blind spot, re-confirmed (unchanged since the last three rounds)

`lib/` has a subdirectory the self-check does not see: `lib/switcheroo/
application.rb`, `lib/switcheroo/rb.rb` and `lib/switcheroo/rb/version.rb`
(the `kettle-jem` gem-release scaffolding). `Dir.children` in
`test/drive_main_window.rb` is non-recursive, so these three files are
invisible to the "every component the port ships was opened" check. They are
gem-release plumbing, not UI, so this is not a missing-component finding —
but it remains a real gap in *how* that check would notice a genuine UI
component someone added under a subdirectory by mistake.

## New this round: the root census document (`COMPONENT_PARITY.md`) still disagrees with the real unit count

Root `COMPONENT_PARITY.md`'s own header table (line 7) reads:

```
| Units | 17 |
```

Against the actual, re-verified-this-round count of **26** `lib/*.rb` units
(matching this document, `test/drive_main_window.rb`'s `COMPONENTS` constant,
and `PORTING.md`'s file-mapping table). `c5f0dbd` edited two body rows of this
same file and left the header's unit count untouched. This is not a new
finding about the *port* — it is the same category `accountability-
ensurance.md` has flagged twice already (a status document, not the
application, going stale) recurring a third time, now at the header level
rather than a single row. See `accountability-ensurance.md` for the full
account, including the matching staleness in `TEST_PARITY.md`'s header.

## Builder-fragment attribute drift — still closed, re-confirmed

`lib/convert_page.rb`'s quality-row `GtkAdjustment` fragment still declares
exactly upstream's three properties (`lower`, `upper`, `step-increment`), no
`value`/`page-increment`. Unchanged since `d1ca7f4`; re-read this round, not
carried from memory.
