# Component parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` |
| Port | `ruby` @ `d15487b137763f668e1bf23284beb7f99989a1da` |
| Widget units | 17 |
| Units with parity | **13 / 17** |
| Non-widget units | 8, all 8 parity |
| Open gaps | **7** |
| Driven | yes — `nix develop --command xvfb-run -a ruby test/drive_main_window.rb`, **328 / 328 checks**, 81 steps, 17 screenshots, 26 components named |
| Specs | `nix develop --command xvfb-run -a ruby -e '…RSpec::Core::Runner.run…'` — 70 examples, 0 failures |

Verdict: **not clean — 7 gaps.** The widget trees, the CSS, the actions, the
accelerators and the message set are in excellent shape, and the headless drive
exercises the whole app including the conversion pipeline, both dialogs, the
drop target, the clipboard and a second window. The gaps left are two live
behavioural divergences (one of which 328 passing checks walk straight past),
one accessibility clamp that is genuinely blocked by the bindings, one
avoidable divergence whose stated excuse I disproved in this audit, two pieces
of upstream tree content, and one unexplained extra.

## File mapping

```
src/application.rs + src/main.rs + src/config.rs.in   -> lib/application.rb, lib/main.rb, lib/config.rb
window.blp:4-47 + src/window.rs                       -> lib/app_window.rb
src/drag_overlay.rs                                   -> lib/drag_overlay.rb
window.blp:53-84                                      -> lib/welcome_page.rb
window.blp:86-97                                      -> lib/loading_page.rb
window.blp:331-341                                    -> lib/invalid_image_page.rb
window.blp:343-374                                    -> lib/converting_page.rb
window.blp:99-329 + src/window.rs (WindowUI etc.)     -> lib/convert_page.rb
window.blp:380-441                                    -> lib/all_images_page.rb
image-thumbnail.blp + src/widgets/image_thumbnail.rs  -> lib/image_thumbnail.rb
image-rest.blp + src/widgets/image_rest.rs            -> lib/image_rest.rb
window.blp:484-513                                    -> lib/primary_menu.rb
window.blp:448-482                                    -> lib/shortcuts_dialog.rb
src/window.rs:1463-1505                               -> lib/error_dialog.rb
src/window.rs:572-608 + :1543-1583                    -> lib/stop_converting_dialog.rb  (2 -> 1, factored)
src/widgets/about_window.rs                           -> lib/about_dialog.rb
data/resources/style.css                              -> lib/style.rb                   (CSS -> Ruby heredoc)
src/magick.rs                                         -> lib/magick.rb
src/filetypes.rs                                      -> lib/file_type.rb
src/file_chooser.rs                                   -> lib/file_chooser.rb
src/input_file.rs                                     -> lib/input_file.rb
src/temp.rs                                           -> lib/temp_dir.rb
src/color.rs                                          -> lib/color.rb
gio::Settings + data/…gschema.xml.in                  -> lib/settings.rb
src/main.rs domain bind                               -> lib/translations.rb
```

Correspondences recorded once so they are not re-read as gaps: `Adw.` ↔
`Adwaita::`; no `.ui`/`.blp` by house style, with three GtkBuilder heredocs as
the accessibility-forced exception; the two identical stop dialogs merged;
`connect_*_notify` ↔ `notify::*`; `connect_state_notify` on the single-PDF
switch ↔ `notify::active` (a switch with no `state-set` handler has
`state == active`); `Gtk.StackPage`/`Gtk.Align`/`Gtk.Orientation` and the
interface lists are not widgets; `tokio` + `SharedChild` ↔ `Thread` +
`GLib::Timeout` + `Process.kill`; `ashpd` OpenFile/OpenDirectory ↔
`Gtk::FileLauncher`; `fdlimit` ↔ `Process.setrlimit`; `meson` ↔ `Rakefile`.

## Stylesheet — parity

