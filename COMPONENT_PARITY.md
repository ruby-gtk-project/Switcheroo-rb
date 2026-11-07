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
| `measure()`, horizontal clamp | **parity in effect, measured** — the vfunc itself still cannot be carried (`FINDINGS.md` §7), but `set_size_request(150, -1)` reaches the same numbers on every input the app can reach: `spec/image_thumbnail_spec.rb` builds the real widget for each of the 13 formats' captions at five-digit dimensions and GTK answers min = nat = 150 for all of them, which is exactly what upstream's override returns. The subtree's natural width only exceeds 150 for a caption wider than the picture, and `InputFile#caption` — `<FORMAT> · <W>×<H>`, a four-character format at most — never builds one. |
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
parity; their only failure was text, and the text is marked. **parity**,
including the drag overlay's CSS node, which is a real node name now:
`DragOverlay` calls `Gtk::Widget#set_css_name('dragoverlay')` from inside its
`type_register` block, so `css_name` reports `dragoverlay` rather than the
generic `widget`. A previous round claimed this binding had no route and left
that claim both in `FINDINGS.md` §8 and here uncorrected; it is corrected in
both places now (`FINDINGS.md` §8).

### Stylesheet

Unchanged: identical rule for rule to upstream's `data/resources/style.css`,
now matching the `dragoverlay` node directly rather than through a
compensating `.dragoverlay` class selector. **parity**.

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
| the `dragoverlay` CSS node was a style class, and `FINDINGS.md` §8 claimed the bindings have no route to a real node name | `Gtk::Widget#set_css_name` is callable from inside `type_register`; `DragOverlay` now calls it and `lib/style.rb` matches the node directly — `FINDINGS.md` §8, `lib/drag_overlay.rb` |
| `lib/application.rb`'s `GLib.application_name = APP_NAME` never went through gettext, unlike upstream's `glib::set_application_name(&gettext("Switcheroo"))` | wrapped as `_(APP_NAME)`, reaching the same `Switcheroo` msgid the window title and the welcome page already use |
| `COPYING`, `Switcheroo.doap`, `PRESS.md`, `data/resources/screenshots/{0,1}.png` were not carried | present; the screenshots are at `data/screenshots/` next to the other `data/` assets |
| `update_translation.sh` had no counterpart, so `po/switcheroo.pot` was still upstream's file and described `src/*.rs` and `*.blp` rather than this tree | `update_translation.sh` is ported, backed by `rake app:pot` and `rake app:update_po`, and **run**: the `.pot` now carries 91 keys with `lib/*.rb` and `data/*` references, and the 19 catalogues in `po/LINGUAS` are merged against it. Checked for loss rather than assumed — every non-fuzzy translation that the new `.pot` still asks for survived byte for byte in all 19 languages; the only entries demoted are three msgids (`Show Less Popular Datatypes` ×2, `Shows less popular datatypes in the menu`) left over from an older upstream release that neither upstream's `.pot` nor any source file holds any more. |
| `measure()`'s horizontal clamp was an untested gap | measured; see the image-thumbnail row |

## Remaining gaps

| Gap | Where |
|---|---|
| `size_allocate()` is not reproduced — Ruby widget vfuncs are not dispatched. The `measure()` half of the same finding no longer costs anything measurable (row above); this half has no equivalent, and what it buys upstream is that the root box is allocated the tile's whole area rather than its own requested size. | `lib/image_thumbnail.rb`, `FINDINGS.md` §7 |
| the colour announcement is an announcement, not a label | `lib/convert_page.rb`, `FINDINGS.md` §1 |
| `io.gitlab.adhami3310.Converter.json` is written from the spec (same desktop entry, metainfo, D-Bus service file, GSettings schema and icon install `rake app:install` would produce) but has never been run through `flatpak-builder`, because neither `flatpak-builder` nor an `org.gnome.Platform`/`org.gnome.Sdk` runtime is available in this environment. The gem native-extension builds, the GObject-introspection typelib lookups inside the sandbox, and the final desktop/metainfo substitution are all unexercised. Written-but-unverified, not "not started" — see `PORTING.md` for the full manifest contents. | `io.gitlab.adhami3310.Converter.json` |

Note: the absence of a GResource bundle (assets are read from `data/` instead) is **not** listed here as a gap — it is correspondence (no observable behavioural difference), per the main-window and about-dialog rows above (lines 45, 110).
