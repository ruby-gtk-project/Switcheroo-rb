# Translation parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `main` @ `ae72daf9fefe` |
| Port | `ruby` @ `e50a6654ab1c` |
| Upstream messages (distinct `(msgctxt, msgid)` from source) | **91** |
| Ported | **0** |
| Gaps | **91** |
| Languages upstream ships | 20 |
| Languages the port ships (`po/`) | 20 — byte-identical |
| Messages the port's `POTFILES.in` would actually extract from `lib/` | **0** |

## The headline

```
$ grep -rcE '\b(_|N_|C_|NC_|n_|p_|s_|np_|ngettext|pgettext)\(' lib/ exe/ | awk -F: '{s+=$2} END{print s}'
0
```

**There is not one translation marker in the port.** Every user-visible string
in `lib/` is a bare Ruby literal, usually hoisted into a frozen constant.
`po/POTFILES.in` lists seventeen `lib/*.rb` files; `xgettext` run over that
list extracts nothing from any of them. The port's catalogue is empty.

The `po/` directory itself came across intact and that is worth stating
precisely, because it is what makes this recoverable and also what makes it
expensive:

```
LINGUAS            identical
po/switcheroo.pot  identical
all 20 .po files   identical (md5 per file, 0 differences)
```

20 languages of donated human work sit in this repository, fully intact, keyed
on 91 English msgids, and **not one of those 91 keys is produced by the port at
runtime.** The translations are present and unreachable.

A second, independent break sits underneath: `lib/application.rb:170` guards
the bind behind `if GLib.respond_to?(:bindtextdomain)`. Even on a build where
that entry point exists, there is nothing for it to look up. The guard is
discussed in `.reports/accountability-ensurance.md` (hit 2) because of the
sentence attached to it.

## Catalogue cross-check

Per the skill, the upstream census was checked against a real catalogue before
being trusted. The committed `.pot` is the authority here and it is current:

```
POT-Creation-Date: 2025-10-31 15:28+0300      (upstream HEAD: 2025-11-01)
```

Comparing the `.pot`'s keys against the keys extracted from upstream source:
**no difference in either direction.** Every msgid upstream's source produces
is in the `.pot`, and every msgid in the `.pot` is produced by upstream's
source. There is no third-case string (one never extracted in any language) and
therefore no upstream bug to report, unlike gnome-contacts. `po/POTFILES.in`
upstream lists all thirteen source files that contribute, including the
gschema and the metainfo.

## Ledger

One row per upstream message, forever. State is `ported` or `gap`. There is no
third state.

Note on the fourth column: it is the **first substring match** of the msgid in
the port tree, so a short msgid can point at a longer literal that contains it
(`Add Images` → the `Add Images (Ctrl+O)` constant; `Images` → `All Images`;
`Resize` → `Resize Algorithm`; `Converting` → `Converting Cancelled`;
`Switcheroo` → `lib/about_dialog.rb`'s `APP_NAME`, which is also the window
title constant at `lib/app_window.rb:52`). The column exists to say where the
bytes already are, so the fix is a marker and not a retype; it is not a claim
that the literal is the right one. The state is `gap` either way.

### `data/resources/blueprints/window.blp` — 44 rows

