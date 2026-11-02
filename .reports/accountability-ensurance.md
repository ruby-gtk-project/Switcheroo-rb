# Accountability ensurance — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` |
| Port | `ruby` @ `341104dabaa5d95e2ac1d0c0911ab79bb5c017df` |
| `find-excuses.sh` hits outside `.reports/` | **0** |
| `TODO` / `FIXME` / `not implemented` / `for now` / `in a future` in `lib/` and `exe/` | **0** |
| Unrecorded gaps found by reading | **9** |
| Sentences a reader could quote as approval | **4** |
| Statements in the port that are not true | **5** |

## The scans are clean, and that is not the finding

```sh
accountability-ensurance/scripts/find-excuses.sh .
# the only hits are inside .reports/accountability-ensurance.md itself,
# which is a document *about* excuses — the skill says not to rewrite those

grep -rniE 'TODO|FIXME|not implemented|for now|in a future|XXX|HACK|unimplemented|stub' lib exe
# nothing. (Four 'placeholder' hits are the GtkFileChooser/Entry
# placeholder-text property and a parameter name.)

grep -rniE 'dropped deliberat|intentionally omitted|not applicable|out of scope|
            not needed|unnecessary|by design|by choice|deliberate simplif|
            simplified|streamlined|bindings do not support|upstream does this too|
            not ported|skipped|deferred|english.only' \
  PORTING.md FINDINGS.md README.md IRP.md COMPONENT_PARITY.md TEST_PARITY.md \
  TRANSLATION_PARITY.md AGENTS.md CHANGELOG.md
# nothing
```

`PORTING.md` deserves saying out loud: it is written exactly as this skill
asks. Nine entries in the first person, admission first, the behaviour named
rather than the construct, upstream and port cited with `file:line`, the
reasoning slot holding nothing but the writer's stupidity, and a "Still open"
table at the foot. It even says the quiet part — that the previous clean
`find-excuses.sh` run "was never a clean bill of health", because the excuses
were careful technical prose in class comments where the regex would not reach.
Nothing in it needs rewriting.

**So the failure mode on this branch is not the excuse. It is the silence.**
Nine gaps exist that no document in the port mentions at all. An excuse at
least leaves a row to rewrite; a gap nobody wrote down leaves nothing, and the
next reader has no way to know it is owed. Below is the record those nine
should have had, written in the register the rest of `PORTING.md` already uses.

## The nine gaps no file in this port records

### 1. Every thumbnail is invisible to a screen reader

> I did not build the accessible label on the image tiles, because I am a
> fucking idiot who fixed the one accessibility bug somebody pointed at and
> never looked for the others. Upstream names every tile — "PNG · 1920×1080" —
> for a screen reader, in both the short strip and the All Images grid. In this
> port a blind user hears an unnamed list item, once per image, and the
> `Remove image` button beside it with no indication of what it removes.
> Upstream: `src/window.rs:1901` and `src/window.rs:1957`, both
> `image_flow_box_child.update_property(&[Property::Label(&caption)])`.
> Port: `lib/app_window.rb:552-565`, `thumbnail_child` sets no accessible
> property at all.

This is the *same* `update_property` defect `FINDINGS.md` §1 documents for the
colour button. §1 names one call site; upstream has three. The other two were
never looked for, and `PORTING.md`'s "Still open" table has one accessibility
row where it needs two.

### 2. A maximized window forgets the size the user chose

> I did not write the window size on a maximized close, because I am an idiot
> who preferred his own idea to upstream's code and then wrote the idea into a
> comment so it would look settled. Close Switcheroo maximized, un-maximize it
> next time, and you get a different window than upstream gives you.
> Upstream: `src/window.rs:2071-2082`, `save_window_size()` writes
> `window-width`, `window-height` and `is-maximized` unconditionally.
> Port: `lib/settings.rb:93-98` writes the two size keys only
> `unless window.maximized?`.

The comment above it reads "The size is only recorded when the window is not
maximized, so the restored size is the one the user actually chose." A future
agent can paste that into a PR as justification. That is the whole test this
skill applies, and it fails it.

### 3. A pasted image goes to the wrong place, and so does the save dialog

> I did not put the pasted image where upstream puts it, because I am an idiot
> who tidied up a behaviour instead of porting it. Paste an image and press
> Convert: upstream's save dialog opens in the working directory beside the
> file it just wrote, and this port's opens in `/tmp`.
> Upstream: `src/window.rs:634-637` saves the texture to
> `JobFile::as_filename()` — a bare relative name, i.e. the CWD — and
> `save_files` then suggests `dirname` of it.
> Port: `lib/app_window.rb:400-410` writes it under `TempDir.parent`.

