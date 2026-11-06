# Translation parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` |
| Port | `ruby` @ `5ec22388b7dd5ea9ec0c27dbebeac2a8bd86ab46` |
| Upstream messages (distinct `(msgctxt, msgid)`) | **91** |
| Produced by the port | **91** |
| Gaps (key-set) | **0** |
| Languages upstream ships | 20 `.po` files, 19 in `LINGUAS` (upstream's own quirk — `zh_cn.po` exists and is not listed; re-confirmed against `origin/main`, not a port-introduced gap) |
| Languages the port ships | the same 20, byte-identical `.po` files, re-confirmed this round |
| Domain | `switcheroo`, both sides |

```
$ grep -c '^msgid "' po/switcheroo.pot
92                       # 91 real messages + 1 empty header msgid
$ ls po/*.po | wc -l
20
$ diff <(ls po/*.po|xargs -n1 basename -s .po|sort) <(sort po/LINGUAS)
20d19
< zh_cn                  # present in both the upstream tree and this port,
                          # inherited, not introduced
```

This round re-ran the key-set check rather than trusting the prior pass's
91/91: `po/switcheroo.pot` is upstream's extracted catalogue (verified
identical in content to the one `rake app:pot` regenerates from the port's
own source — see below), and all 20 `.po` files are byte-for-byte copies of
upstream's, re-diffed this round.

## The catalogue-level claim holds, and the extraction route now works

`9f4999c`'s audit found `po/switcheroo.pot` was upstream's file, never
regenerated, and that there was no task to regenerate it (`rake pot` was
named in `flake.nix` and did not exist). That gap is **closed**, verified by
running it, not by reading the Rakefile:

```
$ cp po/switcheroo.pot /tmp/before.pot
$ nix develop --command rake app:pot
rxgettext --output=... lib/about_dialog.rb lib/all_images_page.rb ... (18 files)
xgettext --output=... data/switcheroo.desktop.in data/*.gschema.xml.in data/*.metainfo.xml.in.in
msgcat --output=po/switcheroo.pot --use-first --sort-by-file ...
wrote po/switcheroo.pot
$ diff /tmp/before.pot po/switcheroo.pot
(only the POT-Creation-Date header line differs)
$ git checkout -- po/switcheroo.pot        # left the tree clean afterward
```

So the port can now regenerate its own catalogue from its own source and get
upstream's message set back, which is the strongest evidence this skill asks
for: the catalogue is not merely identical by coincidence, it is reproducible.

## The one real gap: a call site that never reaches the shared key

The 91/91 key-set match does **not** mean every place upstream calls
`gettext("Switcheroo")` has a port counterpart that does the same. One does
not:

- Upstream: `glib::set_application_name(&gettext("Switcheroo"))`
  (`src/main.rs:45`).
- Port: `GLib.application_name = APP_NAME` (`lib/application.rb:85`), where
  `APP_NAME = 'Switcheroo'` is a bare Ruby constant (`lib/config.rb:17`),
  never passed through `_()`.

The msgid `"Switcheroo"` **is** in the port's catalogue — it is produced by
three *other* call sites (`lib/welcome_page.rb:33`, `lib/app_window.rb:133`,
`lib/app_window.rb:147`), so the key-set diff reports this message
`ported` and is correct to do so; the catalogue genuinely has the key. But
`GLib.application_name`, which upstream deliberately translates so that the
app's registered display name follows the user's locale, is this port's one
remaining English-only literal. `po/ar.po:121` and `po/uk.po:122` both
already carry a translated `"Switcheroo"` that this call site cannot reach.

This is a **uses-mismatch**, per this skill's own rule: the key exists, so it
is not a catalogue gap, but the call-site count is asymmetric in a way that
costs a real user a real translation. Recorded here as the finding the rule
exists for, and in `component-parity.md`'s gap table (#1) as the component
side of the same defect. One edit — wrapping `APP_NAME` in `_()` at the one
call site that currently skips it — closes both.

## Languages

All 20 `.po` files are present, byte-identical to upstream's (re-diffed this
round), and the port installs a `.mo` per language through
`rake app:locale` (unchanged from the prior audit, not re-verified by a
fresh `msgfmt` run this round — noting that as an unrun check rather than
reporting it as proven).

## `de` on screen

Not re-run this round. The previous audit (`9f4999c`) verified
`LANGUAGE=de LC_ALL=de_DE.UTF-8` produces a translated string on screen; this
audit did not repeat that specific check and is reporting it as **not
re-verified**, rather than carrying forward "verified" from a different
commit's run. The catalogue underneath it has not changed (same 91 messages,
same `.mo` build path), so there is no known reason it would have regressed,
but "no known reason" is not the same claim as "checked".

## Rules followed

- The one gap above is reported as a uses-mismatch, not as a catalogue gap,
  because the key genuinely exists in the catalogue — conflating the two
  would either hide a real defect (reporting 91/91 and stopping) or invent a
  92nd message that was never missing.
- Nothing here claims the `de` check passed this round; it is named as unrun.
- The extraction-task fix is reported as proven by running it, with the
  working tree left clean afterward, not as proven by reading the Rakefile.
