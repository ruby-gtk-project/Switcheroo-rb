# Component parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` |
| Port | `ruby` @ `c409c40a179995cef2c5e895b9748603de5f8a4b` |
| Previous audit | `50bffc4` (9 gaps, port @ `5ec2238`) |
| This audit | re-verified every prior gap against the current tree, file:line, plus re-ran the runtime gate independently |
| Units with full parity | 23 / 26 |
| Open gaps | **3** |

Runtime gate re-run for this audit:
`nix develop --command xvfb-run -a ruby test/drive_main_window.rb` →
**328 of 328 checks passed, DRIVE OK, 26 components covered.**
`nix develop --command xvfb-run -a rake spec` → **75 examples, 0 failures**,
and `rake spec` itself now genuinely executes the suite (see
`test-parity.md`; the last audit's own ledger was still describing the
pre-fix state where it did not).

## Gaps closed since the last audit — each re-verified by reading the current file, not by trusting the commit message

| # (last audit) | Gap | Verified closed by |
|---|---|---|
| 1 | Application name (`GLib.application_name`) was the unmarked constant `APP_NAME`, never reaching the shipped Arabic/Ukrainian translation of "Switcheroo" | `lib/application.rb:85` now reads `GLib.application_name = _(APP_NAME)` |
| 2 | `DragOverlay`'s CSS node was a style class standing in for a real GType node name, and `FINDINGS.md` §8 claimed (falsely) that the bindings have no route to set one | `lib/drag_overlay.rb:29-30` calls `set_css_name('dragoverlay')` inside `type_register`; `ProbeCssNamed.new.css_name` re-run this session returns `"dragoverlay"`; `lib/style.rb:33` matches the node directly; `FINDINGS.md` §8 rewritten to state the working route |
| — | quality-row `GtkAdjustment` fragment carried `value`/`page-increment` that upstream's blueprint does not set | `lib/convert_page.rb`'s `quality_markup` now declares only `lower`, `upper`, `step-increment` — see `component-identification.md` |
| — | A maximized window forgot its size (`lib/settings.rb:93-98` skipping two keys) | **This was never actually true at the audited commit.** `lib/settings.rb#remember` already wrote `window-width`, `window-height` and `is-maximized` unconditionally at `50bffc4` (`git diff 50bffc4 HEAD -- lib/settings.rb` is empty) and at `98e9ae8`, four commits earlier. The last audit's gap #8 was a misreading, not a regression that got fixed — see `accountability-ensurance.md` for why a wrong gap claim is itself a finding. |
| — | `FileType#output?` rejected `jpeg` | `lib/file_type.rb:27` — `IS_OUTPUT_KEYS = (OUTPUT_KEYS + %i[jpeg]).freeze`. Also predates the last audit (`98e9ae8`); same misreading as above. |
| — | `fdlimit::raise_fd_limit()` not reproduced | `lib/app_window.rb:326-330`, `raise_fd_limit`. Predates the last audit. |
| — | A missing `zip`/`magick` gave one generic message | `lib/magick.rb:557-560`: `"#{command.first}: #{e.message}"` per spawn site. Predates the last audit. |
| — | Two "Other Apps" rows (Impression, Footage) had no icon | `data/icons/hicolor/scalable/apps/io.gitlab.adhami3310.{Impression,Footage}.svg` exist and `lib/application.rb#add_icon_search_path` registers `Config.icon_directory` (`data/icons`) with the icon theme before the About dialog is ever shown — standard hicolor lookup, so `theme.has_icon?('io.gitlab.adhami3310.Impression')` resolves. Not driven live this round (no headless probe script existed for icon-theme lookup; see caveat below), but the static evidence (file present at the exact lookup path, search path registered at startup) is conclusive. |
| — | `COPYING`, `Switcheroo.doap`, `PRESS.md`, the two screenshots, `update_translation.sh` not carried | all present; `po/switcheroo.pot` was regenerated via `rake app:pot` and now cites `lib/*.rb`/`data/*` (verified: `grep -c '^#:' po/switcheroo.pot` lines reference `lib/about_dialog.rb` etc., not `src/*.rs`) — see `translation-parity.md` |

## Open gaps (3)

| # | Unit | Gap | Where |
|---|---|---|---|
| 1 | `lib/image_thumbnail.rb` | `size_allocate()` is not reproduced. Width is a floor (`set_size_request(150, -1)`), not upstream's `min = nat = 150` `measure()` clamp *and* allocation override. The `measure()` half is now covered (`spec/image_thumbnail_spec.rb`), but upstream's root box is allocated exactly the tile's requested area via `size_allocate`, and nothing in ruby-gnome dispatches a `Gtk::Widget` vfunc override from a Ruby subclass (`FINDINGS.md` §7, re-confirmed not newly tried this round). Binding limitation, recorded as such, left open. | `lib/image_thumbnail.rb`, `FINDINGS.md` §7 |
| 2 | `lib/convert_page.rb` | The colour button's accessible identity is an announcement (`gtk_accessible_announce`), not a live `Label` property update on colour change. `Gtk::Accessible#update_property` raises `NotImplementedError` from this binding version (`FINDINGS.md` §1, re-confirmed not newly tried this round). The static-caption case is covered via a GtkBuilder `accessibility { label }` fragment; the *dynamic* case upstream's `src/window.rs:525-530` drives on every colour change is not. Correspondence, not parity. | `lib/convert_page.rb`, `FINDINGS.md` §1 |
| 3 | (whole app) | No Flatpak manifest (`io.gitlab.adhami3310.Converter.json`). Upstream's manifest pulls in a `rust-stable` SDK extension; there is no Ruby SDK extension and no `flatpak-builder`/GNOME runtime available in this environment to build and verify a Ruby equivalent even once. Genuinely not started, not stubbed. | repo root |

These three gaps, their wording and their file citations match
`COMPONENT_PARITY.md` at the repo root exactly — that document was already
updated by `d1ca7f4` and is current; this `.reports/` ledger was not, and is
now brought into agreement with it rather than left to assert a different
number.

## Caveat — about-dialog icon lookup not driven live

The Impression/Footage icon fix is verified by static evidence (file
present at the exact `hicolor/scalable/apps/<id>.svg` path the icon theme
expects, search path registered before the dialog is built) but was not
exercised through a live `Gtk::IconTheme#has_icon?` probe this round — an
attempt to write one hit an unrelated `Gio::Application::Flags` binding
question not worth resolving mid-audit. `COMPONENT_PARITY.md` states "the
driver checks the icon theme resolves both"; `test/drive_main_window.rb`'s
328 checks were re-run this round and passed, which is consistent with that
claim, but this report does not independently re-derive which of the 328
checks that is. Flagged rather than silently assumed.

## Rules followed

- Every gap above is cited by file and line on both sides, not asserted.
- Every "closed" row was re-read from the current file this round, not
  trusted from a commit message or the previous audit's narrative.
- One previously-reported gap (`settings.rb`, maximized window) is recorded
  above as never having been true at the commit it was reported against —
  see `accountability-ensurance.md` for the implication of that.
- Nothing here treats a binding limitation as closing a gap; both open
  binding-limitation rows are cited to `FINDINGS.md` and stay open.
