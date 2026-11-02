# Translation parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` |
| Port | `ruby` @ `d15487b137763f668e1bf23284beb7f99989a1da` |
| Domain | `switcheroo` on both sides (`domain_source: po/*.pot`) |
| Upstream messages | **91** |
| Ported | **91** |
| Gaps | **0** |
| Extra (untranslated) | **0** |
| `kind_mismatch` | 0 (upstream has no plural forms at all) |
| `with_context` | 7 upstream, 7 in the port |
| Upstream occurrences | 112 across 91 messages (12 reused) |
| Port occurrences | 104 |
| Upstream languages | 20 `.po` files · 1,467 translated · 61 untranslated · 37 fuzzy |
| Languages shipped by the port | **20** — `po/` byte-identical to upstream's |
| Build command | `rake app:locale` (ran: `locale/<lang>/LC_MESSAGES/switcheroo.mo` ×20) |
| `de` verified on screen | **yes** |
| Open gaps in this ledger | **2** (X1, X2) |

Verdict: **not clean — 2 gaps.** The catalogue itself is in perfect shape:
`summary.parity` holds on all four document conditions, and German reaches the
screen. The two gaps are one unmarked call site and the absence of any way to
regenerate the catalogue.

## The numbers

```
91/91 messages · 104/112 occurrences · 20/20 languages · 1,467 strings · de verified on screen
```

```sh
comm -23 up.keys port.keys | wc -l   # 0  gaps
comm -13 up.keys port.keys | wc -l   # 0  extra
comm -12 up.keys port.keys | wc -l   # 91 ported
diff <(ls up/po/*.po|xargs -n1 basename) <(ls port/po/*.po|xargs -n1 basename)   # empty
```

`kind` agrees on all 91 shared keys. Upstream declares no plurals, so there is
no `n_()` to get wrong.

## Where the messages come from

| Upstream file | Messages | Port file |
|---|---:|---|
| `data/resources/blueprints/window.blp` | 42 | `lib/app_window.rb`, `lib/welcome_page.rb`, `lib/loading_page.rb`, `lib/invalid_image_page.rb`, `lib/converting_page.rb`, `lib/convert_page.rb`, `lib/all_images_page.rb`, `lib/primary_menu.rb`, `lib/shortcuts_dialog.rb` |
| `src/window.rs` | 17 | `lib/app_window.rb`, `lib/error_dialog.rb`, `lib/stop_converting_dialog.rb`, `lib/magick.rb` |
| `src/widgets/about_window.rs` | 7 | `lib/about_dialog.rb` |
| `src/file_chooser.rs` | 6 | `lib/file_chooser.rb` |
| `src/widgets/image_rest.rs` | 2 | `lib/image_rest.rb` |
| `data/resources/blueprints/image-thumbnail.blp` | 1 | `lib/image_thumbnail.rb` |
| `src/drag_overlay.rs` | 1 | `lib/drag_overlay.rb` |
| `src/magick.rs` | 2 | `lib/magick.rb`, `lib/temp_dir.rb` |
| `src/application.rs` | 1 | `lib/application.rb` |
| `src/main.rs` | 1 | **unmarked — gap X1** |
| `data/…gschema.xml.in` | 8 | same file, byte-identical |
| `data/…metainfo.xml.in.in` | 5 | same file, byte-identical |
| `data/…desktop.in.in` | 5 | `data/switcheroo.desktop.in`, same keys |

The three non-code sources contribute 18 of the 91. They are upstream's own
files, carried byte for byte, so they cannot drift.

## Unresolved markers — censused by hand

The port's census reports `unresolved: 2`. Both are in
`lib/about_dialog.rb`, where upstream's
`adw_about_dialog_new_from_appdata()` is reimplemented over the shipped
metainfo:

| Site | Marker | Resolves to |
|---|---|---|
| `lib/about_dialog.rb:81` | `_(appdata.name)` | `Switcheroo` — `data/…metainfo.xml.in.in` `<name>`, already a census row from that file |
| `lib/about_dialog.rb:85` | `_(appdata.summary)` | `Convert and manipulate images` — the same file's `<summary>`, already a row |

Neither adds a key the catalogue does not already hold, so the ledger is
complete at 91. Upstream reaches the same two strings through libadwaita's own
appdata reader rather than through a marker, which is why it has no unresolved
rows of its own.

## `uses` mismatch — 112 → 104, every row explained

Not a pass condition. Every difference was read rather than reported:

| msgid | Up | Port | Why |
|---|---:|---:|---|
| `Stop converting?` | 2 | 1 | the two identical `AlertDialog`s of `src/window.rs:572-608` and `:1543-1583` are one `StopConvertingDialog` class |
| `You will lose all progress.` | 2 | 1 | same merge |
| `_Stop` | 2 | 1 | same merge |
| `_Cancel` | 3 | 2 | `window.blp:364`'s cancel button survives; the stop dialog's two sites merge to one |
| `Width` | 5 | 3 | `pixel_entry(placeholder, tooltip)` puts both markers for one entry on one source line, which the census counts once |
| `Height` | 3 | 2 | same |
| `Switcheroo` | 6 | 5 | **gap X1** — `src/main.rs:45` has no counterpart |

