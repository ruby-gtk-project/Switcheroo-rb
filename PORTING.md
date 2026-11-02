# Port status — Switcheroo-rb

| | |
|---|---|
| Upstream spec | `origin/main` @ `ae72daf` |
| Port branch | `ruby` |
| Last audit | `.reports/` @ `8b7d245`, against port commit `341104d` |
| Audit verdict | **not clean** — 23 gap(s) |

This file is the resume point. The debt ledger that used to live here (the
first-person accountability admissions) is in `.reports/accountability-ensurance.md`;
the per-widget comparison is in `.reports/component-parity.md` and
`COMPONENT_PARITY.md`; binding limits actually driven and verified are in
`FINDINGS.md`.

## Upstream

Switcheroo is a batch image converter. It loads images that are dropped,
pasted or opened, and shells out to ImageMagick to convert, resize,
re-quality, strip metadata and re-background them, writing the results as
individual files, a ZIP, a directory or a single multi-page PDF.

It is implemented in Rust (gtk-rs + libadwaita) with blueprint `.blp` UI
files. The spec lives on the `origin/main` ref of this repo; read it with
`git show origin/main:<path>`. The upstream ref is never checked out and never
merged — the port is written from scratch against it.

## Done

Implemented and believed complete. 17 widget units (11 of 17 audited as full
parity) plus 7 non-widget behaviour units (6 of 7 parity).

| `lib` path | Upstream source |
|---|---|
| `lib/application.rb`, `lib/main.rb`, `lib/config.rb` | `src/application.rs`, `src/main.rs`, `src/config.rs.in` |
| `lib/app_window.rb` | `src/window.rs` + `data/resources/blueprints/window.blp:4-47` |
| `lib/drag_overlay.rb` | `src/drag_overlay.rs` |
| `lib/welcome_page.rb` | `window.blp:53-84` |
| `lib/loading_page.rb` | `window.blp:86-97` |
| `lib/invalid_image_page.rb` | `window.blp:331-341` |
| `lib/converting_page.rb` | `window.blp:343-374` |
| `lib/convert_page.rb` | `window.blp:99-329` + `src/window.rs` (WindowUI) |
| `lib/all_images_page.rb` | `window.blp:380-441` |
| `lib/image_thumbnail.rb` | `src/widgets/image_thumbnail.rs` + `image-thumbnail.blp` |
| `lib/image_rest.rb` | `src/widgets/image_rest.rs` + `image-rest.blp` |
| `lib/primary_menu.rb` | `window.blp:484-513` |
| `lib/shortcuts_dialog.rb` | `window.blp:448-482` |
| `lib/error_dialog.rb` | `src/window.rs:1463-1505` |
| `lib/stop_converting_dialog.rb` | `src/window.rs:572-608` + `:1543-1583` (2 call sites → 1 class) |
| `lib/about_dialog.rb` | `src/widgets/about_window.rs` |
| `lib/style.rb` | `data/resources/style.css` (CSS → Ruby heredoc) |
| `lib/magick.rb` | `src/magick.rs` |
| `lib/file_type.rb` | `src/filetypes.rs` |
| `lib/file_chooser.rb` | `src/file_chooser.rs` |
| `lib/input_file.rb` | `src/input_file.rs` |
| `lib/temp_dir.rb` | `src/temp.rs` |
| `lib/color.rb` | `src/color.rs` |
| `lib/settings.rb` | `gio::Settings` + `data/…Converter.gschema.xml.in` |
| `lib/translations.rb` | `src/main.rs` domain bind (gettext gem) |

Also carried: `po/` — 20 catalogues plus `switcheroo.pot`, byte-identical to
upstream; all 91 upstream msgids marked in `lib/`, key sets identical.
`data/…gschema.xml.in`, `data/…metainfo.xml.in.in`, `data/…desktop.in.in` and
`data/…service.in` are upstream's files byte for byte. The `app:` namespace in
the `Rakefile` replaces `meson.build` for install (locale `.mo` tree, desktop
file via `msgfmt --desktop`, metainfo via `msgfmt --xml`, D-Bus service file,
icons, compiled schema).

## Not started

No upstream *source* component is without a Ruby counterpart. What is not
carried is upstream tree content:

| Upstream path | Note |
|---|---|
| `data/resources/icons/.../io.gitlab.adhami3310.Impression.svg` | About dialog's sibling-app row resolves to no icon |
| `data/resources/icons/.../io.gitlab.adhami3310.Footage.svg` | same |
| `COPYING` | GPL-3.0 text absent while `switcheroo-rb.gemspec:18` declares `GPL-3.0-or-later` |
| `data/resources/screenshots/0.png`, `1.png` | the shipped metainfo cites both by URL |
| `io.gitlab.adhami3310.Converter.json` | Flatpak manifest; the port cannot be built as a Flatpak |
| `Switcheroo.doap` | project metadata |
| `PRESS.md` | — |
| `update_translation.sh`, `build-aux/dist-vendor.sh` | no translation-refresh counterpart; `po/switcheroo.pot` is still upstream's, never regenerated from `lib/` |
| `meson.build`, `meson_options.txt`, `*/meson.build` | correspondence — replaced by `Rakefile` + `flake.nix` |

## Open gaps

The last audit reported **23** gaps and clean=false. They come from three
reports and the lists overlap (the accessibility and tree-content rows appear
in two of them).

`.reports/component-parity.md` — 13:

