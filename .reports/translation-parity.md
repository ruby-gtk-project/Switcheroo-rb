# Translation parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` (unchanged) |
| Port | `ruby` @ `fb196babe2113d47395c5efc48bf491b447190cc` |
| Upstream messages (distinct `(msgctxt, msgid)`) | **91** |
| Produced by the port | **91** |
| Gaps (key-set) | **0** |
| Languages upstream ships | 20 `.po` files, 19 listed in `LINGUAS` (upstream's own quirk — `zh_cn.po` exists and is not listed; confirmed against `origin/main` itself, not a port-introduced gap) |
| Languages the port ships | the same 20, re-confirmed this round |
| Domain | `switcheroo`, both sides |

## Re-run this round, not trusted from the last pass

```
$ grep -c '^msgid "' po/switcheroo.pot
92                       # 91 real messages + 1 empty header msgid
$ ls po/*.po | wc -l
20
$ nix develop --command msgfmt --statistics po/de.po -o /dev/null
80 translated messages, 1 fuzzy translation, 10 untranslated messages.
```

91 real msgids, 20 catalogues, consistent with the figures the last two
audits reported.

## The `.pot` regeneration — previously reported as "not done," now done

Both `.reports/translation-parity.md`'s own previous text and the last
pass's root `TRANSLATION_PARITY.md` carried a "Not done" section saying
`po/switcheroo.pot` was still upstream's extracted file, citing `src/*.rs`
and `*.blp` rather than this tree. That changed in `d1ca7f4`/the work
leading into it — `Rakefile` now has a real `app:pot` task, and the
committed `.pot` was regenerated from the port's own source. Re-verified
this round by reading the file directly, not by re-running the generator:

```
$ grep -c '^#:' po/switcheroo.pot
92
$ grep '^#:' po/switcheroo.pot | grep -c 'lib/\|data/'
92
$ grep '^#:' po/switcheroo.pot | grep -c 'src/\|\.rs:\|\.blp:'
0
```

Every `#:` reference comment in the committed `.pot` now points at
`lib/*.rb` or `data/*` — `lib/about_dialog.rb:91`, `lib/about_dialog.rb:155`,
`data/io.gitlab.adhami3310.Converter.gschema.xml.in:30`, and so on. Zero
reference comments to upstream's `src/*.rs` or `*.blp` paths remain. The
`.pot` describes this tree now, and `COMPONENT_PARITY.md`'s "Closed this
round" entry for this item is accurate.

## Spot-check: no reworded or unmarked string found among the sample

A sample of msgids pulled from `po/switcheroo.pot` and grepped back against
`lib/` and upstream for byte-identical literals:

```
$ grep -n "_('Stop converting?')" lib/stop_converting_dialog.rb
lib/stop_converting_dialog.rb:40:      _('Stop converting?'),
$ git show origin/main:src/window.rs | grep -n '"Stop converting?"'
574:            Some(&gettext("Stop converting?")),
1545:            Some(&gettext("Stop converting?")),
```

Byte-identical. Also confirmed this round: upstream has **no plural
messages at all** (`git grep ngettext origin/main` and `grep
msgid_plural po/switcheroo.pot` both return nothing) — so the n_()/plural
axis this skill usually checks for drift does not apply to this app, on
either side. This is a spot-check, not a re-derivation of the full 91-row
census — the full row-by-row mapping lives in `TRANSLATION_PARITY.md` at
the repo root, which this report does not duplicate, only re-verifies the
totals and the regeneration claim against.

## New this round: upstream's own committed `.pot` is stale, and the port's is not

Diffing `po/switcheroo.pot` msgid-for-msgid against `origin/main`'s own
`po/switcheroo.pot` (not against the port) surfaces 5 strings present in the
port's `.pot` and absent from upstream's committed one: `"+{}"`, `"Open a
new window"`, `"Remove image"`, `"Resize unit (percentage or pixels)"`,
`"Show {} more images"`. Before counting these as a port-side extra, each
was traced back into upstream's own **source**, not its `.pot`:

```
$ git grep -n "Open a new window" origin/main -- src   → src/application.rs:47, gettext(...)
$ git grep -n "Remove image" origin/main -- data        → image-thumbnail.blp:47, _("Remove image")
$ git grep -n "Show {} more images" origin/main -- src  → image_rest.rs:65, gettext(...)
$ git grep -n "Resize unit" origin/main -- data          → gschema.xml.in:58, <summary>
```

All five are real, live upstream strings that upstream's own `po/
switcheroo.pot` has simply never had `update_translation.sh`/`ninja
switcheroo-pot` re-run against since they were added — upstream's shipped
`.pot` is stale relative to upstream's own source. The port's regenerated
`.pot` (via its own `rake app:pot`) correctly captures all of them, which is
why the key-set re-derivation above counts 91 on both sides when the two
*committed .pot files* disagree by 5: the comparison that matters is against
live source strings, not against whichever `.pot` snapshot happens to be
checked in. No gap here — if anything this is the port's `.pot` being more
current than the file it was supposedly ported from.

## Rules followed

- The key-set and the `.pot` regeneration claim were both re-run/re-read
  this round rather than carried from the previous audit's narrative.
- The previous "not done" claim about `.pot` regeneration is corrected here
  rather than silently dropped — see the section above.
- No reworded msgid was found in the spot-check; none is reported as a gap
  that is not backed by a located byte-diff.
