# Translation parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` |
| Port | `ruby` @ `341104dabaa5d95e2ac1d0c0911ab79bb5c017df` |
| Upstream source messages | **91** |
| In the port, byte-identical | **91** |
| Message gaps | **0** |
| Languages upstream | 20 + `switcheroo.pot` |
| Languages in the port | 20 + `switcheroo.pot`, **byte-identical** |
| Open items | **2** (catalogue hygiene, not key gaps) |

## The key-set diff is empty

```sh
msgid-census.sh <upstream> | grep -v '\.pot\?:' | cut -f1,2 | sort -u > up.keys   # 91
msgid-census.sh <port>     | grep -v '\.pot\?:' | cut -f1,2 | sort -u > port.keys # 93
comm -23 up.keys port.keys   # (empty)  — nothing upstream has that the port lacks
comm -13 up.keys port.keys   # 2 rows, both '!unresolved' — see below
```

Not one msgid was reworded, retyped, un-marked or interpolated into. That is
the whole point of this ledger, and it holds.

The two `!unresolved` rows are scanner artifacts, not extra keys:
`lib/about_dialog.rb:81,85` call `_(appdata.name)` and `_(appdata.summary)`,
where the argument is a string read out of the AppStream metainfo at runtime.
`xgettext` cannot resolve a variable, so the census records it as unresolved —
but the metainfo's `<name>` and `<summary>` are themselves extracted into the
catalogue by xgettext's ITS rules (both are in the 91), and the runtime lookup
uses exactly those bytes. Upstream reaches the same result inside
`adw_about_dialog_new_from_appdata`. **Not a gap**, and it is the only place in
the port where a marker's argument is not a literal.

### The interpolation traps, all three handled

Three upstream msgids carry a `{}` placeholder, and all three substitute into
the *translated* string so the lookup key stays byte-identical:

| msgid | Upstream | Port |
|---|---|---|
| `New transparency layer color: {}` | `src/window.rs:528` `gettext(...).replace("{}", &y)` | `lib/convert_page.rb:562-564` `_(...).sub('{}', ...)` |
| `+{}` | `src/widgets/image_rest.rs:63` | `lib/image_rest.rb:86` |
| `Show {} more images` | `src/widgets/image_rest.rs:65` | `lib/image_rest.rb:94` |

No Ruby string interpolation reaches a marker anywhere in `lib/`.

### The msgctxt messages

Seven strings carry the `shortcut window` context. The port looks all seven up
with `p_('shortcut window', …)` (`lib/shortcuts_dialog.rb:302,313-318`), which
produces the same `(msgctxt, msgid)` pair upstream's `C_()` does. The context
survived.

## The catalogues

```sh
diff <upstream>/po/LINGUAS po/LINGUAS                  # identical
diff <(ls <upstream>/po/*.po) <(ls po/*.po)            # identical
for f in <upstream>/po/*.po <upstream>/po/*.pot; do cmp -s "$f" po/$(basename $f) || echo DIFFERS; done
                                                       # nothing printed
```

All 20 `.po` files and `switcheroo.pot` are **byte-identical** to upstream's.
Per-file msgid counts match one for one:

| | | | |
|---|---|---|---|
| ar 84 | bg 84 | cs 84 | de 84 |
| es 69 | fr 69 | hi 84 | hr 84 |
| it 69 | ka 86 | kw 86 | nl 69 |
| oc 84 | pt 69 | pt_BR 84 | ru 87 |
| sv 69 | tr 69 | uk 87 | zh_cn 84 |

`LINGUAS` lists all 20. The port compiles them: `Config.localedir`
(`lib/config.rb:216-218`) points at a `<lang>/LC_MESSAGES/switcheroo.mo` tree
that `rake locale` builds from `po/*.po` and `rake install` places under
`<prefix>/share/locale`. **The donated work survives.**

### The domain is bound, and it was driven

`lib/translations.rb` binds the `switcheroo` domain
(`Config::GETTEXT_PACKAGE`) through the `gettext` gem, because ruby-glib2
exposes no `bindtextdomain` (`FINDINGS.md` §3 quotes
`GLib.respond_to?(:bindtextdomain) # => false`). This is a correspondence, not
a gap — the key that reaches the catalogue is unchanged — and it is confirmed
end to end rather than argued: `test/drive_main_window.rb` runs the whole app
with `LANGUAGE=de` and asserts that the status-page title, the add-button
tooltip, the quality-row title and the convert button all come back German.
16/16 checks pass.

## The three non-code sources

All three are carried, and all three are in `po/POTFILES.in`:

| Upstream | Port | Messages |
|---|---|---|
| `data/io.gitlab.adhami3310.Converter.desktop.in.in` | `data/switcheroo.desktop.in` | `Name`, `GenericName`, `Comment`, `Keywords` — identical values; only `Icon=@icon@` is pre-resolved |
| `data/io.gitlab.adhami3310.Converter.metainfo.xml.in.in` | same name, **byte-identical** | `<name>`, `<summary>`, `<p>`, `<li>`, `<caption>` |
| `data/io.gitlab.adhami3310.Converter.gschema.xml.in` | same name, **byte-identical** | 8 `<summary>` elements |

A scan of `lib/` alone would have missed all of them; they are 24-odd of the 91.

## Open items

Neither is a msgid gap. Both are catalogue hygiene that a translator meets
before a user does.

> **1. The `.pot` was copied, not regenerated, so every source reference in it
> points at a file that does not exist here.** A translator who opens
> `po/switcheroo.pot` in Poedit and clicks a reference is sent to
> `src/window.rs:9`, `data/resources/blueprints/window.blp:21` or
> `data/io.gitlab.adhami3310.Converter.desktop.in.in:2`. None of those paths is
> in the port tree. `po/POTFILES.in` was rewritten correctly to name the Ruby
> files; the `.pot` generated from it was not. Its header still reads
> `POT-Creation-Date: 2026-04-12`, i.e. upstream's.

> **2. There is no way to refresh the catalogues.** Upstream ships
> `update_translation.sh`; the port ships no counterpart and the `Rakefile`'s
> `locale` task only compiles existing `.po` files — there is no
> `xgettext`-from-`POTFILES.in` step and no `msgmerge`. Today that costs
> nothing, because the key sets are equal. The first string anyone adds to
> `lib/` will be untranslatable and nothing will say so.

## Upstream bugs worth reporting

None found in the catalogue. The third case the skill asks to check
explicitly — a source string present in **no** `.po` at all, meaning
`xgettext` has never offered it to anyone — came back empty: every source
msgid appears in at least one catalogue, and `po/POTFILES.in` upstream lists
every file that carries a marker.

(There *is* an upstream bug in this app, but it is in the GSettings enum
storage, not in the catalogue: `FINDINGS.md`'s "Reported upstream" section has
it, and filing it is still outstanding — see
`.reports/accountability-ensurance.md`.)