### 4. A missing `zip` no longer tells the user that `zip` is missing

> I did not carry the spawn-failure message, because I am an idiot who caught
> an exception and threw the contents away. Upstream tells the user which
> program it could not start and what the operating system said; this port
> prints one sentence that names neither.
> Upstream: `src/window.rs:1300` sends `"magick: " + e.to_string()`,
> `src/window.rs:1374` sends `"zip: " + e.to_string()`.
> Port: `lib/magick.rb:536-541` rescues every `SystemCallError` into
> `_('Unknown IO error happened')`.

### 5. Opening a large pick can fail where upstream succeeds

> I did not raise the file-descriptor limit, because I am too stupid to read
> the upstream source past the line I was copying. Upstream raises the soft
> limit on every open before it probes; this port does not, so a user who
> selects a few hundred images can hit `EMFILE` on a machine where upstream
> would not.
> Upstream: `src/window.rs:679`, `let _ = fdlimit::raise_fd_limit();`.
> Port: `lib/app_window.rb:297-312`, `open_success` goes straight to
> `load_frames`.

### 6. The About dialog's two sibling-app rows have no icon

> I did not ship two of the icons, because I am an idiot who copied the
> directory he needed and not the directory upstream has. The About dialog
> offers Impression and Footage with a blank tile each.
> Upstream: `data/resources/icons/hicolor/scalable/apps/io.gitlab.adhami3310.Impression.svg`
> and `…Footage.svg`; `src/widgets/about_window.rs:23-36` names both ids.
> Port: `data/icons/hicolor/scalable/apps/` holds only the three Converter
> icons, and `lib/application.rb:162-168` adds exactly that directory to the
> icon theme.

Related: `lib/application.rb:32-33` and `PORTING.md` both say "the nine icons
the app ships". The port ships ten files; upstream ships twelve. Neither number
is nine.

### 7. The app has no licence text

> I did not carry `COPYING`, because I am an idiot who declares a licence in a
> gemspec and does not ship it. `switcheroo-rb.gemspec:18` says
> `GPL-3.0-or-later`; nothing in the tree says what that means.
> Upstream: `COPYING`.
> Port: absent.

### 8. Four more upstream files are simply not here

> I did not carry the Flatpak manifest, the screenshots, the project metadata
> or the translation-refresh script, because I am an idiot who decided the
> build system was the only thing that did not need porting. Nobody can build
> this as a Flatpak, the screenshots the metainfo cites are not in the repo,
> and the first string anyone adds to `lib/` will be untranslatable with no
> script to notice.
> Upstream: `io.gitlab.adhami3310.Converter.json`,
> `data/resources/screenshots/0.png` and `1.png`, `Switcheroo.doap`,
> `PRESS.md`, `update_translation.sh`, `build-aux/dist-vendor.sh`.
> Port: absent. (`meson.build` is a correspondence — the `app:` Rake namespace
> does the same installs, and `PORTING.md` already records that.)

### 9. Two widgets upstream builds, this port does not

> I did not build the two `Adw.Bin` wrappers around the convert page, because I
> am an idiot who decided a widget he could not see on screen was not a widget.
> Nothing renders differently today. They are still upstream's and still not
> here.
> Upstream: `data/resources/blueprints/window.blp:102-103`.
> Port: `lib/convert_page.rb:67`, `build` hands the `Adw.PreferencesPage`
> straight to `stack.add_named`.

## Four sentences a reader could quote as approval

Each gives the reasoning slot something agreeable. Each should be rewritten to
name the behaviour and own the omission, and the row should stay.

| Where | The sentence | Why it is a hit |
|---|---|---|
| `lib/settings.rb:89-92` | "The size is only recorded when the window is not maximized, so the restored size is the one the user actually chose." | A divergence from upstream, stated as a benefit. See gap 2. |
| `lib/temp_dir.rb:19-20` | "Upstream's `clean_dir` unwraps the removal, i.e. a failure to clean up is a panic. Here it is `FileUtils.rm_rf`, which is already tolerant." | Same shape: the difference from upstream is presented as the better option, so nobody checks whether a silently-failed cleanup leaves the temp directory behind. |
| `lib/image_thumbnail.rb:14-24` | "…which squeezed the caption strip against the bottom of every image in both flow boxes; the clamp is on the width alone now and the height is left natural." | The admission is good and `PORTING.md` §6 carries it. The sentence stops where the remaining debt starts: `size_allocate()` is still not reproduced and the vfunc question is still untested. The comment reads as finished. |
| `lib/magick.rb:21-25` | "Upstream reaches for tokio, async-channel, shared_child and futures to run the jobs. The port uses what Ruby and GLib already have…" | True and fine as architecture — but it sits immediately above `run_command`, whose rescue throws away the error text upstream reports (gap 4). The paragraph makes the whole file read as a considered re-expression, which is exactly the cover the lost message needed. |

