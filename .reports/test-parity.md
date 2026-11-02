# Test parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe` |
| Port | `ruby` @ `e50a6654ab1c` |
| Upstream tests | **0** |
| Ported | 0 |
| Gaps | 0 |
| Port tests of its own | **0** |
| Test command | `rake spec` (declared; **does not run**, see below) |

## Upstream has no test suite

Verified, not assumed:

```
test-census.sh <upstream> | wc -l      ->  0
grep -rnE '#\[test\]|#\[cfg\(test\)\]|mod tests' upstream/src/   ->  no hits
grep -n test upstream/Cargo.toml upstream/meson.build            ->  no hits
```

No `tests/` or `test/` directory, no `[[test]]` section, no `test(...)` call in
any `meson.build`, no `#[test]`, no `#[cfg(test)] mod tests` inline in `src/`.
Cross-checked against the build files as the skill requires: `meson.build`
declares no test binary, so there is no declared-but-uncensused target.

Parity is therefore **0/0 and is met trivially.**

**The port inherits no safety net.** Upstream wrote down nothing it considered
worth pinning, so there is no upstream knowledge to lose and no upstream test
to fail. That is the whole of the parity claim, and it is also the reason this
ledger must not be read as a pass: a 0/0 ledger says only that upstream owed
the port nothing. It says nothing about whether the port works.

## Extra

There are **no** extra tests. The `## Extra` section is empty, which is the
finding of this document.

```
test-census.sh . | wc -l  ->  0
find spec -type f         ->  spec/README.md, spec/spec_helper.rb
```

`spec/` contains a harness and no examples. 4,354 lines of `lib/` and `exe/`
are covered by zero assertions.

## The declared test command does not run

This is worse than "no tests", because the suite is wired up well enough to
look healthy and cannot execute:

```
$ ruby -Ilib -e 'require "switcheroo/rb"'
cannot load such file -- switcheroo/rb (LoadError)
```

`spec/spec_helper.rb:29` is `require "switcheroo/rb"`. There is no
`lib/switcheroo/rb.rb` — only `lib/switcheroo/rb/version.rb`. So
`rake spec` cannot get past the helper, and nobody would find out, because
there are no examples for it to fail on.

A second, independent break sits behind it:
`switcheroo-rb.gemspec` declares neither `gtk4` nor `adwaita` as a runtime
dependency (they appear only in the `Gemfile`, lines 63 and 68). `exe/switcheroo`
requires `switcheroo`, which requires `adwaita` at `lib/color.rb:3`. An install
of the built gem cannot start the app.

## Behaviour still owed

Parity owes nothing. The port's own correctness owes everything, and the
following are the behaviours a reader of `.reports/component-parity.md` cannot
currently confirm from reading alone, because nothing drives them:

| Behaviour | Where it lives |
|---|---|
| `Children#initialize` starts `@canceled = true`, so a fresh window closes without the stop dialog | `lib/magick.rb:302`, `lib/app_window.rb:929` |
| `construct_short_thumbnail` gives up the sixth slot when anything remains | `lib/app_window.rb:508` |
| a removed thumbnail keeps its index, so later removals still hit the right file | `lib/app_window.rb:484`, `:555` |
| `unique_stems` turns two files called `cover` into `cover` and `cover_1` | `lib/app_window.rb:801` |
| `frames_for` expands a PDF and a non-animatable animation per frame, and reads everything else as `[0]` | `lib/app_window.rb:827` |
| the 1–2 / 3+ flow-box width switch | `lib/app_window.rb:591` |
| `update_options` hides each row for formats that do not support it | `lib/convert_page.rb:597` |
| `mirror_scale` and `update_{width,height}_from_*` while the axes are linked | `lib/convert_page.rb:238`, `:665` |
| `Color#as_hex_string` round-trip | `lib/color.rb` |
| the settings file surviving a corrupt JSON read | `lib/settings.rb:88` |

Each is plain Ruby with no widget in it except the last three, and each could
be pinned today. None is.
