# Accountability ensurance — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` (unchanged) |
| Port | `ruby` @ `c5f0dbd08393214d7614d776155388a4624aaad2` |
| Scanned | `lib/`, `exe/`, `.reports/`, `PORTING.md`, `COMPONENT_PARITY.md`, `TEST_PARITY.md`, `TRANSLATION_PARITY.md`, `FINDINGS.md` |
| `TODO`/`FIXME`/`not implemented`/`for now`/`in a future`/`XXX`/`HACK` in `lib/` and `exe/` | **0**, re-confirmed by a fresh grep this round |
| `find-excuses.sh` hits outside documents *about* excuses | **0**, re-confirmed this round |
| Previous round's two false greens (`rake spec`, CSS-node-name) | **still fixed, re-verified again this round** |
| Previous round's new finding (`COMPONENT_PARITY.md` stale re: Flatpak/GResource) | **fixed this round, verified** (see below) |
| New issue found this round | **1** — a report-accuracy failure in root-level status documents, worse than the one it replaces |

Verdict: **not clean** — a genuine, correctly-labelled, correctly-excused-
nowhere runtime gap count of 3 (restated in `component-parity.md`), plus a
documentation-accuracy defect in the root-level status files. The open
issue this round is entirely in the **status documents**, not in the
application: `lib/` and `exe/` register zero excuse-pattern hits, and the
328/0/26 drive gate plus 75/0 spec gate were both re-run live this session
and passed.

## The excuse scan, re-run

```
$ .claude/skills/accountability-ensurance/scripts/find-excuses.sh lib --quiet
(no output)
$ .claude/skills/accountability-ensurance/scripts/find-excuses.sh exe --quiet
(no output)
$ grep -rniE 'TODO|FIXME|not implemented|for now|in a future' lib exe
(no output)
$ .claude/skills/accountability-ensurance/scripts/find-excuses.sh PORTING.md --quiet
(no output)
$ .claude/skills/accountability-ensurance/scripts/find-excuses.sh COMPONENT_PARITY.md --quiet
(no output)
$ .claude/skills/accountability-ensurance/scripts/find-excuses.sh TEST_PARITY.md --quiet
(no output)
$ .claude/skills/accountability-ensurance/scripts/find-excuses.sh TRANSLATION_PARITY.md --quiet
(no output)
$ .claude/skills/accountability-ensurance/scripts/find-excuses.sh FINDINGS.md --quiet
(no output)
```

`lib/`/`exe/` and every named root document are clean of excuse phrasing.
The only hits anywhere in the tree (`.reports/` itself, from the *previous*
version of this very file, now replaced) quote the skill's own vocabulary
table while explaining a prior round's finding — exempt by the skill's own
rule for documents about excuses, same as the last three rounds.

## Previous false green #1 — `rake spec` ran nothing, claimed to run — re-verified fixed, live this round

```
$ nix develop --command xvfb-run -a rake spec
75 examples, 0 failures
```

`Rakefile:77`'s real `task :spec` still runs the suite; the false-green
state fixed in `d1ca7f4` (`spec/` being a directory made Rake treat the bare
task name as up to date, so `rake spec` exited 0 having run nothing) has not
regressed.

## Previous false green #2 — the CSS-node-name binding claim — re-verified fixed

```ruby
class ProbeCssNamed < Adwaita::Bin
  type_register
  set_css_name('dragoverlay')
end
ProbeCssNamed.new.css_name  # => "dragoverlay"
```

`lib/drag_overlay.rb:29-30` still calls `set_css_name('dragoverlay')` inside
`type_register`, and `lib/style.rb:34` still matches the real node, not a
class. `FINDINGS.md` §8 still states the working route rather than the
disproven claim it replaced.

## Previous round's finding — fixed this round, verified rather than trusted

Last round's headline finding was that root `COMPONENT_PARITY.md` was stale
against the Flatpak manifest (`fb196ba`) and self-contradicted on the
GResource item (same fact called both "correspondence" and "gap"). The one
commit since then, `c5f0dbd`, addresses exactly this:

```
$ git show c5f0dbd
 COMPONENT_PARITY.md | 5 +++--
```

Line 173 now reads "Written-but-unverified, not 'not started'," matching
`PORTING.md` and `component-parity.md`; the duplicate GResource "gap" row is
removed, replaced by a note pointing at the two rows that already call it
correspondence. Re-read directly, not trusted from the commit message: both
fixes are real and accurate. **This is the first round in this audit trail
where a previously-named documentation-staleness finding was actually
closed by a commit, rather than carried forward again** — worth recording
as a positive data point, not only a negative one.

