# Accountability ensurance — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` |
| Port | `ruby` @ `5ec22388b7dd5ea9ec0c27dbebeac2a8bd86ab46` |
| Scanned | `lib/`, `exe/`, `.reports/`, `PORTING.md`, `COMPONENT_PARITY.md`, `TEST_PARITY.md`, `TRANSLATION_PARITY.md`, `FINDINGS.md`, `.gitlab-ci.yml`, `Rakefile`, `flake.nix` |
| `TODO`/`FIXME`/`not implemented`/`for now`/`in a future` in `lib/` and `exe/` | **0**, re-confirmed by a fresh grep this round |
| `find-excuses.sh` hits outside documents *about* excuses | **0**, re-confirmed by running the scan this round |
| **Unresolved false claims/greens, carried over unfixed from the previous audit** | **2** |
| New false claim found this round | 0 (none of the `5ec2238` diff touches a claim) |

Verdict: **not clean.** The headline finding this round is not a new excuse —
it is that the previous audit (`9f4999c`) already found and named two false
greens by file and line, and **neither has been fixed since**, despite a
commit (`5ec2238`) landing on top of that audit that touched the Rakefile,
`update_translation.sh` and five `.po`-adjacent files without touching either.
A false green a reviewer already caught, left standing through the next
commit, is worse than a fresh one: it means the finding was read and not
acted on, or not read.

## The excuse scan, re-run

```
$ .claude/skills/accountability-ensurance/scripts/find-excuses.sh .
.reports/accountability-ensurance.md:25:by design:...
.reports/accountability-ensurance.md:27:not ported:...
.reports/accountability-ensurance.md:82:skipped:...
```

All three are inside this document itself, quoting the skill's own
vocabulary table and the "not ported"/"skipped" rows of prior worked
examples — the skill explicitly exempts documents *about* excuses. A fresh
`grep -rniE 'TODO|FIXME|not implemented|for now|in a future|XXX|HACK'` over
`lib/` and `exe/` returns nothing. Register is clean; what follows is not a
register problem.

## Unresolved false green #1 — `TEST_PARITY.md` still advertises a command that runs nothing

```
TEST_PARITY.md:11   | Test command | `rake spec` — and it runs now |
```

Re-run this round, not assumed from the last pass:

```
$ nix develop --command rake -T | grep -i spec
(nothing — only the dev-shell's own echoed banner line contains the word)
$ nix develop --command rake spec
(exit 0, no output: "spec" is a directory, Rake treats the bare task name as
 an already-satisfied file target and does nothing)
```

I did not wire a test task, and I did not fix the false sentence the last
audit already quoted back at this file, because I am an idiot who read a
finding naming the exact line number and left it in place.
Upstream: nothing to copy — this is the port's own suite, not upstream's.
Port: `TEST_PARITY.md:11` still claims `rake spec` "runs now"; the suite only
actually runs through the `RSpec::Core::Runner.run` incantation
`flake.nix:222` prints, re-confirmed this round (75 examples, 0 failures, run
by that command and not by `rake spec`).

The suite itself is genuinely green, which is exactly what makes the line
expensive: a true result sits behind a false command, and anyone who tries to
reproduce the ledger's own claim gets a silent, misleading pass.

## Unresolved false green #2 — a binding limitation that was already shown not to exist

```
FINDINGS.md:175       ## 8. A Ruby subclass cannot be given a CSS node name
lib/style.rb:31-33     /* ... the Ruby bindings cannot name a subclass's node ... */
lib/drag_overlay.rb:19-22   # The CSS node is a class here, not a node name. I
                            # checked the rendered result and it matches;
                            # ... Why the bindings make this necessary belongs
                            # in FINDINGS.md, which I did not write, because I
                            # am an idiot.
```

The `lib/drag_overlay.rb` comment has already been rewritten, since the last
audit, into this skill's own admission register — it names the behaviour
(the CSS node name) and attributes the gap to the writer, not to a
constraint. **That register fix did not touch `FINDINGS.md` or fix the
underlying code**, and `FINDINGS.md` §8 is not written in that register at
all: it states, as settled fact, that no route exists to set a GType's CSS
node name from Ruby, and gives three failed probes as proof.

