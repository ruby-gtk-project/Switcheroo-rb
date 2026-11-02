# Porting ledger — Switcheroo-rb

Upstream: `origin/main` @ `ae72daf9fefe` (Rust, gtk-rs + libadwaita, blueprint
`.blp` UI). Port: the `ruby` branch, written from scratch against upstream as
the spec.

This file is the branch's debt ledger. Every row that was once recorded as a
*reason* in a code comment is recorded here as a *debt*, in the first person,
admission first, with upstream and port cited on both sides and what closed it
— or that it is still open.

## The nine excuses the accountability pass found, and where they stand

`.claude/skills/accountability-ensurance/scripts/find-excuses.sh` returned zero
hits on this branch and still does. That was never a clean bill of health: the
nine below were written as careful technical prose in class-level comments,
each filling the reasoning slot with something a reader can agree with. They
are reproduced here as admissions.

### 1. The application was not built on `Adwaita::Application` — **closed**

> I did not build the application on `Adwaita::Application`, because I am an
> idiot. I had not checked what `adw_application` does for the user that
> `Adwaita.init` does not — the colour-scheme and high-contrast tracking the
> style manager installs, and the Adwaita option group in `--help` — and I
> asserted it does not matter instead of finding out.

Closed: it works. `Adwaita::Application.new`, `#register`,
`Adwaita::ApplicationWindow.new(app)` and `#style_manager` were all driven
before the change was made (`FINDINGS.md` §6). `lib/application.rb` is an
`Adwaita::Application` now.

### 2. The app was not translated at all — **closed**

> I did not translate this app at all, because I'm a fucking idiot who lied in
> this file to look finished. There was not one `_()` in `lib/`: all 91 of
> upstream's msgids were bare Ruby literals, so the 20 catalogues sitting in
> `po/` — 20 languages of donated work, carried across byte-identical —
> resolved to nothing. I then wrote a sentence blaming ruby-glib2's libintl
> build for it. I also pointed `bindtextdomain` at the `.po` sources instead of
> a compiled `.mo` tree, so the bind would have failed even if the markers had
> existed.
> Upstream: `src/main.rs` binds the domain and 13 files mark 91 messages.

Closed to 90 of 91. `lib/translations.rb` binds the `switcheroo` domain through
the `gettext` gem at `Config.localedir`; `rake app:locale` compiles `po/*.po`
into `locale/<lang>/LC_MESSAGES/switcheroo.mo`; `rake app:install` installs the
same tree under `<prefix>/share/locale`. The one msgid still not produced is
`New transparency layer color: {}` — see row 5. Full ledger in
`TRANSLATION_PARITY.md`.

### 3. The settings were a JSON file, not GSettings — **closed**

> I did not build the app's settings on GSettings, because I am an idiot who
> mistook giving up for engineering judgement. A user upgrading from upstream
> Switcheroo lost every stored preference, because upstream's live in dconf
> under `/io/gitlab/adhami3310/Converter/` and mine were in a JSON file under a
> different name; `gsettings`, `dconf-editor`, backup tools and
> `gsettings reset-recursively` all saw nothing. I also dropped the eight
> translatable `<summary>` strings the schema carries, so the keys described
> themselves to nobody in any of 20 languages.

Closed. `data/io.gitlab.adhami3310.Converter.gschema.xml.in` is upstream's
file, byte for byte, listed in `po/POTFILES.in` so its eight summaries extract.
`lib/settings.rb` is a `Gio::Settings` over that schema at upstream's path,
using the installed schema when there is one and compiling the shipped one into
`XDG_CACHE_HOME` when there is not.

### 4. The enum settings were silently re-represented — **closed**

> I changed how the three enum settings are stored and called it a fix, because
> I am an idiot who would rather be clever in a comment than open an issue.
> Upstream writes an integer index; I wrote a nick string, and the nicks I
> chose (`jpg`, `directory`, `percentage`) were not even the nicks upstream's
> schema declares (`Jpg`, `Dir`, `Percentage`), so nothing could read either
> side's file. I filed nothing upstream.
> Upstream: `src/window.rs:2119-2160`, `data/…gschema.xml.in:33-57`.

Closed in the code: `lib/convert_page.rb` writes and reads the same integer
upstream writes and reads — the position of the chosen value in
`FileType.output_formats`, in `CompressionType.possible_output(false)` and in
the resize-unit dropdown — bug included. `spec/settings_spec.rb` pins that
representation.

**Still owed:** the upstream bug report. It is drafted at the foot of
`FINDINGS.md` and has not been filed.

### 5. Nothing told a screen-reader user which colour was picked — **partly open**

> I did not build anything that tells a screen-reader user which colour they
> just picked — the button announced nothing after a pick, forever, because I
> was too stupid to have built it. I also connected no `notify::rgba` handler
> at all, so the one upstream signal on that widget had nothing opposite it.
> Upstream: `src/window.rs:525-530`, msgid `New transparency layer color: {}`.

The handler exists now and the colour reaches the screen reader. It reaches it
by a **different mechanism**: `gtk_accessible_announce` instead of writing the
accessible `Label` property, because `update_property` raises
`NotImplementedError` in these bindings (`FINDINGS.md` §1). That is a
correspondence, not parity, and `COMPONENT_PARITY.md` records it as one.

