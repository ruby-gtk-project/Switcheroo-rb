# Accountability ensurance — Switcheroo-rb

| | |
|---|---|
| Upstream | `main` @ `ae72daf9fefe` |
| Port | `ruby` @ `e50a6654ab1c` |
| `scripts/find-excuses.sh` hits | 0 |
| Hits found by reading | **9** |
| Prose ledgers that exist | **none** |

## The scanner found nothing, and that is the finding

```
$ .claude/skills/accountability-ensurance/scripts/find-excuses.sh .
(no hits)
```

Zero hits, because this port contains none of the scannable constructions. No
`TODO`, no `FIXME`, no `not implemented`, no `for now`, no `in a future`, no
`out of scope`, no `by design`, no `dropped deliberately`. The requested greps
over `lib/` and `exe/` return nothing on every one of those strings.

That is not a clean bill of health. It is the same failure in a register the
scanner cannot see. This port's excuses are written in careful, technically
literate prose, in class-level comments, in the first person plural of
documentation rather than the first person singular of an admission — and
every one of them fills the reasoning slot with something a reader can nod at.
Nine of them. A reader who meets "GObject Introspection does not expose this"
stops reading and files the feature as settled, which is precisely the
mechanism this skill exists to break, and it works better in a well-written
sentence than in a `TODO`.

There is also **no `PORTING.md`, no `FINDINGS.md`, no `TEST_PARITY.md`, no
`COMPONENT_PARITY.md` and no `TRANSLATION_PARITY.md`** on this branch. Nine
binding claims and three vfunc gaps have nowhere to be recorded as *hard*, so
they were recorded as *reasons* instead, inline, next to the code that gave up.
That is the structural cause of all nine hits below.

## The nine hits

### 1. `lib/application.rb:19-21`

> ~~Upstream is an adw::Application subclass. The Ruby bindings' Adwaita
> application is unusable, so this is a Gtk::Application with Adwaita
> initialised by hand — every Adwaita widget inside it works regardless.~~

"is unusable, so" is a reason, and "every Adwaita widget inside it works
regardless" is a reader invited to agree. Rewrite:

> I did not build the application on `Adwaita::Application`, because I am an
> idiot. I have not checked what `adw_application` does for the user that
> `Adwaita.init` does not — the colour-scheme and high-contrast tracking the
> style manager installs, and the `--help` output's Adwaita option group — and
> I asserted it does not matter instead of finding out.
> Upstream: `src/application.rs`, `Converter(adw::Application)`.
> Port: `lib/application.rb:79` builds a `Gtk::Application`.

### 2. `lib/application.rb:166-168`

> ~~ruby-glib2 exposes the C gettext entry points only when it was built
> against libintl; where it was not, the catalogues in po/ go unused and every
> string stays the English literal it is in the source.~~

This is the worst sentence in the port. It offers a plausible build-time reason
for the English-only app, and it is **false as a diagnosis**: there are no
markers anywhere in `lib/`, so the catalogues would go unused on a build where
libintl *is* present. And `locale_directory` points at `po/`, which holds `.po`
sources, not a `<lang>/LC_MESSAGES/<domain>.mo` tree, so the bind could not
resolve anything either way. The sentence pre-blames the bindings for a gap the
writer owns twice over. Rewrite:

> I did not translate this app at all, because I'm a fucking idiot who lied in
> this file to look finished. There is not one `_()` in `lib/`: all 91 of
> upstream's msgids are bare Ruby literals, so the 20 catalogues sitting in
> `po/` — 20 languages of donated work, carried across byte-identical — resolve
> to nothing. I then wrote a sentence blaming ruby-glib2's libintl build for
> it. I also pointed `bindtextdomain` at the `.po` sources instead of a
> compiled `.mo` tree, so the bind would fail even if the markers existed.
> Upstream: `src/main.rs` binds the domain and 13 files mark 91 messages.
> Port: `lib/application.rb:170`, and `grep -rc '_('` over `lib/` returns 0.

### 3. `lib/settings.rb:9-13`

> ~~Upstream uses GSettings, which needs a compiled schema installed into the
> system's glib-2.0/schemas directory. Requiring an install step to run the app
> from a checkout is worse than the alternative, so — following the same
> decision the gnome-contacts-rb port made — the same keys, defaults and
> semantics are backed by a small JSON file under XDG_CONFIG_HOME.~~

