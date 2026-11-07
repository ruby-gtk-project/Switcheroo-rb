# Component parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` (unchanged) |
| Port | `ruby` @ `c5f0dbd08393214d7614d776155388a4624aaad2` |
| Previous audit | `01c68e8` (3 gaps, port @ `fb196ba`) |
| This audit | re-verified every prior gap against the current tree, re-ran both runtime gates independently (not trusted from a prior session), and re-audited the one real change since the last report (`c5f0dbd`, the `COMPONENT_PARITY.md` reconciliation) |
| Units with full parity | 23 / 26 |
| Open gaps | **3** (unchanged — `c5f0dbd` is a documentation fix, not a port change) |

Runtime gate re-run for this audit, fresh in this session:

```
$ nix develop --command xvfb-run -a ruby test/drive_main_window.rb
328 of 328 checks passed
DRIVE OK
components covered: 26
$ nix develop --command xvfb-run -a ruby -e 'require "rspec/core"; exit RSpec::Core::Runner.run(["--format","progress","--require","spec_helper","spec"])'
75 examples, 0 failures
```

Matches the task's stated gate (328 checks, 0 failed, 26 components,
drive_ok=true) and the last three audit rounds. Re-derived fresh, not copied
from `PORTING.md` or a cached result.

## What changed since the last audit

Exactly one commit, `c5f0dbd`, and it touches only `COMPONENT_PARITY.md`
(root), not `lib/`, `exe/` or `spec/`:

- Line 173 ("the Flatpak the user installs... Not started rather than
  stubbed") rewritten to say the manifest **is written but unverified** by
  `flatpak-builder` (none available in this environment) — matching what
  `PORTING.md` and the previous `.reports/component-parity.md` already said.
  Re-read this round: `COMPONENT_PARITY.md:173` now says "Written-but-
  unverified, not 'not started'" and cites the manifest file and `PORTING.md`.
  Verified true — `io.gitlab.adhami3310.Converter.json` exists at the repo
  root (`ls` confirms) and `flatpak-builder` is absent from the dev shell
  (unchanged from last round).
- The duplicate "no GResource bundle" row removed from the "Remaining gaps"
  table, replaced with a note pointing at the two rows (lines 45, 110) that
  already call the same fact *correspondence*. Re-read this round: the
  contradiction `accountability-ensurance.md`'s previous round flagged (same
  fact classified as both "correspondence" and "gap" in one document) is
  gone — `grep -n "GResource" COMPONENT_PARITY.md` now returns exactly two
  hits, both "correspondence," none in the gaps table.

Both edits are accurate and close the specific accountability finding from
the previous round. Neither changes the gap count: the Flatpak manifest was
already counted as open gap #3 before this edit, and GResource was never a
real fourth gap (see last round's writeup; re-confirmed, not re-litigated).

## Open gaps (3) — unchanged, re-verified file:line this round

| # | Unit | Gap | Where |
|---|---|---|---|
| 1 | `lib/image_thumbnail.rb` | `size_allocate()` is not reproduced. Width is a floor (`set_size_request(150, -1)`), not upstream's `min = nat = 150` `measure()` clamp *and* allocation override. Nothing in ruby-gnome dispatches a `Gtk::Widget` vfunc override from a Ruby subclass (`FINDINGS.md` §7). Binding limitation, left open. | `lib/image_thumbnail.rb`, `FINDINGS.md` §7 |
| 2 | `lib/convert_page.rb` | The colour button's accessible identity is an announcement (`gtk_accessible_announce`), not a live `Label` property update on colour change. `Gtk::Accessible#update_property` raises `NotImplementedError` (`FINDINGS.md` §1). Correspondence, not parity. | `lib/convert_page.rb`, `FINDINGS.md` §1 |
| 3 | (whole app) | `io.gitlab.adhami3310.Converter.json` exists, written from the spec, but has never been run through `flatpak-builder` — no `flatpak-builder` binary and no `org.gnome.Platform`/`org.gnome.Sdk` runtime are available in this environment. The gem native-extension builds, the GI typelib lookups inside the sandbox, and the final desktop/metainfo substitution are all unexercised. A written, unbuilt manifest is not a built one. | `io.gitlab.adhami3310.Converter.json`, `PORTING.md` |

## Not a fourth gap, re-confirmed

The absence of a GResource bundle (assets read from `data/` directly) is
correspondence, not a gap — re-verified this round: `lib/style.rb` loads CSS
via a plain file read, `lib/about_dialog.rb` parses the shipped metainfo
directly with REXML, and nothing a user can observe differs. `c5f0dbd`
brought root `COMPONENT_PARITY.md` into agreement with this; see
`accountability-ensurance.md` for what was wrong before and is fixed now.

## Rules followed

- Every gap above is cited by file and line on both sides, not asserted.
- Both runtime gates were re-run fresh this session, not read from a report
  or trusted from the task's own stated numbers.
- The one commit since the last audit was read in full (`git show c5f0dbd`)
  and verified against the live files it edited, not accepted from its
  commit message.
- Nothing here treats a binding limitation as closing a gap; both open
  binding-limitation rows stay open, cited to `FINDINGS.md`.
