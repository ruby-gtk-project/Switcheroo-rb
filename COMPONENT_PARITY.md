# Component parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe` |
| Port | `ruby` branch |
| Units | 17 |

This ledger replaces the reading-only verdicts of
`.reports/component-parity.md`. **The port was loaded and driven this round**,
which the previous pass could not do: `gtk4-broadwayd` gives GTK a display with
no graphics hardware, so `spec/` runs 70 examples against real widgets and
`test/drive_main_window.rb` builds the real application and walks it. The first
thing that found was a startup crash the reading pass had marked `parity` —
see "What driving caught" below.

Three states, no fourth: **parity**, **correspondence** (a different mechanism,
located and justified against a verified binding defect), **gap**.

## The text axis

Closed. All 91 upstream msgids are produced; `TRANSLATION_PARITY.md` has the
ledger. Where a unit's only previous failure was text, it is now parity.

## What driving caught

`lib/application.rb` called `Gtk::IconTheme.for_display`, which does not exist
in these bindings (the bound name is `get_for_display`). `add_icon_search_path`
therefore raised inside the `startup` handler on every launch the port has ever
had, so the nine icons it ships were never findable.
`.reports/component-parity.md` lists "Icon search path" as `parity` at
`lib/application.rb:158`. It was read, not run. Fixed; `FINDINGS.md` §5.

## Unit ledger

### application object — `src/main.rs` + `src/application.rs` → `lib/application.rb`, `lib/config.rb`, `lib/main.rb`

| Item | Port | Verdict |
|---|---|---|
| App id, `HANDLES_OPEN`, `--new-window`, `app.quit`, `app.new-window`, 7 accelerators | `lib/application.rb` | parity |
| Base class `adw::Application` | `Adwaita::Application` | **parity** (was a gap; the binding was never broken — `FINDINGS.md` §6) |
| Icon search path | `Gtk::IconTheme.get_for_display` | **parity** (was raising; see above) |
| gettext domain in effect | `lib/translations.rb`, bound at `Config.localedir` | **parity** |
| Build-time constants (`src/config.rs.in`) | `lib/config.rb` | parity |
| GResource bundle registration | none; assets read from `data/` | correspondence |

### main window — `window.blp` + `src/window.rs` → `lib/app_window.rb`

Widgets, CSS classes, the six window actions, the drop target and the six toast
sites are as the previous pass found them, and the text on all of them is now
marked. Behaviour **driven**, not read (`spec/app_window_spec.rb`, 20
examples):

| Behaviour | Pinned by |
|---|---|
| `Children` starts canceled, so a fresh window closes without the stop dialog | `spec/magick_spec.rb` |
| a removed thumbnail keeps its index, so later removals hit the right file | `spec/app_window_spec.rb` |
| the last removal clears the window | `spec/app_window_spec.rb` |
| `construct_short_thumbnail`'s look-ahead gives the sixth slot to the `+N` tile | `spec/app_window_spec.rb` |
| a removed file still gets an empty `FlowBoxChild` | `spec/app_window_spec.rb` |
| `unique_stems` turns two `cover`s into `cover` and `cover_1` | `spec/app_window_spec.rb` |
| `frames_for` expands a PDF and a non-animatable animation, reads the rest as `[0]` | `spec/app_window_spec.rb` |
| the 1–2 / 3+ flow-box width switch | `spec/app_window_spec.rb` |

| Gap | Detail |
|---|---|
| correspondence | `New transparency layer color: {}` — upstream writes the colour button's accessible `Label` property on every pick (`src/window.rs:525-530`). `lib/convert_page.rb` connects `notify::rgba` and **announces** the same translated string on the same child instead, because `update_property` raises `NotImplementedError` here (`FINDINGS.md` §1). The user is told; the mechanism differs. |
| parity | `Unknown IO error happened` — `lib/magick.rb` reports upstream's msgid when the spawn itself fails, instead of the interpolated `"#{command.first}: #{e.message}"` it used to. |
| extra, explained | The port calls `convert_clean` from both the cancel and close dialogs; upstream leaves the temp directory behind on those two paths. Strictly better; recorded so it is not mistaken for a misread. |

### convert page — `window.blp` `stack_convert` + `src/window.rs` → `lib/convert_page.rb`

Widgets and CSS as before, text marked. New this round:

| Item | Verdict |
|---|---|
| `accessibility { labelled-by: quality_row }` on the quality `Scale` (`window.blp:155-159`) | **parity** — attached by the `GtkBuilder` fragment that creates the row, its adjustment and the scale (`FINDINGS.md` §2) |
| `accessibility { label: … }` on the resize-unit `DropDown` (`window.blp:243-247`) | **parity** — same route |
| `notify::rgba` on the colour button | correspondence, above |
| the four resize entries' placeholder/tooltip pairs, including `resize_scale_height_value`'s mismatched pair (`window.blp:243-244`) | **parity** |
| the stored enum representation (`save_options`, `load_options`, `stored_output`, `stored_compression`) | **parity** — the same integer upstream writes, upstream's index bug included; `FINDINGS.md`, "Reported upstream" |