| # | msgctxt | msgid | Bytes present in the port at | State |
|---|---|---|---|---|
| 1 | — | `%` | `lib/app_window.rb:70` (unmarked) | **gap** |
| 2 | — | `_Cancel` | `lib/converting_page.rb:18` (unmarked) | **gap** |
| 3 | — | `_Convert` | `lib/convert_page.rb:50` (unmarked) | **gap** |
| 4 | — | `_Open Images…` | `lib/welcome_page.rb:19` (unmarked) | **gap** |
| 5 | — | `About Switcheroo` | `lib/primary_menu.rb:20` (unmarked) | **gap** |
| 6 | `shortcut window` | `Add Images` | `lib/all_images_page.rb:20` (unmarked) | **gap** |
| 7 | — | `Add Images (Ctrl+O)` | `lib/all_images_page.rb:20` (unmarked) | **gap** |
| 8 | — | `All Images` | `lib/all_images_page.rb:16` (unmarked) | **gap** |
| 9 | — | `Background Color` | `lib/convert_page.rb:21` (unmarked) | **gap** |
| 10 | — | `Choose between resizing with percentages or using exact pixels` | `lib/convert_page.rb:58` (unmarked) | **gap** |
| 11 | — | `Clear Window` | `lib/primary_menu.rb:15` (unmarked) | **gap** |
| 12 | `shortcut window` | `Clear Window` | `lib/primary_menu.rb:15` (unmarked) | **gap** |
| 13 | — | `Converting` | `lib/app_window.rb:78` (unmarked) | **gap** |
| 14 | — | `Could not Load Image` | `lib/invalid_image_page.rb:14` (unmarked) | **gap** |
| 15 | — | `Default` | `lib/convert_page.rb:59` (unmarked) | **gap** |
| 16 | — | `Drag and drop images here` | `lib/welcome_page.rb:18` (unmarked) | **gap** |
| 17 | — | `Drop Here to Open` | `lib/drag_overlay.rb:28` (unmarked) | **gap** |
| 18 | — | `Export Format` | `lib/convert_page.rb:40` (unmarked) | **gap** |
| 19 | `shortcut window` | `General` | `lib/shortcuts_dialog.rb:8` (unmarked) | **gap** |
| 20 | — | `Height` | `lib/convert_page.rb:53` (unmarked) | **gap** |
| 21 | — | `Keyboard Shortcuts` | `lib/primary_menu.rb:19` (unmarked) | **gap** |
| 22 | — | `Loading…` | `lib/converting_page.rb:16` (unmarked) | **gap** |
| 23 | — | `New Window` | `lib/primary_menu.rb:14` (unmarked) | **gap** |
| 24 | `shortcut window` | `New Window` | `lib/primary_menu.rb:14` (unmarked) | **gap** |
| 25 | — | `Paste From Clipboard` | `lib/primary_menu.rb:13` (unmarked) | **gap** |
| 26 | `shortcut window` | `Paste From Clipboard` | `lib/primary_menu.rb:13` (unmarked) | **gap** |
| 27 | — | `Pixel Art` | `lib/convert_page.rb:59` (unmarked) | **gap** |
| 28 | — | `Pixel Density Per Inch` | `lib/convert_page.rb:25` (unmarked) | **gap** |
| 29 | — | `Preserve aspect ratio` | `lib/convert_page.rb:54` (unmarked) | **gap** |
| 30 | — | `Primary Menu` | `lib/app_window.rb:59` (unmarked) | **gap** |
| 31 | — | `px` | `lib/convert_page.rb:57` (unmarked) | **gap** |
| 32 | — | `Quality` | `lib/convert_page.rb:20` (unmarked) | **gap** |
| 33 | `shortcut window` | `Quit` | `lib/shortcuts_dialog.rb:17` (unmarked) | **gap** |
| 34 | — | `Remove Metadata` | `lib/convert_page.rb:28` (unmarked) | **gap** |
| 35 | — | `Replaces original transparency layer` | `lib/convert_page.rb:45` (unmarked) | **gap** |
| 36 | — | `Resize` | `lib/convert_page.rb:26` (unmarked) | **gap** |
| 37 | — | `Resize Algorithm` | `lib/convert_page.rb:26` (unmarked) | **gap** |
| 38 | — | `Save as multi-page PDF` | `lib/convert_page.rb:29` (unmarked) | **gap** |
| 39 | — | `Save To ZIP` | `lib/convert_page.rb:29` (unmarked) | **gap** |
| 40 | `shortcut window` | `Show Shortcuts` | `lib/shortcuts_dialog.rb:16` (unmarked) | **gap** |
| 41 | — | `Switcheroo` | `lib/about_dialog.rb:17` (unmarked) | **gap** |
| 42 | — | `This could take a while` | `lib/converting_page.rb:15` (unmarked) | **gap** |
| 43 | — | `This image could be corrupted or may use an unsupported file format.` | `lib/invalid_image_page.rb:15` (unmarked) | **gap** |
| 44 | — | `Width` | `lib/convert_page.rb:52` (unmarked) | **gap** |

### `src/window.rs` — 16 rows

