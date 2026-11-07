# Test parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` (unchanged) |
| Port | `ruby` @ `c5f0dbd08393214d7614d776155388a4624aaad2` |
| Upstream tests | **0** |
| Ported | 0 |
| Gaps | 0 (met trivially — see below) |
| Suite actually executed this round | **yes** — RSpec and the headless drive script, both run fresh in this session, from scratch |

## Upstream has no test suite

Re-confirmed this round against upstream unchanged (`ae72daf`, same sha as
every prior audit):

```
$ git ls-tree -r --name-only origin/main | grep -iE 'test|spec'
(no output: no tests/ directory, no filename containing test or spec)
$ git grep -n '#\[test\]\|#\[cfg(test)\]\|mod tests' origin/main -- '*.rs'
(no output)
```

Test parity is **0/0** and met trivially. A 0/0 ledger says only that
upstream owed the port nothing; it is not itself evidence the port works.

## Both gates, re-run fresh this session (not copied from a prior report)

```
$ nix develop --command xvfb-run -a ruby test/drive_main_window.rb
...
[81] every component the port ships was opened in this run
    ok   the 26 components driven are the 26 the port ships
    components covered: 26

328 of 328 checks passed
DRIVE OK
```

```
$ nix develop --command xvfb-run -a ruby -e 'require "rspec/core"; exit RSpec::Core::Runner.run(["--format", "progress", "--require", "spec_helper", "spec"])'
Randomized with seed 22051
....................................
.......................................
Finished in 2.96 seconds (files took 4.31 seconds to load)
75 examples, 0 failures
```

328/328 checks, 26/26 components, DRIVE OK; 75 examples, 0 failures. Matches
the task's stated runtime gate exactly, and matches the last three audit
rounds' numbers. Both commands were actually executed in this session against
a live `xvfb` display, not inferred from file contents.

## What the suite proves, and what it does not

- `spec/*.rb` (75 examples): model-level and unit coverage — `Color`,
  `FileType`, `Settings`, `ConvertPage` helpers, `ImageThumbnail`'s
  horizontal-measure clamp.
- `test/drive_main_window.rb` (328 checks across 81 numbered steps): a live,
  headless run of the real GTK app under `gtk4-broadwayd` — every page, every
  dialog (about, shortcuts, error, stop-converting), drag-and-drop, clipboard
  paste, the full convert → converting → all-images flow, a second window,
  and accessibility fragments.
- **None of it is upstream's test suite**, because upstream does not have
  one. Both are extra, by this skill's own accounting, not parity with
  anything upstream pinned down.

## `rake spec`, re-run directly as well

Both the dev shell's documented RSpec-runner invocation and `rake spec`
itself were run fresh this round:

```
$ nix develop --command xvfb-run -a rake spec
75 examples, 0 failures
```

Identical result. `Rakefile:77`'s `task :spec` still wires up correctly; the
false-green state fixed in `d1ca7f4` (`spec/` being a directory made the bare
task name look up to date, so `rake spec` ran nothing and exited 0) has not
regressed.

## Extra (re-run this round)

- `spec/color_spec.rb`, `spec/file_type_spec.rb`, `spec/settings_spec.rb`,
  `spec/convert_page_spec.rb`, `spec/image_thumbnail_spec.rb`,
  `spec/app_window_spec.rb`, `spec/switcheroo/rb_spec.rb` — 75 examples
  total, 0 failures.
- `test/drive_main_window.rb` — 328 checks across 81 steps, DRIVE OK.

## Root `TEST_PARITY.md` is stale and internally inconsistent — see `accountability-ensurance.md`

Root `TEST_PARITY.md`'s own header (line 10) reads "75 examples, plus a
16-check UI drive," and its own body (line 86) reads "70 examples, 0
failures" — neither figure matches the other, and neither matches the
328-check/75-example reality re-verified live in this round and in the three
rounds before it. This is a documentation-accuracy defect in a root-level,
prominently-named file, not a test-suite defect; it is reported in full under
`accountability-ensurance.md` rather than duplicated here.
