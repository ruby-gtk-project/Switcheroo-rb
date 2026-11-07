# Translation parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` (unchanged) |
| Port | `ruby` @ `c5f0dbd08393214d7614d776155388a4624aaad2` |
| Upstream messages (distinct `(msgctxt, msgid)`) | **91** |
| Produced by the port | **91** |
| Gaps (key-set) | **0** |
| Languages upstream ships | 20 `.po` files, 19 listed in `LINGUAS` (upstream's own quirk) |
| Languages the port ships | the same 20, re-confirmed this round |
| Domain | `switcheroo`, both sides |

## Re-run this round, not trusted from the last pass

```
$ grep -c '^msgid "' po/switcheroo.pot
92                       # 91 real messages + 1 empty header msgid
$ ls po/*.po | wc -l
20
```

Unchanged from every prior round. The one commit since the last audit
(`c5f0dbd`) touches only `COMPONENT_PARITY.md` and does not add, remove or
reword a msgid anywhere in `lib/`, `data/` or `po/` — confirmed by `git show
c5f0dbd --stat` listing only that one file.

## `.pot` regeneration — still current

```
$ grep -c '^#:' po/switcheroo.pot
92
$ grep '^#:' po/switcheroo.pot | grep -c 'lib/\|data/'
92
$ grep '^#:' po/switcheroo.pot | grep -c 'src/\|\.rs:\|\.blp:'
0
```

Every `#:` reference in the committed `.pot` points at this tree
(`lib/*.rb`, `data/*`); zero reference comments point at upstream's
`src/*.rs` or `*.blp` paths. Unchanged since `d1ca7f4`.

## Spot-check: no reworded or unmarked string found

```
$ grep -n "_('Stop converting?')" lib/stop_converting_dialog.rb
lib/stop_converting_dialog.rb:40:      _('Stop converting?'),
$ git show origin/main:src/window.rs | grep -n '"Stop converting?"'
574:            Some(&gettext("Stop converting?")),
1545:            Some(&gettext("Stop converting?")),
```

Byte-identical. Upstream has no plural messages at all (`git grep ngettext
origin/main` and `grep msgid_plural po/switcheroo.pot` both return nothing
this round too) — the n_()/plural axis does not apply on either side.

## Upstream's own committed `.pot` is stale; the port's is not (carried forward, unchanged)

Five strings (`"+{}"`, `"Open a new window"`, `"Remove image"`, `"Resize
unit (percentage or pixels)"`, `"Show {} more images"`) are present in the
port's `.pot` and absent from upstream's own committed `.pot`, but all five
are real, live strings in upstream's **source** (`src/application.rs:47`,
`image-thumbnail.blp:47`, `image_rest.rs:65`, `gschema.xml.in:58`) that
upstream's own `.pot` has simply never been regenerated against. No gap
here: the comparison that matters is against live source strings, and the
port's regenerated `.pot` captures all 91 of them.

## Rules followed

- The key-set and `.pot` regeneration claim were both re-run/re-read this
  round rather than carried from the previous audit's narrative.
- No reworded msgid was found in the spot-check; none is reported as a gap
  that is not backed by a located byte-diff.
- The one commit since the last round was checked (`git show c5f0dbd
  --stat`) and confirmed to touch nothing translation-relevant, rather than
  assumed unchanged.