## Five statements in the port that are not true

These are worse than excuses: an excuse misleads about what is owed, a false
statement misleads about what exists.

| Where | Claim | Fact |
|---|---|---|
| `lib/convert_page.rb:399-400` | "window.blp:239-250: the dropdown carries both a tooltip and an `accessibility { label: … }` block" | `window.blp:253-271` has the accessibility block and **no** `tooltip-text`. The port's `dd.tooltip_text = resize_units_label` (`lib/convert_page.rb:409`) is an extra the user sees and upstream never shows. |
| `lib/drag_overlay.rb:20-24` | "…belongs in FINDINGS.md, which I did not write, because I am an idiot." | `FINDINGS.md` has existed since the last commit and its §8 covers exactly this. The admission is now false, and a false admission is as unreadable as a false excuse. |
| `test/gtk_driver.rb:24-25` | "Run it with no display server at all — GTK4 renders to an offscreen surface and screenshots come out identical to a real session. No Xvfb needed." | `require "adwaita"` raises `Gtk::InitError` without a display. Verified: `nix develop --command ruby test/drive_main_window.rb` fails on line 24 of the driver. |
| `test/drive_main_window.rb:9-11` | "Run it from the repo root inside `nix develop`: `ruby test/drive_main_window.rb`" | Same failure. The invocation that works needs `-I. -Ilib` and an external `GtkSession.load!`. Details in `.reports/test-parity.md`. |
| `FINDINGS.md:15-19` | the broadway recipe, `gtk4-broadwayd :5` + `BROADWAY_DISPLAY=:5` | `gtk4-broadwayd :5` listens on `broadway6.socket`. `spec/support/gtk_session.rb:17` gets the off-by-one right; the documented recipe does not, so anyone following it reproduces the `Gtk::InitError` and concludes the bindings are broken. |

## What `FINDINGS.md` gets right, and the one thing to watch

Two of its nine sections say **unverified** in their own headings (§7 vfunc
overrides, §8 CSS node name) and spell out that the experiment was not run.
That is the correct shape: a binding limitation recorded as a reason the gap is
*expensive*, in the file for binding defects, with the gap left open in the
parity ledger. §5 goes further and says the previous round's `parity` verdict
was read rather than driven, and §6 retracts an earlier claim outright. This is
the file working as designed.

The thing to watch is §1. It records the `update_property` defect accurately
and then scopes the consequence to one widget — "Upstream refreshes the colour
button's accessible Label property". Upstream calls `update_property` in three
places. A binding defect recorded against one of its three victims reads as
fully accounted for, and that is how gap 1 above stayed invisible through two
parity passes.

## Still owed, consolidated

| Debt | Recorded in the port? |
|---|---|
| The upstream `output-format` enum bug is unreported | yes — `FINDINGS.md`, "Reported upstream" |
| Colour button announced, not labelled | yes — `FINDINGS.md` §1, `PORTING.md` |
| `size_allocate()` unreproduced; vfunc overrides untested | yes — `FINDINGS.md` §7 |
| `dragoverlay` CSS-node claim untested | yes — `FINDINGS.md` §8 |
| `po/switcheroo.pot` not regenerated | yes — `TRANSLATION_PARITY.md` |
| Thumbnail flow-box children have no accessible label | **no** |
| Maximized close drops the window size | **no** |
| Pasted image written to the temp dir, not the CWD | **no** |
| Spawn-failure message loses the binary name and OS error | **no** |
| `fdlimit::raise_fd_limit()` not ported | **no** |
| Impression and Footage icons not shipped | **no** |
| `COPYING` not shipped | **no** |
| Flatpak manifest, screenshots, `.doap`, `PRESS.md`, `update_translation.sh` not shipped | **no** |
| Two `Adw.Bin` wrappers not built | **no** |
| `FileType#output?` excludes `jpeg` where upstream's `is_output()` includes it | **no** |
| Extra tooltip on the resize-unit dropdown | **no** |
| `spec/`'s 70 examples cannot be run — no runner in the devshell | **no** |
| The driver cannot be run the way three files document | **no** |