| # | msgctxt | msgid | Bytes present in the port at | State |
|---|---|---|---|---|
| 45 | — | `_Cancel` | `lib/converting_page.rb:18` (unmarked) | **gap** |
| 46 | — | `_Close` | `lib/error_dialog.rb:16` (unmarked) | **gap** |
| 47 | — | `_Copy to Clipboard` | `lib/error_dialog.rb:17` (unmarked) | **gap** |
| 48 | — | `_Stop` | `lib/stop_converting_dialog.rb:10` (unmarked) | **gap** |
| 49 | — | `Collecting files` | `lib/converting_page.rb:11` (unmarked) | **gap** |
| 50 | — | `Converting Cancelled` | `lib/app_window.rb:78` (unmarked) | **gap** |
| 51 | — | `Error copied to clipboard` | `lib/app_window.rb:77` (unmarked) | **gap** |
| 52 | — | `Error While Processing` | `lib/error_dialog.rb:13` (unmarked) | **gap** |
| 53 | — | `Image converted` | `lib/app_window.rb:75` (unmarked) | **gap** |
| 54 | — | `Loading…` | `lib/converting_page.rb:16` (unmarked) | **gap** |
| 55 | — | `New transparency layer color: {}` | **nowhere** | **gap** |
| 56 | — | `Open` | `lib/app_window.rb:76` (unmarked) | **gap** |
| 57 | — | `Stop converting?` | `lib/stop_converting_dialog.rb:14` (unmarked) | **gap** |
| 58 | — | `Unable to access dropped files` | `lib/app_window.rb:73` (unmarked) | **gap** |
| 59 | — | `Unsupported filetype` | `lib/app_window.rb:74` (unmarked) | **gap** |
| 60 | — | `You will lose all progress.` | `lib/stop_converting_dialog.rb:15` (unmarked) | **gap** |

### `src/widgets/about_window.rs` — 7 rows

| # | msgctxt | msgid | Bytes present in the port at | State |
|---|---|---|---|---|
| 61 | — | `Code and Design Borrowed from` | `lib/about_dialog.rb:36` (unmarked) | **gap** |
| 62 | — | `Create bootable drives` | `lib/about_dialog.rb:31` (unmarked) | **gap** |
| 63 | — | `Footage` | `lib/about_dialog.rb:32` (unmarked) | **gap** |
| 64 | — | `Impression` | `lib/about_dialog.rb:31` (unmarked) | **gap** |
| 65 | — | `Polish your videos` | `lib/about_dialog.rb:32` (unmarked) | **gap** |
| 66 | — | `Sample Image from` | `lib/about_dialog.rb:45` (unmarked) | **gap** |
| 67 | — | `translator-credits` | `lib/about_dialog.rb:86` (unmarked) | **gap** |

### `src/file_chooser.rs` — 6 rows

| # | msgctxt | msgid | Bytes present in the port at | State |
|---|---|---|---|---|
| 68 | — | `_Select Images` | `lib/file_chooser.rb:27` (unmarked) | **gap** |
| 69 | — | `Images` | `lib/all_images_page.rb:5` (unmarked) | **gap** |
| 70 | — | `Unknown filetype` | `lib/file_chooser.rb:32` (unmarked) | **gap** |
| 71 | — | `Unspecified filetype` | `lib/file_chooser.rb:22` (unmarked) | **gap** |
| 72 | — | `Unsupported filetype` | `lib/app_window.rb:74` (unmarked) | **gap** |
| 73 | — | `Used the wrong filetype` | `lib/file_chooser.rb:33` (unmarked) | **gap** |

### `src/widgets/image_rest.rs` — 2 rows

| # | msgctxt | msgid | Bytes present in the port at | State |
|---|---|---|---|---|
| 74 | — | `+{}` | **nowhere** | **gap** |
| 75 | — | `Show {} more images` | **nowhere** | **gap** |

### `data/resources/blueprints/image-rest.blp` — 1 rows

| # | msgctxt | msgid | Bytes present in the port at | State |
|---|---|---|---|---|
| 76 | — | `Show All` | `lib/all_images_page.rb:6` (unmarked) | **gap** |

### `data/resources/blueprints/image-thumbnail.blp` — 1 rows