`lib/style.rb::CSS` is `data/resources/style.css` rule for rule, including the
`@media (prefers-contrast: more)` block. The only textual differences are the
doubled `dragoverlay, .dragoverlay` selector (gap G4 below) and a dropped
`/* background-color */` comment inside `.image-remove`, which renders
identically. Every app-namespaced class attached on either side has a rule.
`image-container` and `image-thumbnail` are attached on both sides and defined
on neither — dead upstream, dead here, parity. Confirmed at runtime: the drive
run parses the installed provider and the welcome, convert, thumbnail,
all-images, converting and animation states are screenshotted under
`tmp/shots/`.

## Messages — 91 / 91, one unmarked call site

91 distinct source msgids upstream, 91 in the port, key sets byte-identical
(`comm -23` and `comm -13` both empty). Occurrences 112 → 104, every one of the
differences explained in `translation-parity.md` — except one, which is gap G1.

## Actions and accelerators — parity

All eight actions exist and were driven: `app.quit`, `app.new-window`,
`win.close`, `win.add`, `win.clear`, `win.show-help-overlay`, `win.about`,
`win.paste`. All seven accelerators match upstream's `setup_accels()`
byte for byte, asserted by `Gtk.accelerator_parse` in the drive run.

---

## Units with parity (13)

| Unit | Upstream | Port | Driven |
|---|---|---|---|
| application | `src/application.rs` | `lib/application.rb` | activate, open, `--new-window`, second window, 7 accels |
| app window | `window.blp:4-47` + `src/window.rs` | `lib/app_window.rb` | close-request guard, 5 stack switches, both filters, geometry |
| drag overlay | `src/drag_overlay.rs` | `lib/drag_overlay.rb` | reveal on hover, drop refused, drop accepted — **except** the CSS node, G4 |
| welcome page | `window.blp:53-84` | `lib/welcome_page.rb` | shown, in German, button → `win.add` |
| loading page | `window.blp:86-97` | `lib/loading_page.rb` | spinner starts and stops |
| invalid-image page | `window.blp:331-341` | `lib/invalid_image_page.rb` | a corrupt file reaches it, in German |
| converting page | `window.blp:343-374` | `lib/converting_page.rb` | `Loading…` → `3/7` → `Collecting files`, cancel |
| all-images page | `window.blp:380-441` | `lib/all_images_page.rb` | pushed by the `+N` tile, own spinner, own add button |
| `+N` tile | `image-rest.blp` + `image_rest.rs` | `lib/image_rest.rb` | appears at >6 files, label, tooltip, icon, push |
| primary menu | `window.blp:484-513` | `lib/primary_menu.rb` | two sections, item for item, in German |
| shortcuts dialog | `window.blp:448-482` | `lib/shortcuts_dialog.rb` | opened by action, six items, `C_()` section title |
| error dialog | `src/window.rs:1463-1505` | `lib/error_dialog.rb` | raised by a real failing `magick`, copy → clipboard + toast |
| stop dialog | `src/window.rs:572-608`, `:1543-1583` | `lib/stop_converting_dialog.rb` | both call sites: cancel button and close-request, on two windows |

Non-widget units with parity: `magick.rb` (command line asserted
argument-for-argument, including the SVG `-density` and PDF `-density`
branches, `-jFSm0`, the PDF merge, the `"magick: <errno>"` / `"zip: <errno>"`
spawn failures), `file_type.rb` (all 15 inputs, 13 outputs, `is_output()`'s
`jpeg` alias now present), `file_chooser.rb` (all four error messages),
`input_file.rb`, `temp_dir.rb`, `color.rb`, `settings.rb` (all three geometry
keys written unconditionally, the three enums as positions),
`translations.rb` (German verified on screen).

---

## Gaps (7)

### G1 — the application name is not translated

The shell, the window-menu and every GTK dialog that falls back to the
application name show English in every language, including the two that
translate it.

