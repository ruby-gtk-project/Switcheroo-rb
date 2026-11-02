# Component parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` |
| Port | `ruby` @ `341104dabaa5d95e2ac1d0c0911ab79bb5c017df` |
| Units | 17 |
| Units with parity | **11 / 17** |
| Open gaps | **13** |
| Driven | yes — `test/drive_main_window.rb`, 16/16 checks, 4 screenshots under `tmp/shots/` (see the caveat in `.reports/test-parity.md`) |

Verdict: **not clean.** The widget trees, the CSS and the message set are in
very good shape; the gaps are concentrated in accessibility, in two divergences
the port made on purpose and reasoned about in a code comment, and in assets
and files that were never carried across.

## File mapping

```
src/application.rs + src/main.rs + src/config.rs.in   -> lib/application.rb, lib/main.rb, lib/config.rb
window.blp:4-47 + src/window.rs                       -> lib/app_window.rb
src/drag_overlay.rs                                   -> lib/drag_overlay.rb
window.blp:53-84                                      -> lib/welcome_page.rb
window.blp:86-97                                      -> lib/loading_page.rb
window.blp:331-341                                    -> lib/invalid_image_page.rb
window.blp:343-374                                    -> lib/converting_page.rb
window.blp:99-329 + src/window.rs (WindowUI etc.)     -> lib/convert_page.rb
window.blp:380-441                                    -> lib/all_images_page.rb
image-thumbnail.blp + src/widgets/image_thumbnail.rs  -> lib/image_thumbnail.rb
image-rest.blp + src/widgets/image_rest.rs            -> lib/image_rest.rb
window.blp:484-513                                    -> lib/primary_menu.rb
window.blp:448-482                                    -> lib/shortcuts_dialog.rb
src/window.rs:1463-1505                               -> lib/error_dialog.rb
src/window.rs:572-608 + :1543-1583                    -> lib/stop_converting_dialog.rb   (2 -> 1, factored)
src/widgets/about_window.rs                           -> lib/about_dialog.rb
data/resources/style.css                              -> lib/style.rb                    (CSS -> Ruby heredoc)
```

Correspondences recorded once, so they are not re-read as gaps: `Adw.` ↔
`Adwaita::`; no `.ui`/`.blp` in the port by house style (with the two GtkBuilder
heredocs in `lib/convert_page.rb` as the exception, forced by the accessibility
blocks); the two identical stop-converting dialogs merged into one class; the
stylesheet as a heredoc loaded through `Gtk::CssProvider`.

## Stylesheet

`lib/style.rb`'s `CSS` heredoc is upstream's `data/resources/style.css`
**rule for rule**, including the `@media (prefers-contrast: more)` block. The
only textual difference is upstream's element selector `dragoverlay { }`
appearing as `dragoverlay, .dragoverlay { }`, which is the `css-name` →
`css class` correspondence. Every app-namespaced class attached on either side
has a rule: `drag-overlay-status-page`, `card-content`, `image-caption`,
`image-remove`, `image-rest-button`, `lock`, `large_number`, `unit-drop`,
`long`, `no-padding`, `output-filetype-drop`. `image-container` and
`image-thumbnail` are attached on both sides and defined on neither — dead
upstream, dead here, parity. **Stylesheet: parity.**

## Messages

91 source msgids upstream, 91 in the port, key sets identical byte for byte
(`translation-parity/scripts/msgid-census.sh`, both trees, `comm -3` empty).
Every unit's `Text` column below is `✓` on that basis. Details in
`.reports/translation-parity.md`.

## Units

### 1. application — parity

| Item | Up × | Port × | Verdict |
|---|---:|---:|---|
| `app.quit`, `app.new-window` | 2 | 2 | parity (`lib/application.rb:139-147`) |
| accelerators | 7 | 7 | parity (`lib/application.rb:42-50`, same action→accel map) |
| `--new-window` main option + `handle-local-options` remote activation | 1 | 1 | parity (`lib/application.rb:123-135`) |
| `startup` default icon name + icon search path | 2 | 2 | parity (`lib/application.rb:92-96`) |
| `activate` / `open` | 2 | 2 | parity |
| Text | — | — | ✓ `Open a new window` |

Upstream's `adw::Application` subclass is matched by `Adwaita::Application`
(`lib/application.rb:86`), not worked around — `FINDINGS.md` §6 records that
the earlier claim the bindings could not do this was false.

### 2. window shell — parity

