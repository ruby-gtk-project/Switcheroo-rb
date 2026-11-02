# Test parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` |
| Port | `ruby` @ `341104dabaa5d95e2ac1d0c0911ab79bb5c017df` |
| Upstream tests | **0** |
| Ported | 0 |
| Gaps | 0 |
| Test command | none declared; see **The suite cannot be run as documented** |

## Upstream has no test suite

Verified, not assumed:

```sh
test-parity/scripts/test-census.sh <upstream> | wc -l   # 0
grep -rE '#\[(test|cfg\(test\)|tokio::test|gtk::test)' <upstream>/src   # no hits
grep -n test <upstream>/Cargo.toml <upstream>/meson.build <upstream>/src/meson.build   # no hits
```

There is no `test/` or `tests/` directory, no `[[test]]` section, no
`#[cfg(test)] mod tests` anywhere in `src/`, and no test target in `meson.build`
or `Cargo.toml`. The only CI job in `.gitlab-ci.yml` is a Flatpak build.

Parity is therefore **0/0 and is met trivially.**

**The port inherits no safety net.** Not one check below was written from an
upstream test, because there is no upstream test to write it from. Every
behaviour upstream considered worth pinning is unpinned on both sides: the
frame/dimension probe's handling of an unidentifiable file, the four
`generate_job` match arms, the four `move_output` branches, the unique-stem
algorithm, the index-vs-nick GSettings storage, the two linked-resize sync
directions. The port's checks pin what the port's author chose to look at, and
nothing holds them to upstream's choices.

## Extra

Everything the port has is extra, outside the count by definition.

- `spec/app_window_spec.rb` — 18 examples on the window's state machine.
- `spec/convert_page_spec.rb` — 17 examples on the conditional rows and the resize arithmetic.
- `spec/file_type_spec.rb` — 10 examples on the format tables and predicates.
- `spec/magick_spec.rb` — 9 examples on the argument builders and the probe parser.
- `spec/settings_spec.rb` — 9 examples on the schema keys and the enum round-trip.
- `spec/color_spec.rb` — 5 examples on the float→u8 conversion and `#rrggbbaa`.
- `spec/switcheroo/rb_spec.rb` — 2 examples on the gem's version constant.
- `test/drive_main_window.rb` — 12 driver steps carrying **16** live checks against the real window (see below for why the census reports 28 rows for this file).

Census bookkeeping: `test-census.sh` reports 98 rows for the port tree, 70 in
`spec/` and 28 in `test/drive_main_window.rb`. The driver's assertion unit is
`check`, not `step` — `test/gtk_driver.rb` increments its pass counter in
`check` and uses `step` purely for grouping — so the driver's real count is 16
checks inside 12 steps, and the file's row count of 28 is the sum of both call
sites. The driver's own output confirms it: `16 of 16 checks passed`.

## The suite cannot be run as documented

This is the finding of this report, and it is a gap in its own right: a suite
nobody can run is a suite that pins nothing.

**1. `spec/` — 70 examples, unrunnable.** `rspec` is not in the project's
development bundle and not in the devshell:

```
$ nix develop --command bundle exec rspec
bundler: command not found: rspec
Install missing gem executables with `bundle install`
```

`Gemfile` has no `gem "rspec"` and `switcheroo-rb.gemspec` has no
`rspec` development dependency (the runner it does declare is
`turbo_tests2` via `kettle-test`, which is equally absent), and
`flake.nix:99-102` states outright that the devshell's `bundlerEnv` carries
"the gemspec's runtime dependencies only". So the four runtime gems are
present and nothing that could execute `spec/` is. 70 of the port's 98 checks
have never been observed to pass in this environment.

**2. `test/drive_main_window.rb` — 16 checks, pass, but not the documented
way.** Its own header says:

> Run it from the repo root inside `nix develop`:
>
>     ruby test/drive_main_window.rb

That raises `Gtk::InitError` on `require "adwaita"`, because the file sets up
`XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `GSETTINGS_BACKEND` and `LANGUAGE` but
never establishes a display — unlike `spec/support/gtk_session.rb`, which does.
`test/gtk_driver.rb:24-25` compounds it by asserting "Run it with no display
server at all — GTK4 renders to an offscreen surface… No Xvfb needed", which is
not true of these bindings: `gtk_init` fails before any widget exists.

What does work, and what was run for this audit:

```sh
nix develop --command ruby -I. -Ilib \
  -e 'require "spec/support/gtk_session"; GtkSession.load!; load "test/drive_main_window.rb"'
# → 16 of 16 checks passed / DRIVE OK
```

Two extra things that command needed and the documented one does not provide:
`-Ilib` (the driver's `$LOAD_PATH.unshift` runs *after*
`spec/support/gtk_session.rb` has already required `switcheroo`) and the
`GtkSession` bootstrap itself.

**3. `FINDINGS.md` §9's broadway recipe is off by one.** It gives

```sh
gtk4-broadwayd :5 &
GDK_BACKEND=broadway BROADWAY_DISPLAY=:5 ruby <probe>
```

`gtk4-broadwayd :5` prints `Listening on /run/user/1001/broadway6.socket`, so
`BROADWAY_DISPLAY=:5` looks for `broadway5.socket` and finds nothing.
`spec/support/gtk_session.rb:17` gets this right (`DISPLAY_NUMBER + 1`); the
documented recipe does not, and following it reproduces the `Gtk::InitError`
above rather than a working probe.

## What has to happen before this report can say anything stronger

- Declare a test runner the devshell actually carries, so `spec/`'s 70 examples run.
- Give `test/drive_main_window.rb` the display bootstrap and the load path it needs, so its documented invocation works.
- Fix `FINDINGS.md` §9 and `test/gtk_driver.rb:24-25`, both of which currently tell the next reader something that does not work.
- Name the resulting command in this header. Right now there is nothing true to put there.
