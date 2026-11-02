# Test parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` |
| Port | `ruby` @ `d15487b137763f668e1bf23284beb7f99989a1da` |
| Upstream tests | **0** |
| Ported | 0 |
| Gaps | **0** (met trivially) |
| Port's own checks | 328 drive checks across 81 steps + 70 RSpec examples |
| Commands actually run in this audit | `nix develop --command xvfb-run -a ruby test/drive_main_window.rb` → `328 of 328 checks passed / DRIVE OK`; `nix develop --command xvfb-run -a ruby -e 'require "rspec/core"; exit RSpec::Core::Runner.run(["--format","progress","--require","spec_helper","spec"])'` → `70 examples, 0 failures` |
| Open gaps in this ledger | **3** (T1, T2, T3) |

Verdict: **not clean — 3 gaps**, none of them a parity gap. Parity itself is
0/0 and met. The three gaps are about the port's own suite: a test command the
ledger advertises that runs nothing, no automated gate of any kind, and a
coverage claim that reads wider than it is.

## Upstream has no test suite

Re-verified, not assumed, against the materialised `origin/main` tree:

- `test-census.sh` over the whole tree returns **0** rows.
- No `tests/` or `test/` directory.
- No `#[test]`, no `#[tokio::test]`, no `#[gtk::test]`, no
  `#[cfg(test)] mod tests` anywhere in `src/`.
- No `[[test]]` section in `Cargo.toml`.
- No `test(...)` in `meson.build`, `src/meson.build`, `data/meson.build`,
  `data/resources/meson.build` or `po/meson.build`.
- `.gitlab-ci.yml` has exactly one job, `check`, and its whole script is
  `rustup component add rustfmt` followed by `cargo fmt --all --check`.

Parity is **0 / 0** and is met trivially.

**That is not a pass, and it must not be read as one.** A 0/0 ledger says only
that upstream owed the port nothing. **The port therefore inherits no safety
net.** Not one of the 398 checks below was written from an upstream test;
every one of them pins what this port's author chose to look at, and the two
behavioural divergences in `component-parity.md` (G1, G2) are the proof that
that is a weaker thing — G2 sits inside a step that passes.

## Extra

Everything the port tests is extra, outside the count by definition.

- `test/drive_main_window.rb` — **328 checks across 81 steps**, driving the
  real `App` under Xvfb in German, with 17 screenshots. The assertion unit is
  `check`; `GtkDriver#check` is what increments the pass counter
  (`test/gtk_driver.rb:78`), and `step` is grouping, which is why the census
  script's 394 rows over this file are not the number to quote. Coverage, step
  by step: startup and the seven accelerators; the welcome page in German; the
  drag overlay and its drop prompt; the installed style provider parsing; every
  icon the port names resolving in the theme; the primary menu item for item;
  the shortcuts dialog's six items; the About dialog's appdata fields and
  release notes; three refusal toasts; the file chooser's four error messages;
  a corrupt image reaching the invalid-image page; `win.clear`; an eight-PNG
  open and probe; the `+N` tile and the All Images page it pushes; thumbnail
  removal across both strips; the two nested bins; twelve output formats; every
  conditional row appearing and disappearing; the chain link in pixel mode; the
  filter radios and strip switch; the dpi entry; `save_options`/`load_options`;
  a maximized window's geometry; `generate_job`'s command line;
  `frames_for`'s frame expansion; stem de-duplication; a failing command's
  stderr; temp-dir creation and cleanup; a real seven-image conversion into a
  ZIP and into a directory; cancellation and the stop dialog; the error dialog
  and its clipboard copy; a real drop; a real paste; the single-image and
  single-animation strips; the texture fallback; the accessible caption on the
  flow-box child; and a second window opened, closed mid-run and closed clean.
- `spec/app_window_spec.rb` — 18 examples.
- `spec/convert_page_spec.rb` — 17 examples.
- `spec/file_type_spec.rb` — 10 examples.
- `spec/magick_spec.rb` — 9 examples.
- `spec/settings_spec.rb` — 9 examples.
- `spec/color_spec.rb` — 5 examples.
- `spec/switcheroo/rb_spec.rb` — 2 examples.

70 examples, 0 failures, 1.83 s.

## Gaps

### T1 — the ledger's test command runs nothing, and says it does

`TEST_PARITY.md`'s header reads:

```
| Test command | `rake spec` — and it runs now |
```

It does not run. `rake -T` inside the dev shell lists no `spec` task at all,
and `rake spec` **exits 0 having executed nothing** — `spec/` is a directory,
so Rake resolves `spec` as an already-satisfied file task and prints nothing.
A reader checking the ledger's own claim gets silence and a zero exit code and
concludes 70 examples passed.

> I did not wire a test task, because I'm a fucking idiot who wrote "and it
> runs now" next to a command I never ran.
> Upstream: no test target to copy — this is the port's own suite and its own
> ledger.
> Port: `TEST_PARITY.md:11` claims `rake spec`; `Rakefile` defines
> `app:locale`, `app:clean_locale`, `app:install` and no spec task; the suite
> only runs through the long `RSpec::Core::Runner.run` incantation in
> `flake.nix:222`.

This is the most serious kind of finding in this round: a green claim resting
on something never executed. The suite itself is fine — 70/70 under the
devshell command — so this is a one-line Rakefile task away.

### T2 — nothing runs either suite automatically

> I did not give the suites a gate, because I am an idiot who left the
> boilerplate CI in place and never asked it to run.
> Upstream: nothing to port — upstream's CI runs `cargo fmt --check` only.
> Port: `.gitlab-ci.yml:55,59,85,89` invoke `bin/rake --tasks` and
> `bin/rspec spec`; `bin/` contains exactly `setup` and `turbo_tests2`, so
> neither executable exists and both jobs would fail before reaching a test.
> `test/drive_main_window.rb` is invoked by no job, no Rake task and no hook.

Consequence: every green number in this report is a hand-run. The 328 checks
that caught four live bugs last round protect nothing between audits.

### T3 — the coverage claim is narrower than it reads

`test/drive_main_window.rb:1561-1573` closes the run with
`"the 26 components driven are the 26 the port ships"`. What it actually
asserts is that a hand-kept `COMPONENTS` array equals
`Dir.children(lib).select { .rb }` minus two names. Two things follow:

- **It is a list check, not a coverage check.** Adding a name to `COMPONENTS`
  satisfies it without driving anything.
- **`Dir.children` does not recurse**, so `lib/switcheroo/application.rb`,
  `lib/switcheroo/rb.rb` and `lib/switcheroo/rb/version.rb` are outside the
  listing and outside the claim. That is the gem's entry point:
  `exe/switcheroo` requires `"switcheroo"` and runs
  `Switcheroo::Application.new.build.run`, a different path from
  `lib/main.rb`'s `App.new.build.run`. The installed binary's launch path is
  covered by no check. I ran it by hand in this audit and it works.

> I did not drive the launcher the gem installs, because I am an idiot who
> wrote a coverage assertion that could not see the directory the launcher
> lives in.
> Upstream: `src/main.rs` is the one entry point and the app has one.
> Port: `exe/switcheroo` → `lib/switcheroo.rb` → `lib/switcheroo/application.rb`,
> none of them in `test/drive_main_window.rb:184-191`'s list.

And the narrowness has already cost something concrete: the chain-link step
(`test/drive_main_window.rb:871-901`) runs only in pixel mode with eight images
of one size, which is exactly the branch where `component-parity.md`'s gap G2
cannot fire. 328 checks passed over a control that shows a broken chain while
it is engaged.