> I did not mark the application name for translation, because I am an idiot
> who copied a constant out of a build file instead of reading the line next to
> it.
> Upstream: `src/main.rs:45`, `glib::set_application_name(&gettext("Switcheroo"))`.
> Port: `lib/application.rb:85` sets `GLib.application_name = APP_NAME`, and
> `lib/config.rb:17` is `APP_NAME = 'Switcheroo'` — a bare literal with no
> marker.

Driven: under `LANGUAGE=de` the port's `GLib.application_name` is
`"Switcheroo"` while every other string on the window comes back German
(`"Bilder hierher ziehen und ablegen"`, `"Primäres Menü"`, `"Exportformat"`,
`"Allgemein"`). The msgid is already in the catalogue — `po/ar.po` has
`"سويتشيرو"` and `po/uk.po` has `"Міняло"` — so this is one call site away from
free. Recorded against the message in `translation-parity.md` as well.

### G2 — re-engaging the chain link shows a broken chain

With images that do not share a size, clicking the chain link closed leaves the
*open*-chain icon on screen and skips the re-mirror, so the control lies about
its own state.

> I did not reproduce upstream's link-axis click handler, because I am an idiot
> who pasted one guard into three places that do not want the same guard.
> Upstream: `src/window.rs:413-440` guards the click handler on
> `link_axis.is_active() && link_axis.is_visible()` and nothing else.
> Port: `lib/convert_page.rb:733` `linked?` is
> `active? && visible? && !dimensions.nil?`, and
> `lib/convert_page.rb:738-745` `on_link_axis_clicked` uses it, so the `else`
> branch sets `LOOSE_ICON` whenever the loaded images disagree on a size.

Driven in this audit: percentage mode, `image_width`/`image_height` nil, after
`link_axis.clicked` the button reports `active=true visible=true` and
`icon_name == "chain-link-loose-symbolic"`. Upstream shows
`chain-link-symbolic` and re-mirrors the height percentage onto the width.
`dimensions` is the right guard for `update_width_from_height` /
`update_height_from_width` (upstream has it there, `src/window.rs:1775-1778`)
and the wrong guard for the click.

**The drive run does not catch this.** `test/drive_main_window.rb:871-901`
exercises the chain link only in pixel mode with eight images that share a
size, which is the one branch where the extra guard is satisfied.

### G3 — a thumbnail is not clamped to 150 wide, only floored at it

A caption wider than the tile widens the tile, and with it every other tile in
a homogeneous flow box, instead of being clipped.

> I did not build the thumbnail's width clamp, because I am an idiot who
> settled for a size request and called it a measure override.
> Upstream: `src/widgets/image_thumbnail.rs:120-131`, `measure()` returns
> `(150, 150, …)` for the horizontal orientation whenever the file's dimensions
> are known, so minimum *and* natural are 150.
> Port: `lib/image_thumbnail.rb:171-175` calls `set_size_request(150, -1)`,
> which is a minimum only.

Measured in this audit: with the caption `"PNG · 1920×1080"` the port reports
`min=150 nat=150` and matches. With a caption of ~29 characters it reports
`min=206 nat=206` where upstream still reports 150. Real captions
(`"TIFF · 65535×65535"` is the worst case the format table and five-digit
dimensions allow) all measure 150, so the divergence is reachable through a
larger text scale rather than through data.

**The binding limitation behind it is now verified rather than assumed**
(`FINDINGS.md` §7 should drop the "unverified"): `GLib::Object` exposes no
vfunc override hook, a `do_measure` method on an `Adwaita::Bin` subclass is
never called, and `Gtk::Widget.implement_virtual_function(Sub, "measure")`
returns `false`. The gap is hard. It is still a gap.
`size_allocate` is not reproduced either and needs nothing: `Adwaita::Bin`
allocates its single child the whole size, which is what upstream's override
does.

### G4 — the drag overlay's CSS node is a class, and the reason given for it is false