| Widget | Up × | Port × | CSS | Signals | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Adw.ApplicationWindow` | 1 | 1 | — | ✓ `close-request` | ✓ | parity |
| `Gtk.Box` root | 1 | 1 | — | — | — | parity |
| `$DragOverlay` | 1 | 1 | see unit 3 | — | ✓ | parity |
| `Adw.ToastOverlay` | 1 | 1 | — | — | — | parity |
| `Adw.NavigationView` | 1 | 1 | — | — | — | parity |
| `Adw.ToolbarView` / `Adw.HeaderBar` | 1/1 | 1/1 | — | — | — | parity (`show_title = false`) |
| `Gtk.Button` add | 1 | 1 | ✓ `flat` | ✓ `win.add` | ✓ | parity; `clicked`→action is a narrowing |
| `Gtk.MenuButton` | 1 | 1 | — | ✓ menu model | ✓ | parity |
| `Gtk.WindowHandle` | 1 | 1 | — | — | — | parity |
| `Gtk.Stack` | 1 | 1 | — | — | — | parity, 5 named children, crossfade |
| `Gtk.DropTarget` (controller) | 1 | 1 | — | ✓ `drop`, `notify::current-drop` | ✓ | parity |
| window actions | 6 | 6 | — | ✓ | — | parity (`lib/app_window.rb:60,227`) |
| toasts | 5 | 5 | — | — | ✓ | parity |

### 3. drag overlay — parity (one correspondence)

| Widget | Up × | Port × | CSS | Verdict |
|---|---:|---:|---|---|
| `Adw.Bin` root | 1 | 1 | css **name** `dragoverlay` → class `dragoverlay` | parity, correspondence |
| `Gtk.Overlay` | 1 | 1 | — | parity |
| `Gtk.Revealer` | 1 | 1 | — | parity (`can_target = false`, crossfade) |
| `Adw.StatusPage` | 1 | 1 | ✓ `drag-overlay-status-page` | parity |

`set_drop_target` disconnect-and-reattach is reproduced
(`lib/drag_overlay.rb:58-65,89-97`). Upstream's three GObject properties
(`title`, `child`, `drop-target`) become Ruby accessors — nothing in the app
binds to them, so this is a correspondence. `FINDINGS.md` §8 flags the css-name
claim as **unverified**; the rendered result was checked and matches.

### 4-7. welcome / loading / invalid-image / converting pages — parity

Every widget, every CSS class, every property and every msgid matches. The
welcome button's `clicked`→`win.add` substitution is the same narrowing as the
header-bar add button. Progress text transitions `Loading…` → `done/total` →
`Collecting files` all present (`lib/converting_page.rb:34-48`).

### 8. convert page — **3 gaps**

| Widget | Up × | Port × | CSS | Signals | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Adw.Bin` wrappers | 2 | 0 | — | — | — | **gap** |
| `Adw.PreferencesPage` | 1 | 1 | — | — | — | parity |
| `Adw.PreferencesGroup` | 4 | 4 | — | — | — | parity |
| `Gtk.FlowBox` image_container | 1 | 1 | — | ✓ filter func | — | parity |
| `Adw.ComboRow` output_filetype | 1 | 1 | ✓ `output-filetype-drop` | ✓ `notify::selected` | ✓ | parity |
| `Adw.ActionRow` ×8 | 8 | 8 | — | — | ✓ | parity |
| `Gtk.Switch` ×3 | 3 | 3 | — | ✓ | — | parity; `notify::state`→`notify::active` is equivalent for a Switch with no `state-set` handler |
| `Gtk.Scale` quality | 1 | 1 | — | — | ✓ | parity; adjustment 1..100 and the `labelled-by` relation built via the GtkBuilder fragment |
| `Gtk.ColorDialogButton` | 1 | 1 | — | ✓ `notify::rgba` | ✓ | **gap** — see below |
| `Gtk.Entry` ×5 | 5 | 5 | — | ✓ `changed` ×4 | ✓ | parity (built by the `pixel_entry` factory + `dpi_entry`) |
| `Gtk.ToggleButton` link_axis | 1 | 1 | ✓ `raised`,`circular`,`lock` | ✓ `clicked` | ✓ | parity, icon swap included |
| `Gtk.DropDown` resize_type | 1 | 1 | ✓ `flat`,`unit-drop` | ✓ `notify::selected` | ✓ | **gap** — extra tooltip |
| `Gtk.Box` `linked` + 2 `Gtk.ToggleButton` | 3 | 3 | ✓ `linked` | ✓ `toggled` ×2 | ✓ | parity, mutual-exclusion logic reproduced |
| `Gtk.Button` convert | 1 | 1 | ✓ `suggested-action`,`pill`,`long` | ✓ `clicked` | ✓ | parity |