Behaviour driven by `spec/convert_page_spec.rb` (19 examples): every
conditional row (quality / dpi / resize-algorithm / metadata / background /
compression / single-PDF), the percentage↔pixel entry swap, `mirror_scale`
under an open and a closed chain, and the save/load round trip through the
schema.

### image thumbnail — `image-thumbnail.blp` + `image_thumbnail.rs` → `lib/image_thumbnail.rb`

| Item | Verdict |
|---|---|
| `measure()`, horizontal clamp | **parity** — `set_size_request(150, -1)`, so the width is pinned and the caption strip gets its natural height. Was 150×150, which squeezed the caption against the picture on every tile. |
| `size_allocate()` | **gap** — not reproduced; whether the bindings can carry a widget vfunc override is **untested** (`FINDINGS.md` §7) |
| `Button remove_image { name: "remove_image"; }` (`image-thumbnail.blp:46`) | **parity** — the widget name is set |
| `Remove image` tooltip | parity (marked) |

### "+N" tile — `image-rest.blp` + `image_rest.rs` → `lib/image_rest.rb`

| Item | Verdict |
|---|---|
| `icon-name: "view-more-horizontal-symbolic"` (`image-rest.blp:9`) | **parity** — set |
| `+{}` and `Show {} more images` | **parity** — looked up first, `{}` substituted after |

### About dialog — `src/widgets/about_window.rs` → `lib/about_dialog.rb`

| Item | Verdict |
|---|---|
| construction | **parity in effect** — upstream calls `from_appdata(metainfo, VERSION)`; the port parses the same shipped metainfo and sets exactly the fields libadwaita's `from_appdata` sets. There is no GResource to read it from, so the parse is REXML: correspondence on the mechanism, parity on every field. |
| developer name, description paragraph, name, icon, licence | **parity** — read from the metainfo |
| homepage / bugtracker / help URLs | **parity** |
| 14 `<release>` entries → "What's New" | **parity** — `release_notes` + `release_notes_version` for the release matching `Config::VERSION` |
| donation / translate / contribute / vcs-browser URLs | **not owed** — `AdwAboutDialog` has no property for them and `from_appdata` does not read them either; upstream's dialog does not show them. Only `add_link` could, and that needs a title string no catalogue holds. |
| `VERSION` | **parity** — `Config::VERSION`, one place, ported from upstream's `src/config.rs.in` / `meson.build:3` |
| `copyright` | removed — the metainfo declares none, so `from_appdata` sets none; the port used to invent one |
| developers, translator credits, 2 other apps, 2 acknowledgement sections, ImageMagick legal section | parity |

### Data files that had no counterpart

| Upstream | Port | Verdict |
|---|---|---|
| `data/…gschema.xml.in` | shipped verbatim; backs `lib/settings.rb` via `Gio::Settings`; installed and compiled by `rake app:install` | **parity** |
| `data/…metainfo.xml.in.in` | shipped verbatim; read by the About dialog; installed after `msgfmt --xml` | **parity** |
| `data/…service.in` | shipped; installed, so `DBusActivatable=true` is no longer a lie | **parity** |
| `data/…desktop.in.in` | `data/switcheroo.desktop.in`; installed through `msgfmt --desktop` | **parity** |
| `…Converter.Devel.svg`, `symbolic/apps/…Converter-symbolic.svg` | copied into `data/icons` | **parity** |

### The other units

welcome page, loading page, invalid-image page, converting page, all-images
page, drag overlay, shortcuts dialog, primary menu, stop-converting alert,
error alert, file chooser: widgets, CSS, signals and actions were already
parity; their only failure was text, and the text is marked. **parity**, except
the drag overlay's CSS node, which stays a **correspondence** whose binding
claim is **untested** (`FINDINGS.md` §8).

### Stylesheet

Unchanged: identical rule for rule to upstream's `data/resources/style.css`,
with `dragoverlay, .dragoverlay` covering both forms. **parity**.

## Remaining gaps

| Gap | Where |
|---|---|
| `size_allocate()` not reproduced; vfunc overrides untested | `lib/image_thumbnail.rb`, `FINDINGS.md` §7 |
| the colour announcement is an announcement, not a label | `lib/convert_page.rb`, `FINDINGS.md` §1 |
| the `dragoverlay` CSS-node claim is untested | `lib/drag_overlay.rb`, `FINDINGS.md` §8 |
| no GResource bundle | `lib/`, assets read from `data/` |
