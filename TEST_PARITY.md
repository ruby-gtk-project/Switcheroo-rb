# Test parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe` |
| Port | `ruby` branch |
| Upstream tests | **0** |
| Ported | 0 |
| Gaps | **0** (met trivially) |
| Port tests of its own | **70 examples**, plus a 16-check UI drive |
| Test command | `rake spec` — and it runs now |

## Upstream has no test suite

Re-verified, not assumed: no `tests/` or `test/` directory, no `#[test]`, no
`#[cfg(test)] mod tests`, no `[[test]]` in `Cargo.toml`, no `test(...)` in any
`meson.build`. Parity is 0/0 and is met trivially.

That is the whole of the parity claim, and it must not be read as a pass. A
0/0 ledger says only that upstream owed the port nothing. Everything below is
`## Extra`.

## The harness could not run, and now does

```
$ ruby -Ilib -e 'require "switcheroo/rb"'
cannot load such file -- switcheroo/rb (LoadError)
```

`spec/spec_helper.rb:29` requires `"switcheroo/rb"` and there was no
`lib/switcheroo/rb.rb` — only `lib/switcheroo/rb/version.rb` — so `rake spec`
died in the helper, and nobody found out because there were no examples.
`lib/switcheroo/rb.rb` exists now; it exposes the gem version and loads the
application object lazily, so the helper can be required on a machine with no
display. `spec/switcheroo/rb_spec.rb` is the example that exercises it.

## The gem could not start

`switcheroo-rb.gemspec` declared neither `gtk4` nor `adwaita`, while
`exe/switcheroo` requires `switcheroo`, which requires `adwaita`. An install
of the built gem could not start the app. The gemspec now declares `adwaita`,
`gtk4`, `gettext` and `rexml` as runtime dependencies, and `nix/Gemfile`,
`nix/Gemfile.lock` and `nix/gemset.nix` carry the same four so the devshell
and the packaged app agree.

## Running the suite without a display

`require "adwaita"` calls `gtk_init`, which raises `Gtk::InitError` with no
display, so every widget example would be unrunnable headless.
`spec/support/gtk_session.rb` starts `gtk4-broadwayd` — GTK's own display
server, no graphics hardware needed — when no `DISPLAY` or `WAYLAND_DISPLAY`
is set, and tears it down with the suite. No example is passed over: if neither a real
display nor `gtk4-broadwayd` is there, `gtk_init` fails and the examples fail
with it.

The widget examples keep out of the user's real state: every `Settings` under
test is built over `Gio.memory_settings_backend_new`, so nothing reaches dconf.

## Extra — what is pinned

70 examples, 0 failures.

| File | Examples | What it pins |
|---|---|---|
| `spec/switcheroo/rb_spec.rb` | 2 | the gem version, and that the harness loads at all |
| `spec/color_spec.rb` | 5 | `#rrggbbaa` with alpha last, zero padding, the Gdk round trip, and that the float channels are **truncated** as upstream's `as u8` truncates |
| `spec/file_type_spec.rb` | 10 | the output-format list's order (load-bearing twice: the combo row and the stored enum), `jpeg`→`jpg`, the non-standard `image/jpg` mime, the lossy / alpha / metadata predicates, and `CompressionType.possible_output` inside and outside a sandbox |
| `spec/settings_spec.rb` | 10 | that the shipped schema is found and declares exactly the eight keys; the schema's defaults; int and bool round trips; and that the three enum keys store **upstream's position**, not a nick |
| `spec/magick_spec.rb` | 9 | `Children` starts canceled; `begin_run` clears it; `cancel` sets it; a child registered while canceled is killed on the spot; a run's children are killed on cancel; a removed pid is left alone. Real child processes, really killed. Plus `JobFile` naming. |
| `spec/app_window_spec.rb` | 19 | `unique_stems`, `frames_for` across all five arms, stable removed indices, the last-removal clear, `construct_short_thumbnail`'s look-ahead at 4 / 6 / 7 files, the empty `FlowBoxChild` placeholder, and the 1–2 / 3+ flow-box width switch |
| `spec/convert_page_spec.rb` | 19 | every conditional row, the percentage↔pixel entry swap, `mirror_scale` with the chain open and closed and with an empty source, and the save/load round trip through the schema |

Nine of the ten behaviours `.reports/test-parity.md` listed as owed are pinned
here. The tenth — "the settings file surviving a corrupt JSON read" — no longer
exists: there is no JSON file, because `lib/settings.rb` is `Gio::Settings`
over upstream's schema now.

## Driving the app

`test/drive_main_window.rb` builds the real `App`, presents a real window and
walks it one step per main-loop tick, using the `ruby-gtk-testing` skill's
driver (copied to `test/gtk_driver.rb`). 16 checks, all passing: the welcome
page is the visible stack child and its text is German; the add button carries
its translated tooltip; the primary menu has two sections; the quality row is
visible, translated and holds its scale; the resize-unit dropdown has its
label; a colour pick survives the `notify::rgba` handler; the convert page
switches and its button is translated; the About dialog opens with the
developer name and the release notes from the metainfo.

Run it as:

```sh
gtk4-broadwayd :11 &
GDK_BACKEND=broadway BROADWAY_DISPLAY=:11 ruby test/drive_main_window.rb
```

It is what caught the `Gtk::IconTheme.for_display` crash that had been in the
port since it was written and that the reading-only pass recorded as `parity`.

Screenshots land in `tmp/shots/`. The first frames are faithful; a shot taken
after a `Gtk::Stack` crossfade shows the previous page, because no browser is
attached to broadwayd and GTK has no reason to produce new frames
(`FINDINGS.md` §9). Widget-state checks are reliable; later screenshots are
not.

## Not done

- `test/drive_main_window.rb` is not wired into `rake spec`; it is a script you
  run, and it exits non-zero when a check fails, so it can be wired into CI
  when there is a CI that can start broadwayd.
- Nothing covers `lib/magick.rb`'s job generation, `lib/temp_dir.rb`'s output
  moving, or `lib/file_chooser.rb` — those need a real `magick` binary and a
  real file dialog respectively, and neither has been faked.