Conditional visibility (`update_output_options`, `update_compression_options`,
`update_advanced_options`, `update_resize`) and the two linked-axis sync
directions were compared line by line against `src/window.rs:1641-1880` and
agree, including the "the target already implies the source" guard that stops
the two `changed` handlers bouncing.

> **gap — the colour button has no accessible label.** A screen-reader user
> picking a background colour is told nothing about it as a property of the
> control.
> Upstream: `src/window.rs:525-530`,
> `x.first_child().unwrap().update_property(&[Property::Label(...)])`.
> Port: `lib/convert_page.rb:561-567` calls `announce(...)` on the same child
> instead. `FINDINGS.md` §1 quotes the `NotImplementedError` that makes
> `update_property` uncallable. That is why the gap is expensive; it is not a
> reason the gap is closed.

> **gap — an extra tooltip on the resize-unit dropdown that upstream does not
> have.** Hovering the `%`/`px` dropdown shows a long sentence upstream never
> shows.
> Upstream: `window.blp:253-271` — `accessibility { label: ... }` and no
> `tooltip-text`.
> Port: `lib/convert_page.rb:409` `dd.tooltip_text = resize_units_label`. The
> comment at `lib/convert_page.rb:398-400` asserts the dropdown "carries both a
> tooltip and an `accessibility { label: … }` block"; it carries only the
> latter, so the comment states something that is not in the blueprint.

> **gap — the two `Adw.Bin` wrappers around the convert page are not built.**
> Upstream: `window.blp:102-103`, `Adw.Bin { Adw.Bin { Adw.PreferencesPage ... } }`.
> Port: `lib/convert_page.rb:67` `build` returns the `Adw.PreferencesPage`
> straight into `stack.add_named`. A transparent `Adw.Bin` renders nothing of
> its own, so nothing is visibly wrong today — and it is still two widgets
> upstream builds and the port does not.

### 9. all-images page — parity

Every widget, CSS class and property matches, including the 4-per-line flow
box, the 16px margins and the second spinner that
`switch_to_stack_loading_generally` needs.

### 10. image thumbnail — **2 gaps**

| Widget | Up × | Port × | CSS | Signals | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| root | 1 | 1 | ✓ `card`, `image-thumbnail` | — | — | parity; `Gtk.Widget` → `Adwaita::Bin` correspondence |
| `Gtk.Box` root / child | 1/1 | 1/1 | ✓ `card-content` / `image-container` | — | — | parity |
| `Gtk.Overlay` | 1 | 1 | — | — | — | parity |
| `Gtk.Box` | 3 | 3 | — | — | — | parity |
| `Gtk.Picture` | 1 | 1 | — | — | — | parity, `content-fit: cover`, 150×150 |
| `Gtk.Image` fallback | 1 | 1 | — | — | — | parity |
| `Adw.Bin` caption | 1 | 1 | ✓ `image-caption`, `caption` | — | — | parity |
| `Gtk.Label` content | 1 | 1 | — | — | — | parity, `FORMAT · W×H` |
| `Gtk.Button` remove | 1 | 1 | ✓ `circular`,`image-remove`,`osd` | ✓ `clicked` | ✓ | parity |
| `measure()` / `size_allocate()` | 2 vfuncs | 1 approximation | — | — | — | **gap** |

> **gap — the tile's width is a minimum, not a fixed natural size.**
> Upstream: `src/widgets/image_thumbnail.rs:120-131` — `measure()` returns
> min = nat = 150 on the horizontal orientation whenever the dimensions are
> known, so a wide photo and a tall one take exactly the same room in the flow
> box; `size_allocate()` allocates `root` the full size.
> Port: `lib/image_thumbnail.rb:159-164` uses
> `set_size_request(150, -1)` + `hexpand = false`, which pins the minimum and
> leaves the natural width to the picture. `FINDINGS.md` §7 states plainly that
> nobody has established whether ruby-gnome can override a `Gtk::Widget` vfunc
> — the experiment has not been run.

> **gap — every thumbnail is invisible to a screen reader.** Both flow boxes
> contain one `Gtk.FlowBoxChild` per image and neither carries an accessible
> label, so a screen reader announces an unnamed list item where upstream reads
> out "PNG · 1920×1080".
> Upstream: `src/window.rs:1901` and `src/window.rs:1957`,
> `image_flow_box_child.update_property(&[Property::Label(&caption)])` — on
> **every** child in both containers.
> Port: `lib/app_window.rb:552-565` `thumbnail_child` builds the
> `Gtk::FlowBoxChild` and sets no accessible property at all. This is the same
> `update_property` binding defect as the colour button, and unlike that one it
> is recorded **nowhere** — not in `FINDINGS.md`, not in `COMPONENT_PARITY.md`.

