# Test parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` |
| Port | `ruby` @ `5ec22388b7dd5ea9ec0c27dbebeac2a8bd86ab46` |
| Upstream tests | **0** |
| Ported | 0 |
| Gaps | 0 (met trivially — see below) |
| Suite actually executed this round | **yes** — both the RSpec suite and the headless drive script, by this audit, in this session |

## Upstream has no test suite

Re-confirmed this round against upstream unchanged (`ae72daf`, same sha as
the last audit):

```
$ git -C <upstream worktree> ls-tree -r --name-only ae72daf | grep -iE 'test|spec'
(no output from any Rust test module, no tests/ directory, no #[test],
 no #[cfg(test)])
```

Switcheroo upstream is a thin gtk-rs/libadwaita app with no Rust unit tests
and no `tests/` directory. Test parity is **0/0** and is met trivially — the
port inherits no safety net from upstream, and everything the port's own
suite checks was chosen by the port's authors, not pinned down by the
original project.

## What the port's own suite actually proves — re-executed this round

Both commands below were run fresh in this session, not reported from a
previous pass, under `nix develop --command xvfb-run -a ruby ...`:

```
$ ruby -e 'require "rspec/core"; exit RSpec::Core::Runner.run(
    ["--format", "progress", "--require", "spec_helper", "spec"])'
...........................................................................
75 examples, 0 failures
```

```
$ ruby test/drive_main_window.rb
328 of 328 checks passed
DRIVE OK
    components covered: 26
```

**Up from the last audit's 70 RSpec examples** — `spec/image_thumbnail_spec.rb`
is new (5 examples, added in `5ec2238`), and it is real test coverage of a
real gap: it pins the exact circumstances under which `image_thumbnail.rb`'s
width-floor correspondence (component-parity gap #3) would start to matter,
by measuring the real widget for every caption shape `InputFile#caption` can
produce. This is extra, upstream-less coverage and belongs under `## Extra`
below, not counted toward the 0/0 bijection.

## The suite can still only be run one way, and it is not the documented one

`TEST_PARITY.md:11` still reads:

```
| Test command | `rake spec` — and it runs now |
```

This is false, re-confirmed this round, not carried over by assumption:

```
$ nix develop --command rake -T | grep -i spec
(no "spec" task listed — only the devshell's echoed banner line mentions it)
$ nix develop --command rake spec
(exits 0, prints nothing: "spec" is a directory, Rake treats the bare name
 as a satisfied file task and runs no action)
```

So `rake spec` is a **false green by construction**: it reports success
(exit 0) while running zero of the suite's 75 examples, and the ledger that
exists specifically to say what was executed asserts that this is the command
that runs it. This was first found in the previous audit (`9f4999c`, finding
F1) and has not been fixed since — the Rakefile changes in this round's diff
(`5ec2238`) added `app:pot`/`app:update_po` but no `spec`/`test` task. Carried
into `accountability-ensurance.md` as an unresolved false green, because it is
one.

The suite only actually runs through the incantation `flake.nix:222` prints in
the dev-shell banner (the command reproduced above), or through
`test/drive_main_window.rb` directly. Neither is wired to `rake`, `make` or any
CI job — `.gitlab-ci.yml` still calls `bin/rspec` and `bin/rake`
(`.gitlab-ci.yml:55,59,85,89`), and `bin/` contains only `setup` and
`turbo_tests2`:

```
$ ls bin/
setup  turbo_tests2
$ test -f bin/rake || echo "bin/rake MISSING"
bin/rake MISSING
$ test -f bin/rspec || echo "bin/rspec MISSING"
bin/rspec MISSING
```

So the CI pipeline as checked in would fail at the first `bundle exec
appraisal unlocked_deps bin/rake --tasks` line, and **the drive script is not
invoked by any CI job at all** — the 328-check gate that is this audit's
runtime evidence runs only when a human or an audit, like this one, runs it by
hand. That is this round's own instruction treating a failed-or-narrow drive
run as a gap in its own right, applied to the CI wiring rather than the drive
script itself: the drive script passed, but nothing makes it keep passing.

## Closing coverage self-check — re-read, narrowed finding

`test/drive_main_window.rb:1561-1571`'s "every component the port ships was
opened in this run" check compares `COMPONENTS` against
`Dir.children(lib/).select { .rb }`, which is **non-recursive**. `lib/`
has one subdirectory, `lib/switcheroo/` (the gem-launcher scaffolding:
`application.rb`, `rb.rb`, `rb/version.rb`), which this check cannot see.
Those three files are not UI components and do not belong in `COMPONENTS`,
so the check's **result** is correct today (26 == 26, verified by this run)
— but the check would stay green even if a real widget file were ever added
under a subdirectory, because `Dir.children` would never list it. Recorded
as a latent weakness in the self-check, not as a current miscount.

## Extra (not parity work, not counted toward 0/0)

- `test/drive_main_window.rb` — 328 checks across 81 steps, 26 components,
  17 screenshots. Drives drag-and-drop, clipboard paste, the full
  ImageMagick conversion pipeline, the error dialog, the stop-converting
  dialog, the all-images page, the `+N` rest tile, a second window, and
  window-close races — this round confirmed none of that is "not driven,
  therefore unconfirmed" any more, which is what an older line in
  `PORTING.md` still claims (see `accountability-ensurance.md`).
- `spec/` — 75 RSpec examples across the model/backend layer
  (`magick`, `file_type`, `input_file`, `color`, `settings`, `temp_dir`,
  `image_thumbnail`). All green, re-run this round.

Both are real, substantial coverage the port's own authors chose to write.
Neither is upstream's test suite, because upstream does not have one.