> I did not name the DragOverlay's CSS node, because I am an idiot who wrote
> down a binding limitation I had not tested and then built the workaround into
> the stylesheet so nobody would look again.
> Upstream: `src/drag_overlay.rs:30`, `klass.set_css_name("dragoverlay")` —
> an element selector.
> Port: `lib/drag_overlay.rb:29,36` adds a style class of the same name and
> `lib/style.rb:31-37` doubles the selector to `dragoverlay, .dragoverlay`,
> under a comment stating as fact that "the Ruby bindings cannot name a
> subclass's node".

Disproved in this audit. `Gtk::Widget.respond_to?(:set_css_name)` is `true`,
and on an `Adwaita::Bin` subclass carrying `type_register("…")` the call
`set_css_name("dragoverlay")` yields an instance whose `css_name` is
`"dragoverlay"` under gtk4 4.22.4 and the bundled `gtk4` gem. The rendered
result happens to match today because the stylesheet carries both selectors —
that is the workaround working, not the gap closing. A future rule written
against `dragoverlay` as an element (a descendant selector, a child selector)
would not apply to the port.

The same falsehood appears in `PORTING.md:143-145` where it is at least
labelled "unverified", and `FINDINGS.md` §8 should now record the opposite of
what it says.

### G5 — the port cannot be built as a Flatpak

> I did not carry the Flatpak manifest, because I am an idiot who shipped an
> app for a platform whose only distribution channel I left out of the tree.
> Upstream: `io.gitlab.adhami3310.Converter.json`, the Flathub manifest, plus
> `build-aux/dist-vendor.sh` for the offline source bundle.
> Port: neither file exists. `rake app:install` installs into a prefix and
> nothing else.

This also keeps the sandbox branch of `lib/temp_dir.rb` (`/.flatpak-info` →
`XDG_CACHE_HOME/tmp`) and the `CompressionType.possible_output(sandboxed)`
distinction unreachable and therefore undriven on the only platform where they
matter.

### G6 — the message catalogue can never be refreshed

A string added to the port reaches no translator, ever, and the shipped `.pot`
points at files that do not exist here.

> I did not build the translation-refresh path, because I am an idiot who
> wrote the name of a Rake task into the dev shell's banner instead of writing
> the task.
> Upstream: `update_translation.sh` drives meson's `switcheroo-pot` and
> `switcheroo-update-po` targets.
> Port: `rake -T` lists `app:locale`, `app:clean_locale` and `app:install` and
> no extraction task at all; `po/switcheroo.pot` is upstream's file unchanged,
> so its `#:` references are `src/window.rs` lines; and `flake.nix:192` says
> "rxgettext, the extractor `rake pot` drives", naming a task that does not
> exist.

The `rxgettext` binary *is* in the dev shell, so this is a Rakefile task away.
Also recorded in `translation-parity.md` and `accountability-ensurance.md`.

### G7 — the quality scale's adjustment carries two properties upstream's does not

> I did not keep the quality adjustment to upstream's four properties, because
> I am an idiot who padded a builder fragment with defaults I never compared.
> Upstream: `window.blp:149-153` — `lower: 1`, `upper: 100`,
> `step-increment: 1`. No `value`, no `page-increment`.
> Port: `lib/convert_page.rb:592,594` (in `quality_markup`) adds
> `<property name="value">100</property>` and
> `<property name="page-increment">10</property>`.

`value` is harmless — `load_options` overwrites it on the next line. The
`page-increment` is a behaviour difference: Page Up / Page Down on the quality
scale moves 10 in the port and 0 upstream. Every extra is explained in the
ledger or removed; this one was neither.

---

## Tree content upstream ships