| # | msgctxt | msgid | Bytes present in the port at | State |
|---|---|---|---|---|
| 77 | — | `Remove image` | `lib/image_thumbnail.rb:25` (unmarked) | **gap** |

### `src/magick.rs` — 2 rows

| # | msgctxt | msgid | Bytes present in the port at | State |
|---|---|---|---|---|
| 78 | — | `Pasted Image` | `lib/temp_dir.rb:70` (unmarked) | **gap** |
| 79 | — | `Unknown IO error happened` | **nowhere** | **gap** |

### `src/main.rs` — 1 rows

| # | msgctxt | msgid | Bytes present in the port at | State |
|---|---|---|---|---|
| 80 | — | `Switcheroo` | `lib/about_dialog.rb:17` (unmarked) | **gap** |

### `src/application.rs` — 1 rows

| # | msgctxt | msgid | Bytes present in the port at | State |
|---|---|---|---|---|
| 81 | — | `Open a new window` | `lib/application.rb:44` (unmarked) | **gap** |

### `data/io.gitlab.adhami3310.Converter.gschema.xml.in` — 8 rows

| # | msgctxt | msgid | Bytes present in the port at | State |
|---|---|---|---|---|
| 82 | — | `Compression format` | **nowhere** | **gap** |
| 83 | — | `Image density per inch` | **nowhere** | **gap** |
| 84 | — | `Image quality` | **nowhere** | **gap** |
| 85 | — | `Output format` | **nowhere** | **gap** |
| 86 | — | `Resize unit (percentage or pixels)` | **nowhere** | **gap** |
| 87 | — | `Window height` | **nowhere** | **gap** |
| 88 | — | `Window maximized state` | **nowhere** | **gap** |
| 89 | — | `Window width` | **nowhere** | **gap** |

### `data/io.gitlab.adhami3310.Converter.metainfo.xml.in.in` — 5 rows

| # | msgctxt | msgid | Bytes present in the port at | State |
|---|---|---|---|---|
| 90 | — | `Convert and manipulate images` | `lib/about_dialog.rb:20` (unmarked) | **gap** |
| 91 | — | `Convert between different image filetypes and resize them easily.` | **nowhere** | **gap** |
| 92 | — | `Converting multiple sample images from SVG to HEIF` | **nowhere** | **gap** |
| 93 | — | `Converting sample image from PNG to HEIF` | **nowhere** | **gap** |
| 94 | — | `Switcheroo` | `lib/about_dialog.rb:17` (unmarked) | **gap** |

### `data/io.gitlab.adhami3310.Converter.desktop.in.in` — 5 rows

| # | msgctxt | msgid | Bytes present in the port at | State |
|---|---|---|---|---|
| 95 | — | `Convert and manipulate images` | `lib/about_dialog.rb:20` (unmarked) | **gap** |
| 96 | — | `converter;image;convert;converting;processing` | `data/switcheroo.desktop:10` (unmarked) | **gap** |
| 97 | — | `Image Converter` | `data/switcheroo.desktop:3` (unmarked) | **gap** |
| 98 | — | `New Window` | `lib/primary_menu.rb:14` (unmarked) | **gap** |
| 99 | — | `Switcheroo` | `lib/about_dialog.rb:17` (unmarked) | **gap** |

99 rows over 91 distinct `(msgctxt, msgid)` keys — eight keys are contributed
by two upstream files each (`_Cancel`, `Loading…`, `Switcheroo` ×3,
`New Window`, `Unsupported filetype`, `Convert and manipulate images`,
`Clear Window`/`New Window`/`Paste From Clipboard`/`Add Images` in both their
plain and `shortcut window` forms). The catalogue key count is 91; the number
to close is 91.

## The gaps that are not just a missing marker

Fourteen rows above say **nowhere**, and each is a second piece of work beyond
adding `_()`:

### Interpolation — 3 rows

The port built these with Ruby string interpolation, which runs before any
marker could see it, so the lookup key differs on every call and matches
nothing in any of the 20 catalogues.

