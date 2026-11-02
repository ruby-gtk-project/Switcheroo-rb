# Translation parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe` |
| Port | `ruby` branch |
| Upstream messages (distinct `(msgctxt, msgid)` from source) | **91** |
| Produced by the port | **91** |
| Gaps | **0** |
| Languages upstream ships | 20 (`po/`), 19 in `LINGUAS` |
| Languages the port ships | the same 20, byte-identical |

```
$ grep -rcE '\b(_|N_|C_|NC_|n_|p_|s_|np_|ngettext|pgettext)\(' lib/ exe/ | awk -F: '{s+=$2} END{print s}'
# was 0 last round
```

## How this was checked

Not by reading. The port's own catalogue was extracted the way upstream
extracts its own, from `po/POTFILES.in`, and compared key for key against
`po/switcheroo.pot`:

```sh
rxgettext -o rb.pot $(grep -v '^#' po/POTFILES.in | grep '\.rb$')
xgettext  -o data.pot switcheroo.desktop.in …gschema.xml …metainfo.xml
msgcat    -o all.pot rb.pot data.pot
```

Every one of the 86 keys the committed `.pot` holds is produced by the port,
with the same `msgctxt` where there is one. The remaining five are discussed
under "The third case" below: upstream's source produces them and upstream's
own catalogue does not hold them.

Then it was driven. With `po/de.po` compiled into
`locale/de/LC_MESSAGES/switcheroo.mo` and the locale set to `de`, the running
app shows `Bilder hierher ziehen und ablegen`, `Qualität`, `_Umwandeln`,
`Allgemein` and `Bilder hinzufügen (Ctrl+O)` — see `test/drive_main_window.rb`
and `tmp/shots/01-welcome.png`.

## How the port marks

`lib/translations.rb` binds the `switcheroo` domain through the `gettext` gem
at `Config.localedir`, and every class that shows text includes it. ruby-glib2
exposes no `GLib.bindtextdomain` here (`FINDINGS.md` §3), so the gem does the
lookup against the same compiled `.mo` files.

Three rules the previous round got wrong, and what they are now:

1. **No translated string is a constant.** A constant is evaluated when the
   file is required, which is before any locale is in effect. Every marked
   string is looked up inside the method that uses it.
2. **The seven `shortcut window` messages use `p_`, not `_`.** They carry a
   msgctxt, so `_()` would build a key no catalogue holds.
   `lib/shortcuts_dialog.rb` uses `p_('shortcut window', …)` for all seven.
3. **`{}` placeholders are substituted after the lookup.** Upstream uses
   `.replace("{}", …)` and not a printf format, so the port writes
   `_('+{}').sub('{}', @count.to_s)`. Three msgids need this: `+{}` and
   `Show {} more images` (`lib/image_rest.rb`) and
   `New transparency layer color: {}` (`lib/convert_page.rb`).

## Files that had to be ported before their messages could exist

| Upstream file | Port | Messages |
|---|---|---|
| `data/io.gitlab.adhami3310.Converter.gschema.xml.in` | same name under `data/` | 8 `<summary>` |
| `data/io.gitlab.adhami3310.Converter.metainfo.xml.in.in` | same name under `data/` | 4 |
| `data/io.gitlab.adhami3310.Converter.desktop.in.in` | `data/switcheroo.desktop.in` | 5 |

All three are listed in `po/POTFILES.in` and extract under xgettext's ITS
rules, as upstream's do.

## The build and install path

Upstream's `po/meson.build` compiles the catalogues and `i18n.merge_file`
folds the translated launcher keys back into the installed desktop entry. The
port does the same from the `Rakefile`:

- `rake app:locale` → `locale/<lang>/LC_MESSAGES/switcheroo.mo` for each of the
  19 languages in `LINGUAS`, via `msgfmt --check-format`.
- `rake app:install` → the same tree under `<prefix>/share/locale`;
  `msgfmt --desktop` over `data/switcheroo.desktop.in` so `Name`,
  `GenericName`, `Comment` and `Keywords` are translated in the installed
  launcher; `msgfmt --xml` over the metainfo so the software centre shows the
  translated name and summary.

`lib/config.rb` resolves the locale directory, honouring
`SWITCHEROO_LOCALEDIR` so an installed copy reads the installed tree.

## The third case — five messages upstream produces and never extracted

This is a finding against **upstream**, not the port, and it contradicts the
previous round's report, which recorded "no third-case string".

| msgid | Upstream source | In `po/switcheroo.pot`? | In any `.po`? |
|---|---|---|---|
| `Open a new window` | `src/application.rs:47` | no | no |
| `+{}` | `src/widgets/image_rest.rs:63` | no | no |
| `Show {} more images` | `src/widgets/image_rest.rs:65` | no | no |
| `Remove image` | `data/resources/blueprints/image-thumbnail.blp:47` | no | no |
| `Resize unit (percentage or pixels)` | `data/…gschema.xml.in` `<summary>` | no | no |

`po/POTFILES.in` upstream lists neither `src/application.rs` nor
`src/widgets/image_rest.rs` nor
`data/resources/blueprints/image-thumbnail.blp`, so three of the five can
never be extracted there; the gschema summary is listed but missing from the
committed `.pot`, which makes that file stale as well. 20 languages have
therefore never been offered these five strings, and they are English in every
locale upstream ships.

The port **marks all five anyway**, with upstream's exact bytes, and lists the
three files in its own `POTFILES.in`. Nothing is adjusted to match the stale
`.pot`: when upstream fixes its extraction, the port's keys already line up.