### 11. image rest — parity

All six widgets, all four CSS classes, the `clicked` handler, the icon name,
and both substituted msgids (`+{}`, `Show {} more images`) match, with the
substitution done *after* the lookup on both sides. The count arithmetic
(`files_count - 5`) matches.

### 12. primary menu — parity

2 sections, 5 items, same labels, same action names, same order.

### 13. shortcuts dialog — parity

1 section, 6 items, same `shortcut window` msgctxt on all seven strings, each
item naming an action so libadwaita resolves the accelerator from the
application — which binds the same seven accelerators.

### 14. error dialog — parity

Heading, extra child, the 200/400 content heights, the `card` and `monospace`
classes, both margins-and-alignment sets, both responses and the suggested
appearance all match. The `copy` branch sets the clipboard and raises the
`Error copied to clipboard` toast.

### 15. stop-converting dialog — parity

Both upstream call sites produce the same dialog; the port's one class is
presented from `convert_cancel` and from `on_close_request` with different
`on_stop` blocks, which is what upstream's two copies differ in.

### 16. about dialog — **1 gap**

| Item | Up × | Port × | Verdict |
|---|---:|---:|---|
| `Adw.AboutDialog` from appdata | 1 | 1 | parity — `lib/about_dialog.rb:110-148` reads the shipped metainfo with REXML and sets the same properties `from_appdata` sets |
| developers | 1 | 1 | parity |
| `translator-credits` | 1 | 1 | parity |
| other apps | 2 | 2 | **gap** — rows present, icons missing |
| acknowledgement sections | 2 | 2 | parity, same 8 entries |
| legal section | 1 | 1 | parity (`ImageMagick`, MIT/X11) |

> **gap — the two "Other Apps" rows have no icon.** The About dialog offers
> Impression and Footage with a blank or generic icon where upstream shows each
> app's own.
> Upstream ships `data/resources/icons/hicolor/scalable/apps/io.gitlab.adhami3310.Impression.svg`
> and `…Footage.svg`; `src/widgets/about_window.rs:23-36` names those ids.
> Port: `data/icons/hicolor/scalable/apps/` holds only the three Converter
> icons, and `lib/application.rb:162-168` adds that directory to the icon
> theme, so the two ids resolve to nothing.

### 17. stylesheet — parity

See **Stylesheet** above.

## Non-widget behaviour compared on the same four axes

These are not components, and three of them carry user-visible divergences, so
they are recorded here rather than left out.

