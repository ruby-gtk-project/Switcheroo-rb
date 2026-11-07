# Translation parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` |
| Port | `ruby` @ `c409c40a179995cef2c5e895b9748603de5f8a4b` |
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

## Rules followed

- The key-set and the `.pot` regeneration claim were both re-run/re-read
  this round rather than carried from the previous audit's narrative.
- The previous "not done" claim about `.pot` regeneration is corrected here
  rather than silently dropped — see the section above.
- No reworded msgid was found in the spot-check; none is reported as a gap
  that is not backed by a located byte-diff.