This is owed upstream as a report and has not been filed — `PORTING.md`,
"Still open".

## Ledger

One row per upstream message. `ported` means the port's extraction produces
that exact `(msgctxt, msgid)` pair.

| # | msgctxt | msgid | State |
|---|---|---|---|
| 1 | — | `%` | ported |
| 2 | — | `_Cancel` | ported |
| 3 | — | `_Close` | ported |
| 4 | — | `_Convert` | ported |
| 5 | — | `_Copy to Clipboard` | ported |
| 6 | — | `_Open Images…` | ported |
| 7 | — | `_Select Images` | ported |
| 8 | — | `_Stop` | ported |
| 9 | — | `About Switcheroo` | ported |
| 10 | — | `Add Images (Ctrl+O)` | ported |
| 11 | — | `All Images` | ported |
| 12 | — | `Background Color` | ported |
| 13 | — | `Choose between resizing with percentages or using exact pixels` | ported |
| 14 | — | `Clear Window` | ported |
| 15 | — | `Code and Design Borrowed from` | ported |
| 16 | — | `Collecting files` | ported |
| 17 | — | `Compression format` | ported |
| 18 | — | `Convert and manipulate images` | ported |
| 19 | — | `Convert between different image filetypes and resize them easily.` | ported |
| 20 | — | `converter;image;convert;converting;processing` | ported |
| 21 | — | `Converting` | ported |
| 22 | — | `Converting Cancelled` | ported |
| 23 | — | `Converting multiple sample images from SVG to HEIF` | ported |
| 24 | — | `Converting sample image from PNG to HEIF` | ported |
| 25 | — | `Could not Load Image` | ported |
| 26 | — | `Create bootable drives` | ported |
| 27 | — | `Default` | ported |
| 28 | — | `Drag and drop images here` | ported |
| 29 | — | `Drop Here to Open` | ported |
| 30 | — | `Error copied to clipboard` | ported |
| 31 | — | `Error While Processing` | ported |
| 32 | — | `Export Format` | ported |
| 33 | — | `Footage` | ported |
| 34 | — | `Height` | ported |
| 35 | — | `Image converted` | ported |
| 36 | — | `Image Converter` | ported |
| 37 | — | `Image density per inch` | ported |
| 38 | — | `Image quality` | ported |
| 39 | — | `Images` | ported |
| 40 | — | `Impression` | ported |
| 41 | — | `Keyboard Shortcuts` | ported |
| 42 | — | `Loading…` | ported |
| 43 | — | `New transparency layer color: {}` | ported |
| 44 | — | `New Window` | ported |
| 45 | — | `Open` | ported |
| 46 | — | `Output format` | ported |
| 47 | — | `Paste From Clipboard` | ported |
| 48 | — | `Pasted Image` | ported |
| 49 | — | `Pixel Art` | ported |
| 50 | — | `Pixel Density Per Inch` | ported |
| 51 | — | `Polish your videos` | ported |
| 52 | — | `Preserve aspect ratio` | ported |
| 53 | — | `Primary Menu` | ported |
| 54 | — | `px` | ported |
| 55 | — | `Quality` | ported |
| 56 | — | `Remove Metadata` | ported |
| 57 | — | `Replaces original transparency layer` | ported |
| 58 | — | `Resize` | ported |
| 59 | — | `Resize Algorithm` | ported |
| 60 | — | `Sample Image from` | ported |
| 61 | — | `Save as multi-page PDF` | ported |
| 62 | — | `Save To ZIP` | ported |
| 63 | — | `Show All` | ported |
| 64 | — | `Stop converting?` | ported |
| 65 | — | `Switcheroo` | ported |
| 66 | — | `This could take a while` | ported |
| 67 | — | `This image could be corrupted or may use an unsupported file format.` | ported |
| 68 | — | `translator-credits` | ported |
| 69 | — | `Unable to access dropped files` | ported |
| 70 | — | `Unknown filetype` | ported |
| 71 | — | `Unknown IO error happened` | ported |
| 72 | — | `Unspecified filetype` | ported |
| 73 | — | `Unsupported filetype` | ported |
| 74 | — | `Used the wrong filetype` | ported |
| 75 | — | `Width` | ported |
| 76 | — | `Window height` | ported |
| 77 | — | `Window maximized state` | ported |
| 78 | — | `Window width` | ported |
| 79 | — | `You will lose all progress.` | ported |
| 80 | `shortcut window` | `Add Images` | ported |
| 81 | `shortcut window` | `Clear Window` | ported |
| 82 | `shortcut window` | `General` | ported |
| 83 | `shortcut window` | `New Window` | ported |
| 84 | `shortcut window` | `Paste From Clipboard` | ported |
| 85 | `shortcut window` | `Quit` | ported |
| 86 | `shortcut window` | `Show Shortcuts` | ported || 87 | — | `Open a new window` | ported (third case) |
| 88 | — | `+{}` | ported (third case) |
| 89 | — | `Show {} more images` | ported (third case) |
| 90 | — | `Remove image` | ported (third case) |
| 91 | — | `Resize unit (percentage or pixels)` | ported (third case) |

## Not done

`po/switcheroo.pot` is still upstream's file. Regenerating it from the port's
`POTFILES.in` would renumber every source reference in it and in all 20 `.po`
files, which is a separate change and a noisy one; the extraction above is run
from a scratch copy instead. Until it is regenerated, the committed `.pot` does
not describe this tree.