Six of the seven are structural and belong to `COMPONENT_PARITY.md`, where the
widgets are already accounted for. The seventh is a missing call site and is
recorded in both ledgers.

## `POTFILES.in` completeness — clean

```sh
comm -13 <(grep -v '^#' po/POTFILES.in | grep . | sort) \
         <(msgid-census.sh . | cut -f4 | cut -d: -f1 | grep -v '^po/' | sort -u)
```

prints nothing: every port file that contains a marker is listed. 18 entries,
3 metadata and 15 Ruby. `POTFILES.skip` is correctly absent — upstream's lists
nothing a Ruby port generates.

Upstream's own `POTFILES.in` is complete too; the gnome-contacts hole does not
exist here.

## What else lives in `po/`

- **20 languages**, `LINGUAS` and the `.po` files agreeing except for `zh_cn`,
  which is present as a file and absent from `LINGUAS` — **upstream's defect,
  carried verbatim**, so Simplified Chinese is translated and not built.
  Reported here rather than silently fixed; fixing it in the port alone would
  make the port's `po/` diverge from the only copy that gets refreshed.
- **37 fuzzy entries**, counted as untranslated: `rmsgfmt` leaves them out of
  the `.mo` and the user sees English. Same 37 on both sides.
- **61 untranslated.** 1,467 + 61 + 37 = 1,565 messages across the 20 files,
  which reconciles against `msgid` lines minus one header each.
- No CRLF file in this set.

## Delivery — verified on screen

`rake app:locale` compiles all 20 catalogues into
`locale/<lang>/LC_MESSAGES/switcheroo.mo`, and `lib/translations.rb` binds the
domain there via `Config.localedir`, with `SWITCHEROO_LOCALEDIR` honoured for
an installed copy. Driven under `LANGUAGE=de`:

| Widget | Shown |
|---|---|
| welcome `Adw.StatusPage` description | `Bilder hierher ziehen und ablegen` |
| menu button tooltip | `Primäres Menü` |
| `Export Format` combo row | `Exportformat` |
| shortcuts section title (`C_()` context) | `Allgemein` |
| **`GLib.application_name`** | **`Switcheroo`** — gap X1 |

The context-carrying lookup working is worth stating on its own: the gem's
`p_()` resolves `msgctxt "shortcut window"` correctly, so all seven
context messages are live and not silently falling through to the untranslated
msgid.

## Gaps

### X1 — the application name is the one string the port never marked

> I did not mark the application name, because I am an idiot who read a
> constant out of a build file and not the `gettext()` wrapped around it one
> line later.
> Upstream: `src/main.rs:45`,
> `glib::set_application_name(&gettext("Switcheroo"))`.
> Port: `lib/application.rb:85`, `GLib.application_name = APP_NAME`, where
> `lib/config.rb:17` is `APP_NAME = 'Switcheroo'`.

Text still owed: `Switcheroo` — already in the catalogue, so this is
transcription into a marker, not authorship. The cost is concrete: `po/ar.po`
translates it `سويتشيرو` and `po/uk.po` translates it `Міняло`, and Arabic and
Ukrainian users of the port see neither. The key set is unaffected, so
`summary.parity` reads `true` the whole time — which is why this row exists
here as well as in `component-parity.md` (gap G1).

### X2 — no extraction target, so the catalogue is frozen

> I did not build the extraction task, because I am an idiot who typed its name
> into the dev shell's banner and stopped there.
> Upstream: `update_translation.sh` runs meson's `switcheroo-pot` target, and
> `switcheroo-update-po` is one commented line away.
> Port: `rake -T` lists `app:locale`, `app:clean_locale` and `app:install` and
> no extraction task; `flake.nix:192` nonetheless states that `rxgettext` is
> "the extractor `rake pot` drives".

Two consequences, both already true today:

- `po/switcheroo.pot` is upstream's file, unchanged, so its `#:` source
  references name `src/window.rs` and `window.blp` lines that do not exist in
  this tree. A translator handed it would be navigating the Rust app.
- Any message the port adds is invisible to everyone. It cannot be extracted,
  cannot be merged into the 20 `.po` files, and the `POTFILES.in` completeness
  check above is a command in a report rather than a step in a target — which
  is the hole the `translation-parity` skill specifically says to wire into
  whatever runs the tests.

`rxgettext` is already in the dev shell (`flake.nix:195`), so the gap is a Rake
task.

## Open items, stated rather than left implied

- The catalogue is a snapshot. It was taken from `ae72daf` and l10n.gnome.org
  works against upstream, never against this fork. Refreshing is
  `git checkout origin/main -- po/` plus a merge, and the sha to diff from is
  the one in this header.
- `zh_cn`'s absence from `LINGUAS` is upstream's bug and is not filed upstream.
- The `output-format` enum defect drafted at the foot of `FINDINGS.md` (the
  schema's nicks are unreachable because both sides write an index) is still
  not filed upstream.