| msgid | Upstream | Port | Fix |
|---|---|---|---|
| `+{}` | `src/widgets/image_rest.rs:65` | `Gtk::Label.new("+#{@count}")` — `lib/image_rest.rb:71` | `_('+{}').sub('{}', @count.to_s)` |
| `Show {} more images` | `src/widgets/image_rest.rs:67` | `"Show #{@count} more images"` — `lib/image_rest.rb:79` | `_('Show {} more images').sub('{}', @count.to_s)` |
| `New transparency layer color: {}` | `src/window.rs:528` | the handler does not exist | build the `notify::rgba` handler, then the same `sub` |

Upstream uses `{}` placeholders and `.replace("{}", …)` rather than printf
formats, so the port must do the same substitution **after** the lookup. These
are the easiest three rows in the ledger to "fix" wrongly, by reaching for
`format` with a `%s` the catalogues do not contain.

### A string the port replaced with a different one — 1 row

| msgid | Upstream | Port |
|---|---|---|
| `Unknown IO error happened` | `src/magick.rs:301` | `"#{command.first}: #{e.message}"` — `lib/magick.rb:538` |

Not a rewording: a different sentence, in a different language register,
interpolating a libc error string that is itself locale-dependent and that no
translator has ever seen.

### A whole file not shipped: the GSettings schema — 8 rows

`data/io.gitlab.adhami3310.Converter.gschema.xml.in` has no counterpart in the
port. Its eight `<summary>` elements are extracted by `xgettext`'s GSettings
ITS rules and are translated in the shipped catalogues. The port keeps the same
eight keys in a JSON file (`lib/settings.rb:25-34`) with no summaries at all,
so the eight msgids have nowhere to come from, and dconf-editor / `gsettings
describe` show the user nothing. See `.reports/accountability-ensurance.md`
hit 3 for the sentence that presents this as settled.

### A whole file not shipped: the AppStream metainfo — 4 rows

`data/io.gitlab.adhami3310.Converter.metainfo.xml.in.in` has no counterpart.
Its `<description><p>` and two `<caption>` elements are translated msgids; the
`<name>` and `<summary>` overlap with the desktop file's. Beyond the four
rows, the absent file costs the port its software-centre listing, its branding
colours, its two screenshots, its `<requires>`/`<recommends>` form-factor
hints, its donation and help URLs, and the fourteen `<release>` entries the
About dialog's "What's New" reads — see `.reports/component-parity.md`, About
dialog unit.

## The desktop file

`data/switcheroo.desktop` carries upstream's five translatable keys with
byte-identical English and is listed in `POTFILES.in`, so extraction works. But
it is a **plain `.desktop`, not a `.desktop.in`**, and the port has no build or
install step of any kind (no `meson.build`, no `install` task in the
`Rakefile`). Upstream runs `i18n.merge_file` at install time to fold the
translated `Name`, `GenericName`, `Comment` and `Keywords` back into the
installed file. Nothing in the port does, so even once the markers are added,
the launcher entry stays English in all 20 languages. `Icon=@icon@` was
resolved by hand to `io.gitlab.adhami3310.Converter`, which is right for the
default profile and loses upstream's devel profile.

The file also declares `DBusActivatable=true` while the port ships no
`io.gitlab.adhami3310.Converter.service` (upstream's
`data/…Converter.service.in` has no counterpart), so D-Bus activation of the
port fails.

## What closing this looks like

1. Pick the marker set. The port depends on no i18n gem today; `po/` is a
   gettext catalogue, so `gettext` (the `GetText` module, `_`, `n_`, `p_`,
   `s_`) is the obvious choice, and `p_('shortcut window', …)` is **required**
   for the seven context rows — `_()` on those produces the wrong key.
2. Mark all 91, against the bytes above. Never adjust an msgid to match a
   constant: upstream's bytes are what 20 catalogues are keyed on.
3. Fix the three interpolations with post-lookup `sub`, not `format`.
4. Port `gschema.xml.in` and `metainfo.xml.in.in` into the port tree and list
   them in `POTFILES.in`, as upstream does.
5. Build `.mo` files from `po/` and install them where
   `GLib.bindtextdomain` points (`lib/application.rb:176` currently points at
   the raw `po/` directory, which holds `.po` sources, not compiled `.mo`
   catalogues — so the bind would fail to find anything even with markers in
   place). That is a sixth, separate defect and it is a gap of its own.
