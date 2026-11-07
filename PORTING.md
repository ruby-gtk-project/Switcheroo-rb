# Port status — Switcheroo-rb

| | |
|---|---|
| Upstream spec | `origin/main` @ `ae72daf` |
| Port branch | `ruby` |
| Last audit | `.reports/` @ `c409c40`, against port commit `c409c40` |
| Audit verdict | **not clean** — 3 gap(s) |

This header was itself found stale by the `c409c40` audit: it had read
"`.reports/` @ `8b7d245`... not clean — 23 gap(s)" since before `d1ca7f4`
closed most of those 23, and five of the 13 gaps `.reports/
component-parity.md` once listed (the settings.rb maximized-window one,
`FileType#output?` rejecting jpeg, the fd-limit raise, the per-binary spawn
message, the two About-dialog icons) were already fixed four commits
*before* that 23-gap count was even written, by `98e9ae8` — so the number
was wrong from the day it was recorded, not only out of date since. See
`.reports/accountability-ensurance.md` for the full account. The 3 gaps
below are current, re-verified against the tree at `c409c40`.

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

Implemented. 26 units total; 23 of 26 audited as full component parity
(`.reports/component-parity.md`, re-verified `c409c40`); the 3 that are not
are listed under **Open gaps** below.

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
| `io.gitlab.adhami3310.Converter.json` | Written this round. Upstream's manifest pulls in a `rust-stable` SDK extension; there is no equivalent Ruby SDK extension, so the port's manifest builds Ruby 3.4.9 from source as its own module (real tarball, sha256 verified against the upstream download), installs the ruby-gnome gem stack (`pkg-config`, `native-package-installer`, `gobject-introspection`, `glib2`, `gio2`, `atk`, `cairo`, `cairo-gobject`, `pango`, `gdk_pixbuf2`, `graphene1`, `gdk4`, `gsk4`, `gtk4`, `adwaita`, `locale`, `text`, `gettext`, `rexml`) from `.gem` files fetched from rubygems.org with real sha256 checksums I downloaded and hashed myself, then builds and installs `switcheroo-rb` and lays down the desktop entry, AppStream metainfo, D-Bus service file, GSettings schema and icon the same way `rake app:install` does. **Unverified**: `flatpak-builder` and a Flatpak `org.gnome.Platform`/`org.gnome.Sdk` runtime are not available in this environment, so the manifest has never actually been run through `flatpak-builder --force-clean build-dir io.gitlab.adhami3310.Converter.json` — the gem native extensions, the GObject-introspection typelib lookups inside the sandbox, and the final desktop/metainfo substitution are all unexercised. Treat it as a from-the-spec draft, not a proven build. |
| `meson.build`, `meson_options.txt`, `*/meson.build` | correspondence — replaced by `Rakefile` + `flake.nix` |

Closed since this table was last accurate (re-verified `c409c40`): the two
About-dialog app icons (`data/icons/hicolor/scalable/apps/io.gitlab.adhami3310.
{Impression,Footage}.svg`), `COPYING`, both screenshots
(`data/screenshots/{0,1}.png`), `Switcheroo.doap`, `PRESS.md`, and
`update_translation.sh` (backed by real `rake app:pot`/`app:update_po`
tasks; `po/switcheroo.pot` is regenerated from `lib/`/`data/`, not
upstream's `src/*.rs`/`*.blp` any more — see `.reports/translation-
parity.md`) are all present and carried.

## Open gaps

Current count, re-verified `c409c40`: **3**, all in
`.reports/component-parity.md` and `COMPONENT_PARITY.md` (the two agree):

1. The colour button's accessible identity is an announcement, not a live
   `Label` property update on colour change — `update_property` raises
   `NotImplementedError` (`FINDINGS.md` §1).
2. `size_allocate()` is not reproduced on `ImageThumbnail` — no ruby-gnome
   route to dispatch a `Gtk::Widget` vfunc override has been found
   (`FINDINGS.md` §7). The `measure()` half of this finding is now pinned
   by `spec/image_thumbnail_spec.rb`; this half has none.
3. `io.gitlab.adhami3310.Converter.json` now exists but is unverified — no
   `flatpak-builder` or Flatpak runtime is available in this environment, so
   the manifest has never been run; see **Not started** for exactly what it
   does and does not prove.

Everything else this file previously listed as an open gap (13 rows under
`.reports/component-parity.md`, folded into 9 by the accountability report,
plus the `rake spec` false green under `.reports/test-parity.md`) is
closed, re-verified this round by reading the current file rather than
trusting a prior ledger — see `.reports/component-parity.md`,
`.reports/test-parity.md` and `.reports/accountability-ensurance.md` for
what closed each one and when.

Still owed and not a parity gap: the upstream `output-format` enum bug (the
schema's nicks are unreachable because the code writes an index) is drafted at
the foot of `FINDINGS.md` and has not been filed upstream.

The runtime gate, re-run `c409c40`: `test/drive_main_window.rb` → 328/328
checks, 26/26 components, DRIVE OK. `rake spec` → 75 examples, 0 failures,
and (unlike the state this section used to describe) `rake spec` itself
now genuinely runs the suite.

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
- **Neither `measure()` nor `size_allocate()` can be overridden as a real
  `Gtk::Widget` vfunc.** FINDINGS.md §7's probe shows GTK dispatching none of
  the three override spellings for `measure` either, so `ImageThumbnail`
  does not carry upstream's vfunc at all — it approximates the one outcome
  that vfunc exists to produce (`min = nat = 150` on the horizontal
  orientation) with a plain `set_size_request(150, -1)` call, which is not a
  vfunc override and does not touch `size_allocate` in any way.
  `spec/image_thumbnail_spec.rb` pins that approximation's *output*, not a
  working override. (§7)
- **CSS node name on a subclass: resolved, works.** `Gtk::Widget#set_css_name`
  is callable inside `type_register`; `lib/drag_overlay.rb` uses it and
  `lib/style.rb` matches the real `dragoverlay` node, not a class. A
  previous version of this file claimed the opposite; that claim was false
  and is corrected. (§8)
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