| Upstream path | State |
|---|---|
| `data/resources/icons/**` (12 files) | **parity** — byte-identical under `data/icons/`, and `App#add_icon_search_path` points the theme at them; the About dialog's Impression and Footage rows resolve |
| `data/resources/screenshots/0.png`, `1.png` | **parity** — byte-identical under `data/screenshots/` |
| `COPYING`, `Switcheroo.doap`, `PRESS.md` | **parity** — byte-identical |
| `data/…gschema.xml.in`, `…metainfo.xml.in.in`, `…service.in` | **parity** — byte-identical |
| `data/…desktop.in.in` | **parity** — same keys; the template is `data/switcheroo.desktop.in` but `Rakefile:294` installs it as `#{APP_ID}.desktop`, which is the name that matters |
| `po/**` | **parity** — 20 `.po`, `LINGUAS` and `switcheroo.pot` byte-identical; `POTFILES.in` rewritten to the Ruby paths and complete |
| `io.gitlab.adhami3310.Converter.json` | **gap G5** |
| `build-aux/dist-vendor.sh` | **gap G5** |
| `update_translation.sh` | **gap G6** |
| `meson.build`, `meson_options.txt`, `*/meson.build` | correspondence — `Rakefile` `app:` namespace + `flake.nix`; the install task produces the same desktop file, service file, icons, schema and `.mo` tree |
| `Cargo.toml`, `Cargo.lock`, `src/config.rs.in`, `src/widgets/mod.rs`, `.gitlab-ci.yml` | correspondence — the generated constants live in `lib/config.rb`; upstream's CI only runs `cargo fmt --check` |

## Steps 4 and 5

- **Step 4, the styling renders.** `lib/style.rb` compared line for line
  against `data/resources/style.css`; one correspondence (G4) and one dropped
  comment. 17 screenshots under `tmp/shots/`.
- **Step 5, the behaviour fires.** 328 of 328 checks across 81 steps: the
  seven accelerators, the six window actions, the drag overlay's reveal, the
  style provider parsing, every named icon resolving in the theme, the menu
  model item for item, the shortcuts dialog's six items, the About dialog's
  appdata fields and release notes, three toasts, the file chooser's four
  refusals, the invalid-image page, the eight-file probe, the `+N` tile and the
  push it performs, thumbnail removal across both strips, the two nested bins,
  twelve output formats, every conditional row appearing and disappearing, the
  chain link in pixel mode, the filter radios, the dpi entry, `save_options` /
  `load_options` round-tripping, a maximized window's geometry, `generate_job`'s
  command line, `frames_for`'s expansion, stem de-duplication, a real
  conversion of seven images into a ZIP *and* into a directory, cancellation,
  the error dialog with a real child's stderr, a real drop, a real paste, the
  single-image and single-animation strips, the texture fallback, the
  accessible caption on the flow-box child, and a second window opened and
  closed.
- **Not driven, therefore unconfirmed:** G2's branch (percentage mode with
  mismatched sizes — see above), the sandboxed temp-dir and
  `possible_output(true)` branches (unreachable without G5), D-Bus activation
  and the desktop file's `new-window` action (need an installed, registered
  binary), the accessible *Label* property on the colour button and the
  thumbnails (blocked, `FINDINGS.md` §1-2, re-verified below), and
  `lib/switcheroo/*.rb` — the gem entry point `exe/switcheroo` →
  `Switcheroo::Application` is outside the drive run's component list. I smoke-
  tested it by hand in this audit and it builds an `Adwaita::Application` with
  the right id.

## Binding limits re-verified in this audit

| Claim | Verdict |
|---|---|
| `Gtk::Accessible#update_property` cannot be called | **true** — `NotImplementedError: TODO: in Ruby -> GIArgument(array/C)[interface(enum)](GtkAccessibleProperty)` |
| `Gtk::AccessibleList.new_from_array` is not bound | **true** — `NoMethodError`; the class has only `gtype` |
| Widget vfunc overrides unavailable | **true** — no override hook on `GLib::Object`, `do_measure` never called, `implement_virtual_function` returns `false`. Was "unverified"; now verified |
| CSS node name on a subclass impossible | **FALSE** — `set_css_name` works. Gap G4 |
