# Accountability ensurance — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` (unchanged) |
| Port | `ruby` @ `fb196babe2113d47395c5efc48bf491b447190cc` |
| Scanned | `lib/`, `exe/`, `.reports/`, `PORTING.md`, `COMPONENT_PARITY.md`, `TEST_PARITY.md`, `TRANSLATION_PARITY.md`, `FINDINGS.md`, `.gitlab-ci.yml`, `Rakefile`, `flake.nix`, `io.gitlab.adhami3310.Converter.json` |
| `TODO`/`FIXME`/`not implemented`/`for now`/`in a future`/`XXX`/`HACK` in `lib/` and `exe/` | **0**, re-confirmed by a fresh grep this round |
| `find-excuses.sh` hits outside documents *about* excuses | **0**, re-confirmed by running the scan this round |
| Previous round's issues | **both resolved and re-verified again this round** |
| New issue found this round | **1** — a report-accuracy failure in the audit documents, not in the port |

Verdict: **not clean** — a genuine, correctly-labelled, correctly-excused-
nowhere runtime gap count of 3 (restated above and in `component-parity.md`),
plus a documentation-accuracy defect carried forward from last round
(below). The last two audits (`9f4999c`, `50bffc4`) found two false greens
in the *port's own claims*; `d1ca7f4` genuinely closed both, re-verified
from scratch again this round rather than trusted a second time from a
commit message. The open issue this round is entirely in the **audit
trail's own documents**, not in the application.

## The excuse scan, re-run

```
$ .claude/skills/accountability-ensurance/scripts/find-excuses.sh lib exe
(no output — nothing matched)
$ grep -rniE 'TODO|FIXME|not implemented|for now|in a future|XXX|HACK' lib exe
(no output)
$ .claude/skills/accountability-ensurance/scripts/find-excuses.sh .reports PORTING.md
component-parity.md:65:n/a:...
component-parity.md:68:skipped:...
accountability-ensurance.md:26:by design:...
accountability-ensurance.md:27:not ported:...
accountability-ensurance.md:28:skipped:...
accountability-ensurance.md:32:not ported:...
accountability-ensurance.md:32:skipped:...
```

All seven hits are inside the ledgers themselves, quoting the skill's own
vocabulary table or a prior worked example — the skill explicitly exempts
documents *about* excuses, and these are that. `PORTING.md` itself: zero
hits. `lib/`/`exe/` register is clean.

## Previous false green #1 — `rake spec` ran nothing, claimed to run

Re-verified fixed, not assumed from the commit message:

```
$ nix develop --command xvfb-run -a rake spec
75 examples, 0 failures
```

`Rakefile:77` defines a real `task :spec`; `TEST_PARITY.md` now says so
accurately ("a real Rake task now; see below") and documents the false
claim it replaces, in the same first-person-adjacent register this skill
asks for, rather than deleting the history of the mistake.

## Previous false green #2 — the CSS-node-name binding claim

Re-verified fixed, not assumed from the commit message:

```ruby
class ProbeCssNamed < Adwaita::Bin
  type_register
  set_css_name('dragoverlay')
end
ProbeCssNamed.new.css_name  # => "dragoverlay", re-run this session
```

`FINDINGS.md` §8 is rewritten to state the working route and to name, in
its own heading, that "this file previously said otherwise." `lib/
drag_overlay.rb` calls `set_css_name('dragoverlay')` and `lib/style.rb`
matches the real node. Both sides of the false claim — the code and the
document that excused not fixing it — are corrected.

Both of these were genuinely hard to fake: they are falsifiable by running
a command, and this audit ran the commands rather than reading the diff
and trusting it.

## New finding — the audit trail itself produced at least one false claim, and the resume document is now badly stale

This is the headline finding this round, and it is about the auditing
process, not about the port.

**`.reports/component-parity.md` at `50bffc4` reported a gap that was not
true at the commit it was reported against.** Its gap #8 claimed
`lib/settings.rb:93-98` "skips the two size keys" on a maximized window.
Reading that exact file at that exact commit:

```
$ git show 50bffc4:lib/settings.rb | sed -n '88,97p'
  def remember(window)
    self['window-width'] = window.default_width
    self['window-height'] = window.default_height
    self['is-maximized'] = window.maximized?
  end
```

All three keys, unconditional, matching upstream — and this had been true
since `98e9ae8`, four commits *before* either the `9f4999c` or `50bffc4`
audit ran. The same misreading reproduced itself for `FileType#output?`
rejecting `jpeg`, the fd-limit raise, the per-binary spawn error message,
and the two About-dialog icons: all five were already fixed by `98e9ae8`,
and all five were still listed as open gaps in `PORTING.md`'s "Open gaps"
section and in the prior `.reports/component-parity.md`, at the time this
audit started.

I am naming this plainly rather than softening it: **an audit that reports
a gap without re-reading the file at the commit it cites is making the
same mistake this skill exists to catch, in the opposite direction.** A
false green hides work still owed. A false, uncorrected *red* — a gap
claimed against code that already closed it — is cheaper to carry but has
the same mechanism: the next reader trusts the ledger instead of the file,
and inherits a wrong fact. `PORTING.md`'s header currently reads "not
clean — 23 gap(s)" against an audit two rounds old; the actual count,
re-verified this round and matching the already-current `COMPONENT_PARITY.md`
at the repo root, is **3**. Anyone opening `PORTING.md` as the stated
"resume point" right now would believe five to eight times more work
remains than does.