## New finding this round — the fix above was narrow; two other root documents are stale in the same way, one of them self-contradicting internally

`c5f0dbd` fixed exactly the two things the previous round named in
`COMPONENT_PARITY.md`, and nothing else. Reading these root documents fresh
rather than trusting their having been "the current ledger" from a prior
round's framing:

**`COMPONENT_PARITY.md`'s own header (line 7), untouched by `c5f0dbd`:**

```
| Units | 17 |
```

The actual, independently re-counted unit total is **26**
(`ls lib/*.rb | wc -l`), matching `component-identification.md`,
`test/drive_main_window.rb`'s `COMPONENTS` constant, and `PORTING.md`'s own
file-mapping table. `17` is left over from an earlier stage of the port and
was not updated when the unit count grew to 26. The body of the same
document (line 12) also still says "`spec/` runs 70 examples," which was
true at some earlier round and is not true now (75, re-verified live this
session and the last three rounds).

**`TEST_PARITY.md` disagrees with itself, not just with reality:**

```
line 10: | Port tests of its own | **75 examples**, plus a 16-check UI drive |
line 86: 70 examples, 0 failures.
```

The header says 75 examples (right) and a "16-check UI drive" (wrong — the
drive script is 328 checks across 81 steps, re-verified live this session
and matching the task's own stated gate). The body, four lines from the
header it sits under, says 70 examples (wrong — contradicting its own
header's "75"). A reader of this one document, without cross-referencing
anything else, cannot tell which number the document itself believes.

**Why this is worse than the finding it follows, not merely a repeat of it:**
the previous round's finding (Flatpak/GResource) was one document, one
fact, cleanly fixable, and got fixed within one commit. This round's finding
is two separate numbers in two separate root-level files, one of which
disagrees with *itself* across two lines four lines apart. Root
`COMPONENT_PARITY.md` and `TEST_PARITY.md` are the prominently-named,
canonical-sounding files a new reader — human or agent — would open first,
ahead of `.reports/`; both currently describe a smaller, differently-shaped
port than the one in the tree. This is exactly the inverse-false-green
pattern this skill's mandate covers ("is work that was built being hidden
behind a stale ledger"), recurring a third round in a row in the same two
files, after only a partial fix.

**Not an excuse pattern in the `find-excuses.sh` sense** — no sentence
anywhere presents the stale numbers as a decision; they are simply wrong and
uncorrected, which this skill's literal phrase-hunting does not catch on its
own (as the last two rounds also noted about `PORTING.md`'s header). Also
true of `PORTING.md`'s own header: it still reads "Last audit: `.reports/`
@ `c409c40`," two rounds (`01c68e8`, and this one) behind the actual last
`.reports/` commit. The pattern is now three root documents
(`PORTING.md`, `COMPONENT_PARITY.md`, `TEST_PARITY.md`) with stale headers,
one of them (`COMPONENT_PARITY.md`) partially fixed this round and two
(`TEST_PARITY.md`, `PORTING.md`'s header) not touched at all.

Recorded here rather than fixed in this report, consistent with this
document's own job across every prior round (audit, not edit other
ledgers) — but naming precisely what the next agent should fix:
`COMPONENT_PARITY.md` line 7 (`Units | 17` → `26`) and line 12 (`70
examples` → `75`); `TEST_PARITY.md` line 10 (`16-check UI drive` → `328-check,
81-step drive`) and line 86 (`70 examples` → `75`); `PORTING.md`'s header
row ("Last audit") regenerated against the actual latest `.reports/` commit
rather than `c409c40`.

## What remains genuinely open (not an excuse — see `component-parity.md`)

Two binding limitations (`Gtk::Accessible#update_property`, `Gtk::Widget`
vfunc dispatch) and the unverified Flatpak manifest are recorded as open
gaps in `component-parity.md`, each cited to `FINDINGS.md` for why they are
hard, with no sentence anywhere attributing them to scope, design or
necessity.

## Rules followed

- Both previously-named false greens (`rake spec`, CSS-node-name) were
  re-run from scratch this round, not accepted from a prior report.
- The previous round's own finding was checked against the commit that
  claimed to fix it (`git show c5f0dbd`), not accepted from the commit
  message.
- This round's new finding names exact file and line on both sides (the
  wrong number, and the right one, independently re-derived) for every
  claim, rather than asserting generally that "the ledger is stale."
- No reasoning slot anywhere in this document accepts a constraint as a
  closure; the two still-open binding limitations stay open, cited to
  `FINDINGS.md`, never excused here.