| Unit | Verdict |
|---|---|
| `src/filetypes.rs` → `lib/file_type.rb` | 15 input / 13 output formats, 2 compression types, all 6 predicates, both mime/extension override tables — **parity**, with one dead-code divergence below |
| `src/magick.rs` → `lib/magick.rb` | argument builders, the three input-format special cases, `generate_job`'s four match arms, `move_output`'s four branches, `JobFile` naming and `Pasted Image.png` — **parity**, with one error-text gap below |
| `src/file_chooser.rs` → `lib/file_chooser.rb` | 3 dialogs, the `Images` filter over all 15 mimes, the accept label, the same-file guard, all four error msgids and the extension validation order — **parity** |
| `src/input_file.rs` → `lib/input_file.rb` | path/kind/sandbox/texture/frame-count/dimensions/area/caption — **parity** |
| `src/temp.rs` → `lib/temp_dir.rb` | sandbox detection, both parents, `file_path`, `clean` — **parity** |
| `src/color.rs` → `lib/color.rb` | truncating float→u8 conversion and `#rrggbbaa` ordering — **parity** |
| `gio::Settings` → `lib/settings.rb` | same schema id, same path, same 8 keys, same 3 enums, same index-not-nick storage (upstream's own bug, reproduced on purpose) — **1 gap below** |

> **gap — a maximized window forgets its size.** Closing Switcheroo maximized
> and reopening it un-maximized gives a different window size than upstream
> does.
> Upstream: `src/window.rs:2071-2082` `save_window_size()` writes
> `window-width`, `window-height` **and** `is-maximized` on every close,
> unconditionally.
> Port: `lib/settings.rb:93-98` writes `is-maximized` always but skips the two
> size keys `unless window.maximized?`. The comment above it offers a reason
> for the difference ("so the restored size is the one the user actually
> chose"), which is a divergence dressed as an improvement.

> **gap — a pasted image lands somewhere else, and so does the save dialog.**
> Paste an image, then press Convert: upstream's save dialog opens in the
> process's working directory, the port's opens in the temp directory.
> Upstream: `src/window.rs:634-637` writes the texture to
> `JobFile::as_filename()` — a bare relative filename, i.e. the CWD — and then
> `choose_destination` suggests `File.dirname` of it.
> Port: `lib/app_window.rb:400-410` writes it under `TempDir.parent`.

> **gap — a missing `zip` or `magick` no longer says which one.** If the
> binary is absent the user sees one generic sentence instead of the name of
> the program and the OS error.
> Upstream: `src/window.rs:1300` sends `"magick: " + e.to_string()` and
> `src/window.rs:1374` sends `"zip: " + e.to_string()`.
> Port: `lib/magick.rb:536-541` rescues `SystemCallError` and returns
> `_('Unknown IO error happened')` for every spawn failure.

> **gap — opening many images can hit the file-descriptor limit.**
> Upstream: `src/window.rs:679` calls `fdlimit::raise_fd_limit()` on every
> successful open, before probing.
> Port: `lib/app_window.rb:297-312` `open_success` does not raise the soft
> limit, so a large pick can fail where upstream succeeds.

> **gap — `FileType#output?` rejects `jpeg`.**
> Upstream: `src/filetypes.rs:93` `is_output()` matches `Jpeg` as well as
> `Jpg`.
> Port: `lib/file_type.rb:72` `output?` tests `OUTPUT_KEYS`, which has no
> `:jpeg`. Neither side calls the predicate today, so nothing is broken — it is
> a divergence in a predicate the next change could start using.

## Tree content upstream ships and the port does not

| Upstream path | State |
|---|---|
| `data/resources/icons/.../io.gitlab.adhami3310.Impression.svg` | **gap** — see unit 16 |
| `data/resources/icons/.../io.gitlab.adhami3310.Footage.svg` | **gap** — see unit 16 |
| `COPYING` | **gap** — the GPL-3.0 text is not in the port, while `switcheroo-rb.gemspec:18` declares `GPL-3.0-or-later` |
| `data/resources/screenshots/0.png`, `1.png` | **gap** — the metainfo the port ships cites both by URL (`data/io.gitlab.adhami3310.Converter.metainfo.xml.in.in:41,46`); the files themselves were not carried |
| `io.gitlab.adhami3310.Converter.json` (Flatpak manifest) | **gap** — the port cannot be built as a Flatpak |
| `Switcheroo.doap` | **gap** — the project metadata file |
| `PRESS.md` | **gap** |
| `update_translation.sh`, `build-aux/dist-vendor.sh` | **gap** — the translation-refresh script has no counterpart; see `.reports/translation-parity.md` |
| `meson.build`, `meson_options.txt`, `src/meson.build`, `data/**/meson.build`, `po/meson.build` | correspondence — replaced by `Rakefile` + `flake.nix`; the install task produces the same desktop file, service file, icons, schema and `.mo` tree |
| `Cargo.toml`, `Cargo.lock`, `src/config.rs.in`, `src/widgets/mod.rs` | correspondence — Ruby has no equivalent; the generated constants live in `lib/config.rb` |

## Steps 4 and 5

- **Step 4, styling renders.** `lib/style.rb` diffed against
  `data/resources/style.css`: equivalent (one css-name correspondence).
  Screenshots captured for the welcome page, the header bar, the convert page
  and the About dialog.
- **Step 5, behaviour fires.** `test/drive_main_window.rb` drives the real
  `App` under broadway in German and asserts 16 live properties — window
  visibility, the translated status-page title and add-button tooltip, the
  two-section menu model, the quality row's visibility and title and suffix
  child, the unit dropdown's label, the surviving `notify::rgba` pick, the
  stack's visible child after a crossfade, the translated convert button, the
  add button's reveal, and the About dialog's appdata-sourced developer name
  and release notes. 16/16 pass. The caveat is in
  `.reports/test-parity.md`: the driver cannot be run the way its own header
  documents.
- **Not driven**, and therefore not confirmed: drop-target reveal, clipboard
  paste, the full conversion pipeline, the error dialog, the stop dialog, the
  all-images page, the thumbnail strip's `+N` tile, and the accessibility
  assertions that would catch the two `update_property` gaps.
