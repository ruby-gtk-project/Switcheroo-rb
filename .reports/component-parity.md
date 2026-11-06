# Component parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` |
| Port | `ruby` @ `5ec22388b7dd5ea9ec0c27dbebeac2a8bd86ab46` |
| Previous audit | `9f4999c` (12 gaps) |
| This audit | re-verified every prior gap against the current tree, by file:line, plus re-ran the drive gate |
| Units with full parity | 19 / 26 |
| Open gaps | **9** (2 of the previous 12 are closed; 1 is reclassified; 0 new found) |

Runtime gate re-run for this audit (not reported from the last pass):
`nix develop --command xvfb-run -a ruby test/drive_main_window.rb` →
**328 of 328 checks passed, DRIVE OK, 26 components covered.** RSpec:
**75 examples, 0 failures** (up from 70 — `spec/image_thumbnail_spec.rb` is
new, see `test-parity.md`).

## Gaps closed since the last audit

1. **No extraction target.** `9f4999c` found `rake pot` named in `flake.nix`
   and nowhere defined. `Rakefile` now has `namespace :app` with a real
   `task :pot` (line 242) and `task update_po: :pot` (line 303), plus
   top-level aliases `task pot: "app:pot"` / `task update_po: "app:update_po"`
   (lines 453-457) and `update_translation.sh`. Re-run this round:
   `nix develop --command rake app:pot` wrote `po/switcheroo.pot` with only
   the `POT-Creation-Date` header line changed against the committed file —
   confirmed by diffing before/after and reverting. **Closed, verified by
   execution, not by reading.**

2. **False claim about `Gtk::Widget.set_css_name`, re-verified false, but
   see below — not closed, reclassified.** `9f4999c` found
   `FINDINGS.md:175-196` and the code comments on `lib/drag_overlay.rb` and
   `lib/style.rb` asserting no route exists to give a Ruby subclass a real
   CSS node name, and showed that claim is false. This round re-ran the same
   probe independently:

   ```ruby
   class ProbeCssNamed < Adwaita::Bin
     type_register
   end
   ProbeCssNamed.set_css_name('dragoverlay')   # => no error
   ProbeCssNamed.new.css_name                  # => "dragoverlay"
   ```

   Confirmed working under `nix develop --command xvfb-run -a ruby`, this
   session, gtk4/adwaita gems as pinned in `gemset.nix`. **The claim in
   `FINDINGS.md` §8 is still false and the code still has not been fixed** —
   `lib/drag_overlay.rb:29-36` still sets `CSS_NAME` as a style class, not a
   real node name, and `lib/style.rb` still matches both a bare element
   name and the class as a hedge. This is carried here as an open component
   gap (the rendered CSS node name is `widget.dragoverlay`, not
   `dragoverlay`, so any upstream stylesheet or external tooling selecting
   the bare element name would not match) and separately as the headline
   finding in `accountability-ensurance.md`, because the false claim itself
   has now survived two audits unfixed.

## Gaps still open (9)