1. Colour button has no accessible `Label` property; the port announces instead (`update_property` raises `NotImplementedError`, `FINDINGS.md` §1).
2. Resize-unit dropdown carries a tooltip upstream does not have, and a code comment claims the blueprint has one.
3. The two `Adw.Bin` wrappers around the convert page (`window.blp:102-103`) are not built.
4. Thumbnail width is a minimum (`set_size_request(150, -1)`), not min = nat = 150; `size_allocate()` not reproduced.
5. Every `Gtk::FlowBoxChild` thumbnail is unlabelled to a screen reader (upstream `src/window.rs:1901`, `:1957`).
6. About dialog's two "Other Apps" rows have no icon.
7. A maximized window forgets its size — `lib/settings.rb:93-98` skips the two size keys; upstream writes all three unconditionally.
8. A pasted image is written under `TempDir.parent`, not the CWD, so the save dialog opens elsewhere.
9. A missing `zip`/`magick` yields one generic message instead of `"magick: <errno>"` / `"zip: <errno>"`.
10. `fdlimit::raise_fd_limit()` on open is not reproduced — a large pick can fail where upstream succeeds.
11. `FileType#output?` rejects `jpeg`; upstream's `is_output()` accepts it (dead on both sides today).
12. `COPYING` and the two screenshots not carried (see **Not started**).
13. Flatpak manifest, `.doap`, `PRESS.md`, `update_translation.sh` not carried.

`.reports/accountability-ensurance.md` — 9 gaps found by reading, plus 4
sentences a reader could quote as approval and 5 statements in the port that
are not true. The 9 are items 5, 7, 8, 9, 10, 6, 12, 13 and 3 above, recorded
there because the port's own files did not record them.

`.reports/test-parity.md` — 1: the suite cannot be run the way its own header
documents. Upstream has 0 tests, so test parity is 0/0 and met trivially; the
port's 70 spec examples and 16 driver checks are all extra and pin only what
the port's author chose to look at.

Still owed and not a parity gap: the upstream `output-format` enum bug (the
schema's nicks are unreachable because the code writes an index) is drafted at
the foot of `FINDINGS.md` and has not been filed upstream.

Not driven, therefore unconfirmed: drop-target reveal, clipboard paste, the
full conversion pipeline, the error dialog, the stop dialog, the all-images
page, the `+N` tile, and any accessibility assertion.

## Blockers

Verified binding limits (see `FINDINGS.md`):

- **`Gtk::Accessible#update_property` cannot be called** — raises
  `NotImplementedError`. This blocks true parity on the colour button's and
  every thumbnail's accessible label. `gtk_accessible_announce` is a
  correspondence, not parity. (`FINDINGS.md` §1)
- **`Gtk::AccessibleList.new_from_array` is not bound** — the blueprint
  `labelled-by` relations are built through `GtkBuilder` XML fragments in
  `lib/convert_page.rb` instead. (§2)
- **ruby-glib2 exposes no gettext entry points** — the `gettext` gem binds the
  domain. (§3)
- **Widget vfunc overrides: unverified.** Nobody has established whether
  ruby-gnome can override `measure`/`size_allocate` on a `Gtk::Widget`
  subclass. The experiment has not been run, so the thumbnail clamp stays an
  approximation. (§7)
- **CSS node name on a subclass: unverified.** `lib/drag_overlay.rb` covers
  both `dragoverlay` and `.dragoverlay`; the claim that the bindings force
  this was never tested. (§8)
- **Screenshots under broadway go stale** — harness limitation, not a port
  limitation. (§9)

Hard runtime dependencies, inherent to upstream:

- **ImageMagick.** Every conversion and every frame/dimension probe shells out
  to `magick` via Open3/spawn. The app does nothing without the binary on
  PATH. Not a library binding on either side.
- **`zip`.** ZIP output shells out to the `zip` binary, the same way upstream
  does.
- **No tokio / `SharedChild`.** Progress and cancellation are rebuilt on
  `GLib::Timeout` + Thread + `Process.kill` driven off the GTK main loop. The
  UI is unchanged; the plumbing is not upstream's.
- **XDG portals are not in the Ruby bindings.** `ashpd` supplies
  `is_sandboxed()` for temp-dir placement and the OpenFile/OpenDirectory
  requests behind the success toast's "Open" button; the button falls back to
  `Gio::AppInfo.launch_default_for_uri`.
- **D-Bus activation.** Upstream's `DBusActivatable` desktop entry and
  `data/…Converter.service.in` assume an installed, D-Bus-activatable binary.
  Both files are shipped and installed by `rake app:install`, but a gem run
  from a checkout registers nothing, so shell-side activation and the
  "New Window" desktop action do not work until the port is packaged.

Survey blockers that turned out **not** to be blockers, recorded so the next
run does not re-assume them:

- `Adwaita::Application` and `Adwaita::ApplicationWindow` work.
  `lib/application.rb` is an `Adwaita::Application`, matching upstream's
  subclass structure. (`FINDINGS.md` §6)
- GSettings works from a checkout. `lib/settings.rb` is a `Gio::Settings` over
  upstream's schema at upstream's path, using the installed schema when there
  is one and compiling the shipped one into `XDG_CACHE_HOME` when there is
  not. No JSON settings file.
- The metainfo is shipped, so the About dialog is not written out literally —
  `lib/about_dialog.rb` reads `data/…metainfo.xml.in.in` with REXML and sets
  what `adw_about_dialog_new_from_appdata` sets, release notes included.
- The accessibility blocks are reachable, via the `GtkBuilder` fragment route.
- `Gtk::IconTheme.for_display` does not exist and was raising on every
  startup; fixed, and `test/drive_main_window.rb` exists so the next live bug
  of that shape is caught. (`FINDINGS.md` §5)
