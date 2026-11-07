# Test parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` (unchanged) |
| Port | `ruby` @ `fb196babe2113d47395c5efc48bf491b447190cc` |
| Upstream tests | **0** |
| Ported | 0 |
| Gaps | 0 (met trivially — see below) |
| Suite actually executed this round | **yes** — RSpec, the headless drive script, and `rake spec` itself, all run fresh in this session |

## Upstream has no test suite

Re-confirmed this round against upstream unchanged (`ae72daf`, same sha as
the last two audits):

```
$ git ls-tree -r --name-only origin/main | grep -iE 'test|spec'
(no output: no tests/ directory, no filename containing test or spec)
$ git grep -n '#\[test\]\|#\[cfg(test)\]\|mod tests' origin/main -- '*.rs'
(no output)
```

Switcheroo upstream is a thin gtk-rs/libadwaita app with no Rust unit tests.
Test parity is **0/0** and met trivially — the port inherits no safety net
from upstream; everything the port's own suite checks was chosen by the
port's authors, not pinned down by the original project.

## `rake spec` — re-verified genuinely fixed, not just claimed fixed

The previous audit (`9f4999c`, carried into `50bffc4`'s own ledger text)
found `rake spec` was a false green: `spec/` being a directory made Rake
treat the bare task name as an up-to-date file target, so `rake spec`
exited 0 having run nothing, while `TEST_PARITY.md` claimed it "runs now."
That was fixed in `d1ca7f4`. Re-run from scratch this round, not trusted
from the commit message:

```
$ nix develop --command xvfb-run -a rake spec
Randomized with seed ...
.........................  (x75)
Finished in 3.8 seconds (files took 4.69 seconds to load)
75 examples, 0 failures
```

Genuinely executes 75 examples, 0 failures. `Rakefile:77` now defines a
real `task :spec` running `RSpec::Core::Runner.run`, and `task test: :spec`
aliases it. The `.reports/test-parity.md` left by the *previous* audit
still described the false-green state as current fact (see
`accountability-ensurance.md`); this document replaces that description.

## The headless drive script, re-run independently

```
$ nix develop --command xvfb-run -a ruby test/drive_main_window.rb
...
[81] every component the port ships was opened in this run
    ok   the 26 components driven are the 26 the port ships
    components covered: 26

328 of 328 checks passed
DRIVE OK
```

328/328, 26/26 components, re-run fresh this session rather than taken from
either the previous audit's report or the task's stated runtime gate. The
two numbers agree, which is itself worth stating: the gate this round was
not re-derived from a cached result.

## What the port's own suite proves, and what it does not

- `spec/*.rb` (75 examples): model-level and unit coverage —
  `Color`, `FileType`, `Settings`, `ConvertPage` helpers, `ImageThumbnail`'s
  horizontal-measure clamp (the one spec added since the last round,
  pinning the gap recorded in `component-parity.md` #1 so it does not
  silently regress further).
- `test/drive_main_window.rb` (328 checks across 81 numbered steps): a
  live, headless run of the actual GTK app — every page, every dialog
  (about, shortcuts, error, stop-converting), drag-and-drop, clipboard
  paste, the full convert → converting → all-images flow, a second window,
  and accessibility fragments. This is substantial behavioural coverage
  that a unit-test suite alone would not give.
- **None of it is upstream's test suite**, because upstream does not have
  one. It is all extra, by this skill's own accounting, and it is listed
  here as extra rather than as parity:

## Extra

- `spec/color_spec.rb`, `spec/file_type_spec.rb`, `spec/settings_spec.rb`,
  `spec/convert_page_spec.rb`, `spec/image_thumbnail_spec.rb`,
  `spec/app_window_spec.rb`, `spec/switcheroo/rb_spec.rb` — 75 examples
  total, 0 failures, re-run this round.
- `test/drive_main_window.rb` — 328 checks across 81 steps driving every
  shipped page, dialog and the two-window case, re-run this round, DRIVE OK.

Upstream has no safety net to inherit, so every one of these checks pins
only what this port's own authors decided was worth pinning — which is
sizeable, genuinely green, and genuinely run, but is not test *parity* in
the sense this skill measures, because there is no upstream test to be at
parity with.

## One correction to the previous audit's own coverage claim

`component-parity.md`'s `50bffc4` pass carried forward a claim, inherited
from `9f4999c`, that the chain-link open/closed icon branch in
`lib/convert_page.rb`'s link-axis handling was "a branch no check
exercises." Re-grepped this round:

```
$ grep -n "chain link\|link_axis" test/drive_main_window.rb
871:  d.step("the chain link keeps the two axes in proportion") do
873:    d.check("the link is offered, since the images share a size") { ... }
874:    d.check("it starts linked") { page.link_axis.active? }
875:    d.check("and shows the closed-chain icon") { page.link_axis.icon_name == ConvertPage::LINKED_ICON }
885:    d.check("unlinking shows the loose-chain icon") { page.link_axis.icon_name == ConvertPage::LOOSE_ICON }
```

It is driven, both icon states, and has been since at least `d15487b`
(unchanged in the diff since). The "untested branch" claim carried in two
prior audits was false — recorded here because a wrong "this is untested"
claim is the same category of inaccuracy as a wrong "this passes" claim:
both misdescribe what the suite actually covers, and both would have sent
the next agent to re-test something already pinned.

## This round: re-run fresh again, nothing new in the suite

The only change on the port side since the last parity-report commit
(`01c68e8`) is `fb196ba`, which adds a Flatpak manifest and edits
`PORTING.md`. Neither touches `spec/`, `lib/`, `exe/` or `test/`, so there is
no new code for a test to cover and no reason to expect the numbers to move.
Re-run from scratch rather than assumed unchanged:

```
$ nix develop --command xvfb-run -a rake spec
75 examples, 0 failures
$ nix develop --command xvfb-run -a ruby test/drive_main_window.rb
328 of 328 checks passed
DRIVE OK
```

Same 75/0 and 328/0/26 as the task's stated runtime gate and as the last
three audit rounds. Nothing in this round's one commit (`fb196ba`) is
exercised by any check — it is a Flatpak manifest, and no `flatpak-builder`
is available here to run it even once (see `component-parity.md` gap #3
and `accountability-ensurance.md`). That absence of coverage is recorded
there as an open gap, not hidden by this suite's unrelated green.