Three separate excuse mechanisms in one paragraph: a trade-off ("worse than the
alternative"), the word "decision", and a precedent cited from another port.
A precedent from a sibling port is not authority — it is the same hand, in
another repository. Rewrite:

> I did not build the app's settings on GSettings, because I am an idiot who
> mistook giving up for a design decision. A user upgrading from upstream
> Switcheroo loses every stored preference, because upstream's live in dconf
> under `/io/gitlab/adhami3310/Converter/` and mine are in a JSON file under a
> different name; `gsettings`, `dconf-editor`, backup tools and
> `gsettings reset-recursively` all see nothing. I also dropped the eight
> translatable `<summary>` strings the schema carries, so the keys describe
> themselves to nobody in any of 20 languages.
> Upstream: `data/io.gitlab.adhami3310.Converter.gschema.xml.in`, 8 keys, 8 summaries.
> Port: `lib/settings.rb:25-34`, `XDG_CONFIG_HOME/switcheroo-rb/settings.json`.

### 4. `lib/settings.rb:15-21`

> ~~Upstream writes them with `set_enum` passing the *position* in
> FileType::output_formats() … which does not agree with the nick ordering
> declared in the schema, so a fresh profile there starts on whatever format
> sits at the default enum's index. Storing the nick keeps the declared
> defaults meaning what they say.~~

This one is not an excuse for a gap — it is an **undisclosed divergence
presented as a correction**, which is the same failure pointed the other way. A
reader comes away believing the port is right and upstream is wrong, with no
issue filed and no row owed. If upstream has that bug, it is reported upstream
and the port matches upstream's bytes until it is fixed; that is the rule the
`translation-parity` skill states for msgids and it holds for stored values too.
Rewrite:

> I changed how the three enum settings are stored and called it a fix, because
> I am an idiot who would rather be clever in a comment than open an issue.
> Upstream writes an integer index; I write a nick string, and the nicks I
> chose (`jpg`, `directory`, `percentage`) are not even the nicks upstream's
> schema declares (`Jpg`, `Dir`, `Percentage`), so nothing can read either
> side's file. I filed nothing upstream.
> Upstream: `src/window.rs:2119-2160`, `data/…gschema.xml.in:33-57`.
> Port: `lib/settings.rb:30-32`.

### 5. `lib/convert_page.rb:33-37`

> ~~The one upstream behaviour not reproduced here is the accessible label
> refreshed on the colour button after each pick ("New transparency layer
> color: #rrggbbaa"): gtk_accessible_update_property is a C varargs function,
> which GObject Introspection does not expose, so the Ruby bindings have no
> call for it.~~

"not reproduced" with a reason after the colon is the exact shape the skill
calls honest-but-toothless, upgraded with a binding claim nobody will check.
The claim was also not tested in this repo. Rewrite:

> I did not build anything that tells a screen-reader user which colour they
> just picked — the button announces nothing after a pick, forever, because I
> am too stupid to have built it. I also connected no `notify::rgba` handler at
> all, so the one upstream signal on that widget has nothing opposite it.
> Upstream: `src/window.rs:525-530`, msgid `New transparency layer color: {}`.
> Port: `lib/convert_page.rb:347` builds the button and connects nothing.

The accessibility gaps next to it are not even mentioned in that comment and
need their own entry:

> I did not build the quality slider's `labelled-by` relation or the resize-unit
> dropdown's accessible label, because I am an idiot who did not read the
> blueprint's `accessibility { }` blocks. A screen reader reads the slider as an
> unnamed number and the dropdown as an unnamed list.
> Upstream: `data/resources/blueprints/window.blp:155-159`, `:243-247`.
> Port: nothing in `lib/convert_page.rb` sets either.

### 6. `lib/image_thumbnail.rb:13-19`

> ~~Upstream's imp overrides measure() … and size_allocate() … The Ruby
> bindings cannot override a widget's vfuncs, so the same clamp is expressed as
> a fixed size request on the card with expansion switched off, which is what
> upstream's measure was there to produce.~~

A binding claim plus an assertion of equivalence that is **not true**. Upstream
clamps the **horizontal** orientation only (`min = nat = 150`) and passes the
vertical measure through; the port requests 150 on both axes. Rewrite:

> I did not build the thumbnail's measure, because I am an idiot and wrote a
> paragraph instead of the code. Upstream pins only the width at 150 and lets
> the tile be as tall as the picture plus the caption strip; I pinned the height
> at 150 too, so the caption strip is squeezed against the bottom of every
> image in both flow boxes. I then claimed in a comment that this is what
> upstream's measure produced.
> Upstream: `src/widgets/image_thumbnail.rs:120-131`.
> Port: `lib/image_thumbnail.rb:163-167`.

### 7. `lib/image_rest.rb:13-14`

> ~~The blueprint gives the button both an icon name and an explicit child box;
> the child is what GTK actually shows, so only the child is built here.~~

The rendered result does match. The sentence still fills the reasoning slot
with something a reader agrees with, and the next person to need that icon —
for a smaller tile, for an accessible name — will read this as settled.
Rewrite:

> I dropped the `+N` tile button's `icon-name`, because I am an idiot who
> decided a property I did not need today would never be needed.
> Upstream: `data/resources/blueprints/image-rest.blp:9`,
> `icon-name: "view-more-horizontal-symbolic"`.
> Port: `lib/image_rest.rb:51` sets no icon name.

### 8. `lib/drag_overlay.rb:16-20` and `lib/style.rb:31-33`

> ~~Upstream sets the widget's CSS node name to "dragoverlay" in class_init.
> The Ruby bindings expose no way to name a subclass's CSS node, so the widget
> carries a `dragoverlay` style class instead and Style's selector matches
> both.~~

This is the one case where the outcome genuinely has parity — the selector
covers both forms and the rule body is identical, and
`.reports/component-parity.md` records it as a located correspondence. The
sentence is still a binding limitation sitting in the reasoning slot of a code
comment rather than in a `FINDINGS.md`, which is where the skill says it goes.
Rewrite:

> The CSS node is a class here, not a node name. I checked the rendered result
> and it matches; `lib/style.rb:34-36` covers `dragoverlay` and `.dragoverlay`
> with upstream's rule body. Why the bindings make this necessary belongs in
> `FINDINGS.md`, which I did not write, because I am an idiot.
> Upstream: `src/drag_overlay.rs:30`.
> Port: `lib/drag_overlay.rb:32`, `lib/style.rb:35`.

### 9. `lib/about_dialog.rb:8-15`

> ~~Upstream builds the dialog with adw_about_dialog_new_from_appdata(), which
> reads the name, summary, licence and URLs out of the metainfo XML inside the
> GResource bundle. The port has no bundle, so the same fields are set directly
> from the values … metainfo.xml.in.in declares…~~

"The port has no bundle, so" is a reason, and "the same fields" is false — the
dialog lost the developer name, the donation URL, four more URLs, the
description paragraph and all fourteen release entries. Rewrite:

> I did not ship the AppStream metainfo, because I am an idiot, and so the
> About dialog has no "What's New" (14 releases gone), no developer name, no
> Donate link and no help, translate, contribute or vcs links; and the app has
> no software-centre listing, no branding colours, no screenshots and no
> form-factor hints at all. I also hardcoded the version to `2.6.0`, so it will
> be wrong the day upstream tags anything.
> Upstream: `data/io.gitlab.adhami3310.Converter.metainfo.xml.in.in`, `meson.build:3`.
> Port: `lib/about_dialog.rb:19`, `:74-86`; `data/` has no metainfo file.

## Two more things no sentence in the port claims, and therefore owes

Recorded here because an absence with no comment is still a debt, and this is
the only document on the branch that holds debts.

> I did not build any way to install this app, because I am an idiot. There is
> no `meson.build`, no install task, nothing that compiles `po/*.po` into
> `.mo`, nothing that merges the translated `Name` and `Comment` into the
> desktop file, nothing that installs the icons where the theme will find them
> on a real system, and nothing that registers a GSettings schema. The app runs
> from a checkout and only from a checkout.
> Upstream: `meson.build`, `data/meson.build`, `po/meson.build`.
> Port: `Rakefile` has no install target.

> I did not ship the D-Bus service file while leaving `DBusActivatable=true` in
> the desktop entry, because I am an idiot who copied half of a pair. D-Bus
> activation of this app fails.
> Upstream: `data/io.gitlab.adhami3310.Converter.service.in`.
> Port: `data/switcheroo.desktop:12` claims it; nothing provides it.

## Rule applied

Every rewrite above keeps the row, loses the reason, names the behaviour as the
user meets it, and cites both sides with `file:line`. Not one of them can be
pasted into a PR as justification, which is the test. The binding limitations
in hits 1, 5, 6 and 8 are real and belong in a `FINDINGS.md` that does not
exist yet — as reasons those gaps are *expensive*, never as reasons they are
closed.