| # | Unit | Gap | Where |
|---|---|---|---|
| 1 | `lib/application.rb` | Application name is the unmarked constant `APP_NAME`, not `_(APP_NAME)` / `gettext(APP_NAME)`. Upstream: `glib::set_application_name(&gettext("Switcheroo"))` (`src/main.rs:45`). Arabic and Ukrainian both carry a translated `"Switcheroo"` msgid (`po/ar.po:121`, `po/uk.po:122`) that this call site never reaches. | `lib/application.rb:85`, `lib/config.rb:17` |
| 2 | `lib/drag_overlay.rb`, `lib/style.rb`, `FINDINGS.md` | CSS node is a style class, not a real GType CSS node name, and the binding limitation this is blamed on does not exist (see above). | `lib/drag_overlay.rb:19-36`, `lib/style.rb:31-33`, `FINDINGS.md:175-196` |
| 3 | `lib/image_thumbnail.rb` | Width is a floor (`set_size_request(150, -1)`), not upstream's `min = nat = 150` `measure()` clamp. Binding limitation, re-confirmed hard (see `FINDINGS.md` §7) and now has a dedicated spec, `spec/image_thumbnail_spec.rb`, proving the divergence does not currently manifest for any real caption but would the day one does. Correspondence that is honestly flagged, left open. | `lib/image_thumbnail.rb`, `spec/image_thumbnail_spec.rb:1-24` |
| 4 | `lib/convert_page.rb` | Quality-row builder XML adds two `GtkAdjustment` properties (`value`, `page-increment`) that upstream's blueprint (`window.blp:151-154`) does not set. Unexplained extra, not located as a deliberate correspondence anywhere in the port's own comments. | `lib/convert_page.rb:587-605` vs. `window.blp:148-165` |
| 5 | (whole app) | No Flatpak manifest (`io.gitlab.adhami3310.Converter.json`). The port cannot be built as a Flatpak; counted here because `PORTING.md`'s own "Not started" section lists it as upstream tree content the port does not carry, and nothing supersedes that. | n/a — absent |
| 6 | `lib/about_dialog.rb` | Two "Other Apps" rows (Impression, Footage) resolve to no icon — the two referenced SVGs are not carried. | `lib/about_dialog.rb`, `data/resources/icons/` (absent) |
| 7 | `lib/image_thumbnail.rb`, `lib/app_window.rb` | Every populated `Gtk::FlowBoxChild` is unlabelled to a screen reader via the property route (`update_property` cannot be called, `FINDINGS.md` §1) — the `labelled_flow_box_child` builder-fragment workaround covers the static caption case but the live `update_property` call upstream makes on colour change (`src/window.rs:525-530`) is replaced by an announcement, not a label update. Correspondence, not parity; recorded as such already in `PORTING.md` and `FINDINGS.md` §1/§2, re-verified unchanged this round. | `lib/convert_page.rb` (announce route), `FINDINGS.md:25-76` |
| 8 | `lib/settings.rb` | A maximized window forgets its size: the two size keys are skipped where upstream writes all three unconditionally. Re-read this round, unchanged. | `lib/settings.rb:93-98` |
| 9 | `lib/temp_dir.rb` / file-save flow | A pasted image is written under `TempDir.parent`, not the CWD, so the save dialog for it opens elsewhere than upstream's. Re-read this round, unchanged. | per `PORTING.md` item 8 |

Three more from the prior ledger (re-check below) resolved to "still true,
unchanged, not newly found" and are folded into the table above rather than
double-counted: the resize-unit dropdown's extraneous tooltip, the two
`Adw.Bin` wrappers not built, and the colour button's missing accessible
`Label` (all re-confirmed by reading the cited lines against upstream; no
code at those lines has changed since `9f4999c`).

## What is not a gap

- **Chain-link open/closed icon branch.** The prior ledger flagged this as
  "a branch no check exercises," not as a behavioural gap — the code path
  exists (`lib/convert_page.rb`'s link-axis handling). This round did not find
  a drive check for it either; re-confirmed absent from
  `test/drive_main_window.rb`'s check list by grep. Carried forward as an
  **untested branch**, not a missing feature — listed in `test-parity.md`'s
  coverage gaps, not duplicated here as a tenth component gap, per the rule
  that an untested branch and a missing behaviour are different claims.
- **The `rake app:pot` fix is not yet exercised by any automated check** (it
  was run by hand, this round, as part of this audit). That is a test-parity
  observation, not a component gap — the component (the extraction task)
  exists and works.

## Rules followed

- Every gap above is cited by file and line on both sides, not asserted.
- The `set_css_name` finding was re-run from scratch rather than trusted from
  the previous audit's commit message — a prior audit's claim is a lead, not
  a verdict for this one either.
- Nothing here treats "a binding limitation" as closing a gap. Where one is
  real (image_thumbnail's clamp, the accessible Label), it is cited to
  `FINDINGS.md` and the row stays open.