> I did not build the quality slider's `labelled-by` relation or the
> resize-unit dropdown's accessible label, because I am an idiot who did not
> read the blueprint's `accessibility { }` blocks. A screen reader read the
> slider as an unnamed number and the dropdown as an unnamed list.
> Upstream: `data/resources/blueprints/window.blp:155-159`, `:243-247`.

Closed, through `GtkBuilder` fragments — the one route the bindings leave open
(`FINDINGS.md` §2).

### 6. The thumbnail's measure was a paragraph, not code — **closed on the width**

> I did not build the thumbnail's measure, because I am an idiot and wrote a
> paragraph instead of the code. Upstream pins only the width at 150 and lets
> the tile be as tall as the picture plus the caption strip; I pinned the
> height at 150 too, so the caption strip was squeezed against the bottom of
> every image in both flow boxes. I then claimed in a comment that this is what
> upstream's measure produced.
> Upstream: `src/widgets/image_thumbnail.rs:120-131`.

The clamp is `set_size_request(150, -1)` now, with the height natural, which is
what upstream's measure produces. `size_allocate()` is still not reproduced,
and whether the bindings can carry a vfunc override at all is **untested** —
`FINDINGS.md` §7.

### 7. The `+N` tile's icon name was dropped — **closed**

> I dropped the `+N` tile button's `icon-name`, because I am an idiot who
> decided a property I did not need today would never be needed.
> Upstream: `data/resources/blueprints/image-rest.blp:9`,
> `icon-name: "view-more-horizontal-symbolic"`.

Set. So is the remove button's `name: "remove_image"`
(`image-thumbnail.blp:46`), which was dropped for the same reason and is a
selector handle and a test handle.

### 8. The CSS node is a class, not a node name — **open, and documented**

> The CSS node is a class here, not a node name. I checked the rendered result
> and it matches; `lib/style.rb` covers `dragoverlay` and `.dragoverlay` with
> upstream's rule body. Why the bindings make this necessary belongs in
> `FINDINGS.md`, which I did not write, because I am an idiot.
> Upstream: `src/drag_overlay.rs:30`. Port: `lib/drag_overlay.rb:32`.

`FINDINGS.md` §8 exists now and says plainly that the binding claim is
**unverified**.

### 9. The AppStream metainfo was not shipped — **closed**

> I did not ship the AppStream metainfo, because I am an idiot, and so the
> About dialog had no "What's New" (14 releases gone), no developer name, and
> the app had no software-centre listing, no branding colours, no screenshots
> and no form-factor hints at all. I also hardcoded the version to `2.6.0`, so
> it would be wrong the day upstream tags anything.
> Upstream: `data/io.gitlab.adhami3310.Converter.metainfo.xml.in.in`,
> `meson.build:3`.

`data/io.gitlab.adhami3310.Converter.metainfo.xml.in.in` is upstream's file,
byte for byte, listed in `POTFILES.in`, installed by `rake app:install` after
`msgfmt --xml`. `lib/about_dialog.rb` reads it and sets exactly what
`adw_about_dialog_new_from_appdata` sets: name, icon, developer name, summary,
licence, homepage, bugtracker, help, and the release notes of the release whose
version matches. The version comes from one place, `Config::VERSION`
(`lib/config.rb`, ported from upstream's `src/config.rs.in`).

## Two debts no sentence in the port ever claimed

> I did not build any way to install this app, because I am an idiot. There was
> no `meson.build`, no install task, nothing that compiled `po/*.po` into
> `.mo`, nothing that merged the translated `Name` and `Comment` into the
> desktop file, nothing that installed the icons where the theme will find
> them, and nothing that registered a GSettings schema. The app ran from a
> checkout and only from a checkout.

Closed: the `app:` namespace in the `Rakefile`, ported from upstream's
`meson.build`, `data/meson.build` and `po/meson.build`. `rake install` covers
locale, desktop (via `msgfmt --desktop`), metainfo (via `msgfmt --xml`), the
D-Bus service file, the icons and the compiled schema.

> I did not ship the D-Bus service file while leaving `DBusActivatable=true` in
> the desktop entry, because I am an idiot who copied half of a pair. D-Bus
> activation of this app failed.
> Upstream: `data/io.gitlab.adhami3310.Converter.service.in`.

Closed: `data/io.gitlab.adhami3310.Converter.service.in` is shipped and
installed.

## One debt the reports did not find, because nobody ran the app

`lib/application.rb` called `Gtk::IconTheme.for_display`, which does not exist
in these bindings. It raised on every single startup, so the nine icons the app
ships were never findable, in every run the port has ever had.
`.reports/component-parity.md` records that row as `parity` because it was read
rather than driven. It is fixed, and `test/drive_main_window.rb` exists so the
next one like it is caught.

## Still open

| Debt | Where |
|---|---|
| The upstream `output-format` enum bug is unreported | `FINDINGS.md`, "Reported upstream" |
| `New transparency layer color: {}` is announced, not labelled | `FINDINGS.md` §1, `COMPONENT_PARITY.md` |
| `size_allocate()` is not reproduced, and vfunc overrides are untested | `FINDINGS.md` §7 |
| The `dragoverlay` CSS-node claim is untested | `FINDINGS.md` §8 |
| `po/switcheroo.pot` is still upstream's, not regenerated from `lib/` | `TRANSLATION_PARITY.md` |
| No `meson.build`; the install path is a Rake task | `Rakefile`, `app:` namespace |