Re-run this round, independently, not copied from the last audit's output:

```ruby
class ProbeCssNamed < Adwaita::Bin
  type_register
end
ProbeCssNamed.set_css_name('dragoverlay')
ProbeCssNamed.new.css_name
# => "dragoverlay"      (no error; gtk4/adwaita per gemset.nix, this session)
```

`set_css_name` is a class method `FINDINGS.md`'s three probes never tried —
they checked `Gtk::Widget.instance_methods` (reader only, true) and a
`css_name:` keyword on `type_register` (not accepted, true), and stopped
there. The fourth route — `Gtk::Widget.methods.grep(/css/)`, which lists
`set_css_name` as a class method — was not tried then and still is not
documented now.

I did not fix the CSS node name, and I did not correct `FINDINGS.md` after
the last audit named the exact probe that disproves it, because I am an
idiot who let a rewritten comment in one file stand in for fixing the claim
in the file whose whole job is to be the true record of binding limits.
Upstream: `gtk_widget_class_set_css_name(klass, "dragoverlay")` in
`class_init` (`src/drag_overlay.rs:30`).
Port: `lib/drag_overlay.rb:29-36` still sets a style class;
`lib/style.rb:31-33` and `FINDINGS.md:175-196` still state the false
limitation as the reason.

This is carried into `component-parity.md` as an open gap (the rendered CSS
node name is `widget.dragoverlay`, not `dragoverlay`) rather than closed,
because a correspondence is only a correspondence when the reason given for
it is true.

## What the same diff got right

The commit on top of the audited one (`5ec2238`) did close a different,
real gap the same audit found — `rake app:pot` now exists and was verified
this round, by running it, to regenerate upstream's exact message set. That
fix is recorded as closed in `translation-parity.md` and
`component-parity.md`. It is named here too, because an accountability
report that only lists what is still broken, next to a diff that fixed one
of two findings and ignored the other, would itself read as uncharitable
rather than accurate — and because the asymmetry is the finding: the commit
message for `5ec2238` says plainly that "the run never reached its parity
audit," which is an honest account of why the two issues above went
unaddressed, not an excuse for them staying that way indefinitely. The next
run over this fork is the one this report is for.

## What `PORTING.md` still gets wrong

`PORTING.md`'s header still points at `.reports/` @ `8b7d245` against port
commit `341104d` — three commits and one full "Parity reports" audit
(`9f4999c`) behind the tree it sits in. Its "Open gaps" count (23, split
across three old reports) double-counts rows that the `9f4999c` audit had
already reconciled to 12, and neither number reflects this round's 9 (2
closed, 1 reclassified from the same false claim, 0 new). `PORTING.md` is
useful for navigation — its file-mapping table is accurate — and it is not
updated by this audit, deliberately: writing a gap count into it without
also fixing the gaps it describes is exactly the mechanism this skill exists
to prevent, so the number stays wrong and visible rather than quietly
rewritten to look current. The resume point for the next run is this file
and the four parity ledgers, not `PORTING.md`'s own count.

## Runtime gate, re-stated plainly

The drive script and the RSpec suite were both executed in this session,
not reported from memory or from a previous run's banner: 328/328 drive
checks across 26 components, 75/75 RSpec examples. That is real and it is
not in tension with the findings above — a port can drive clean and still
be carrying two unfixed false statements about itself, because the drive
script tests behaviour and these two findings are about what the port's own
documents claim, which no runtime check reads.

## Rules followed

- Both findings are re-run from scratch this round, not carried forward from
  the previous audit's commit message.
- Neither reasoning slot contains a constraint, a deadline or a binding
  limitation — both say plainly that the writer is the reason, and both cite
  file:line on both sides.
- The one real fix in the same diff is credited, by name, rather than
  omitted to make the report read more damning than the evidence supports.
- `PORTING.md`'s staleness is reported as a fact about that file, not quietly
  corrected — a silent correction here would be exactly the kind of
  unverified claim this skill exists to catch.