**This is not a new excuse pattern — there is no sentence anywhere
presenting a skip as a decision.** It is a different failure this skill's
literal scope (phrase-hunting) does not catch on its own: a status document
going stale while the gaps underneath it close, and nobody re-running the
numbers before trusting the header. Recorded here because the skill's own
mandate — "is any gap being excused rather than built" — has an inverse
that matters just as much to a campaign run by many agents in sequence: is
work that *was* built being hidden behind a stale ledger that says it
wasn't. `PORTING.md`'s header and "Open gaps" list should be regenerated
from `COMPONENT_PARITY.md`, `TEST_PARITY.md` and `TRANSLATION_PARITY.md`
(all three of which are current) rather than left at `8b7d245`/`341104d`.
This was not done as part of this audit, because rewriting another ledger
is outside what was asked for here; it is named so the next agent does not
have to re-derive it.

## What remains genuinely open (not an excuse — see `component-parity.md`)

Two binding limitations (`Gtk::Accessible#update_property`,
`Gtk::Widget` vfunc dispatch) and the Flatpak manifest are recorded as open
gaps in `component-parity.md`, each cited to `FINDINGS.md` for why they are
hard, with no sentence anywhere attributing them to scope, design or
necessity. That is the correct pattern this skill asks for, and it holds
on both sides of this audit: the binding limitation is why the gap is
expensive, never why it is closed.

## New finding this round — root `COMPONENT_PARITY.md` is stale against the Flatpak manifest, and self-contradicts on the GResource item

Since the last `.reports/` round (`01c68e8`), exactly one commit landed:
`fb196ba`, which writes `io.gitlab.adhami3310.Converter.json` (a Flatpak
manifest) and edits `PORTING.md` to describe it honestly as **written,
unverified** — no `flatpak-builder` or GNOME runtime is available in this
environment, so the manifest has never been run even once. `PORTING.md`
itself does this correctly: its new row says "Unverified" in bold and
spells out exactly which three things (gem native extensions, GI typelib
lookups in the sandbox, desktop/metainfo substitution) were never exercised.

Root `COMPONENT_PARITY.md`, by contrast, **was not touched by `fb196ba`** and
still reads, at line 173, unchanged since `d1ca7f4`:

> "...Not started rather than stubbed."

That was true before `fb196ba` and is not true after it — a manifest now
exists, is a real, careful translation of upstream's SDK-extension shape
into a from-source Ruby build, and is cited by file and line in `PORTING.md`
and in this round's `component-parity.md`. This is the **inverse** of a
false green (same category this report's previous round named for
`PORTING.md`'s gap count): a status document describing less progress than
has actually happened, left stale because the commit that did the work
edited one ledger (`PORTING.md`) and not the other (`COMPONENT_PARITY.md`).
Recorded here rather than silently fixed, because rewriting
`COMPONENT_PARITY.md` is outside this report's job — but the next agent
should not re-derive this: **`COMPONENT_PARITY.md` line 173 needs updating
to reflect that the manifest exists and is unverified, not absent.**

Separately, and independent of the above: `COMPONENT_PARITY.md` classifies
the same fact — the port has no GResource bundle, assets are read from
`data/` directly — three different ways in one document. Lines 45 and 110
call it **correspondence** (a different mechanism, not a gap, because
nothing user-visible differs). Line 173 lists it a third time, now inside
the **"Remaining gaps"** table, with no sentence reconciling the
contradiction. `component-parity.md` (this round) does not carry the
GResource item forward as gap #4 — read against `lib/style.rb`,
`lib/main.rb` and `lib/about_dialog.rb`, the absence is a packaging-mechanism
difference with no observable behavioural gap, consistent with the
*correspondence* classification, not the *gap* one. The document holding
two answers to the same question, unreconciled, is itself the finding:
whichever answer is right, `COMPONENT_PARITY.md` currently asserts both.

Neither of these is a false green **in the port** — the port's own behavior
is unaffected by either, and no sentence in `lib/`, `exe/` or `PORTING.md`
excuses a skip as a decision. Both are false claims **in a status document
about the port**, which is the category this skill treats as "the most
serious finding," because the next reader — human or agent — trusts the
ledger over the file.

## Rules followed

- Both previously-named false greens were re-run from scratch this round,
  not accepted from the fix commit's own message.
- The new finding names file, line and commit on both sides (the wrong
  claim, and the code that already contradicted it) rather than asserting
  generally that "the ledger is out of date."
- No reasoning slot anywhere in this document accepts a constraint as a
  closure; the two still-open binding limitations stay open and are cited
  to `FINDINGS.md`, never excused here.
- This round's new finding (stale/self-contradicting `COMPONENT_PARITY.md`)
  is named with file and line on both sides rather than asserted generally,
  and the fix is described but not performed here, consistent with this
  report auditing rather than editing other ledgers.
