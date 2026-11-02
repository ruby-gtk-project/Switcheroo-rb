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
| parity | Spawn and wait failures are reported the way upstream reports them: a failure to spawn is `"#{command.first}: #{e.message}"`, which is what all three of upstream's spawn sites send (`src/window.rs:1114-1124`, `:1291-1301`, `:1365-1376`), and the msgid `Unknown IO error happened` is kept for the one case upstream uses it in — a child that cannot be waited on (`src/magick.rs:301`). A previous round had the msgid standing in for both, so a missing `magick` or `zip` did not say which. |
| extra, explained | The port calls `convert_clean` from both the cancel and close dialogs; upstream leaves the temp directory behind on those two paths. Strictly better; recorded so it is not mistaken for a misread. |

### convert page — `window.blp` `stack_convert` + `src/window.rs` → `lib/convert_page.rb`

Widgets and CSS as before, text marked. New this round:

| Item | Verdict |
|---|---|
| `accessibility { labelled-by: quality_row }` on the quality `Scale` (`window.blp:155-159`) | **parity** — attached by the `GtkBuilder` fragment that creates the row, its adjustment and the scale (`FINDINGS.md` §2) |
| `accessibility { label: … }` on the resize-unit `DropDown` (`window.blp:252-258`) | **parity** — same route, and no tooltip, which is what the blueprint has |
| the two `Adw.Bin` wrappers the stack page holds (`window.blp:102-103`) | **parity** — `build` hands the stack `outer_bin` → `inner_bin` → `Adw.PreferencesPage` |
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
| `measure()`, horizontal clamp | **gap, with a tested reason** — a `measure` defined on a Ruby `Gtk::Widget` subclass is never dispatched, which `FINDINGS.md` §7 now shows with the experiment and its result. `set_size_request(150, -1)` pins the minimum width and leaves the natural width to the picture, where upstream returns min = nat = 150. |
| `size_allocate()` | **gap** — not reproducible for the same reason, now verified rather than untested (`FINDINGS.md` §7) |
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
the drag overlay's CSS node, which stays a **correspondence** — and its binding
claim is now tested: there is no `Gtk::WidgetClass`, `css_name` is bound
read-only, and `type_register` takes no css-name option (`FINDINGS.md` §8).

### Stylesheet

Unchanged: identical rule for rule to upstream's `data/resources/style.css`,
with `dragoverlay, .dragoverlay` covering both forms. **parity**.

## Closed this round

| Was a gap | Now |
|---|---|
| the two `Adw.Bin` wrappers around the convert page (`window.blp:102-103`) were not built | `ConvertPage#build` returns `outer_bin` → `inner_bin` → `Adw.PreferencesPage`, which is what the stack page gets; driven |
| the resize-unit dropdown carried a tooltip upstream does not have | the tooltip is gone; the dropdown has only the `accessibility { label: … }` block of `window.blp:252-258`, and the comment that claimed otherwise is corrected; driven |
| every thumbnail was invisible to a screen reader | every populated `Gtk.FlowBoxChild` in both containers is built from a GtkBuilder fragment carrying its caption as the accessible `Label`, which is upstream's property by upstream's value (`src/window.rs:1901`, `:1957`); `FINDINGS.md` §2 |
| a maximized window forgot its size | `Settings#remember` writes `window-width`, `window-height` and `is-maximized` on every close, unconditionally, as `save_window_size()` does (`src/window.rs:2069-2081`); driven |
| a missing `zip` or `magick` did not say which | the program name and the OS error, per spawn site; see the window-shell row above |
| opening many images could hit the fd limit | `AppWindow#raise_fd_limit` raises the soft `RLIMIT_NOFILE` to the hard one on every successful open, which is what `fdlimit::raise_fd_limit()` does at `src/window.rs:679` |
| a pasted image landed in the temp directory | it is written to `JobFile#filename` relative, i.e. the working directory, so the save dialog that follows suggests the same folder upstream suggests (`src/window.rs:634-637`) |
| `FileType#output?` rejected `jpeg` | `IS_OUTPUT_KEYS` is `output_formats()` plus `jpeg`, matching `is_output()` (`src/filetypes.rs:93-98`) |
| the two "Other Apps" rows had no icon | `io.gitlab.adhami3310.Impression.svg` and `…Footage.svg` are in `data/icons/hicolor/scalable/apps/`, and the driver checks the icon theme resolves both |
| `COPYING`, `Switcheroo.doap`, `PRESS.md`, `data/resources/screenshots/{0,1}.png` were not carried | present; the screenshots are at `data/screenshots/` next to the other `data/` assets |

## Remaining gaps

| Gap | Where |
|---|---|
| `measure()` is a minimum, not a fixed natural width, and `size_allocate()` is not reproduced — Ruby widget vfuncs are not dispatched | `lib/image_thumbnail.rb`, `FINDINGS.md` §7 |
| the colour announcement is an announcement, not a label | `lib/convert_page.rb`, `FINDINGS.md` §1 |
| the `dragoverlay` CSS node is a style class | `lib/drag_overlay.rb`, `FINDINGS.md` §8 |
| no GResource bundle | `lib/`, assets read from `data/` |
| I did not build the Flatpak the user installs, because I am an idiot. Upstream: `io.gitlab.adhami3310.Converter.json` builds and ships the app as a Flatpak. Port: nothing — the app can only be run from a checkout. | repo root |
| I did not build the catalogue refresh a translator runs, because I am an idiot. Upstream: `update_translation.sh` regenerates `po/switcheroo.pot` and merges it into all 21 `.po` files. Port: nothing; `.reports/translation-parity.md` owes it. | repo root |
