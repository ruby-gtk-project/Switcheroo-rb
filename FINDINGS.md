# Findings — Ruby GTK4/Libadwaita binding defects

Every entry here is something the Ruby bindings cannot do that upstream's Rust
does, **verified in this repository** under `nix develop` with ruby-gnome
4.3.9, GTK 4.22.4 and libadwaita, with the error it raises quoted. A finding is
a reason a gap is *expensive*, never a reason it is closed; each one names what
the user loses and what the port does instead.

Anything I have not run is marked **unverified** and says so.

How these were driven: this machine has no X11 or Wayland display, and
`require "adwaita"` raises `Gtk::InitError` without one. GTK ships
`gtk4-broadwayd`, a display server that needs no graphics hardware, so the
checks below were run against it:

```sh
gtk4-broadwayd :5 &
GDK_BACKEND=broadway BROADWAY_DISPLAY=:5 ruby <probe>
```

`spec/support/gtk_session.rb` does the same thing for the test suite.

---

## 1. `Gtk::Accessible#update_property` cannot be called

```
NotImplementedError: TODO: in Ruby -> GIArgument(array/C)[interface(enum)](GtkAccessibleProperty)
  gobject-introspection-4.3.9/lib/gobject-introspection/loader.rb:722
```

`gtk_accessible_update_property_value` is marked introspectable in
`Gtk-4.0.gir` and is exposed as `update_property(n_properties, properties,
values)`, but ruby-gobject-introspection has no marshaller for a C array of
enum values, so the call cannot be made at all.

**What the user loses.** Upstream refreshes the colour button's accessible
`Label` property after every pick (`src/window.rs:525-530`, msgid
`New transparency layer color: {}`). The port cannot write that property.

**What the port does instead.** `lib/convert_page.rb` connects `notify::rgba`
and calls `gtk_accessible_announce` on the same child with the same msgid, so
a screen-reader user is told the colour as an announcement rather than as a
label. That is a correspondence, not parity, and it is recorded as such in
`COMPONENT_PARITY.md`.

## 2. `Gtk::AccessibleList.new_from_array` is not bound

```
NoMethodError: undefined method 'new_from_array' for class Gtk::AccessibleList
```

The constructor is in the typelib (`new_from_array(accessibles,
n_accessibles)`) but is not reachable from Ruby, and `update_relation` would
fail at finding 1 in any case. A reference-valued accessible relation
therefore cannot be written at runtime.

**What the port does instead.** `GtkBuilder` can attach an `<accessibility>`
block to the widgets it creates, including `<relation name="labelled-by">`,
and that route works. `lib/convert_page.rb` builds the quality row, its
adjustment and its scale from one builder fragment so the `labelled-by`
relation of `window.blp:155-159` is set, and builds the resize-unit dropdown
from another so the accessible label of `window.blp:243-247` is set. The
translated strings are looked up first and escaped into the markup, because
GtkBuilder's own `translatable="yes"` support goes through GLib's gettext,
which is finding 3.

## 3. ruby-glib2 exposes no gettext entry points

```ruby
require "gio2"
GLib.respond_to?(:bindtextdomain)  # => false
```

So `GLib.bindtextdomain` / `GLib.textdomain`, which upstream's `src/main.rs`
calls, do not exist here, and neither does GtkBuilder's translation-domain
path into them.

**What the port does instead.** `lib/translations.rb` binds the same
`switcheroo` domain through the `gettext` gem, which reads the same compiled
`<lang>/LC_MESSAGES/switcheroo.mo` catalogues. Verified end to end: with
`po/de.po` compiled and the locale set to `de`, `_("Quality")` returns
`Qualität` and `p_("shortcut window", "General")` returns `Allgemein`.

## 4. `Gio::Settings` keyword and constructor shapes

Not defects, but three shapes that cannot be guessed and cost a run each:

- `Gio::Settings.new(settings_schema: schema, …)` is rejected. The accepted
  keyword is `schema:`; the binding prints the full list of valid
  combinations in the error.
- `Gio::SettingsSchemaSource.new(directory, parent, trusted)` takes positional
  arguments and works; passing `nil` for the directory is what produced the
  "wrong arguments" error, not the positional form.
- There is no `Gio::MemorySettingsBackend` class. The bound form is the module
  function `Gio.memory_settings_backend_new`, which is what the specs use to
  keep themselves out of the user's dconf.

## 5. `Gtk::IconTheme.for_display` does not exist — and this was a live bug

```
NoMethodError: undefined method 'for_display' for class Gtk::IconTheme
  lib/application.rb:165
```

The bound name is `get_for_display(display)`. The port called `for_display`,
so `add_icon_search_path` raised on every startup — which meant the nine icons
the app ships were never findable, in every run the port has ever had.
`.reports/component-parity.md` records that row as "parity" because it was read
and not run. It is fixed, and it is the clearest argument in this file for
driving the app rather than reading it.

## 6. `Adwaita::Application` is **not** broken

The previous round asserted, in a code comment, that the bindings' Adwaita
application is unusable, and built the app on `Gtk::Application` with a bare
`Adwaita.init`. That was never checked. It is checked now:

```
Adwaita::Application.new('…Probe', :non_unique)  # => #<Adwaita::Application>
app.register                                     # => ok
Adwaita::ApplicationWindow.new(app)              # => #<Adwaita::ApplicationWindow>
app.style_manager                                # => #<Adwaita::StyleManager>
```

`lib/application.rb` is an `Adwaita::Application` now, which is what upstream
subclasses. The project's own `ruby-gtk` skill still lists both
`Adwaita::Application` and `Adwaita::ApplicationWindow` as broken; on
ruby-gnome 4.3.9 with GTK 4.22.4 they are not, and the skill's quirks
reference is out of date on this point.

## 7. Widget vfunc overrides — **unverified**

Upstream's `ImageThumbnail` overrides `measure()` and `size_allocate()`
(`src/widgets/image_thumbnail.rs:120-131`). I have **not** established whether
ruby-gnome can override a `Gtk::Widget` vfunc from a Ruby subclass; I did not
try. The port expresses upstream's measure as a size request of 150 on the
width with the height left natural, which produces the same tile geometry, and
does not reproduce `size_allocate()` at all. Until someone runs the
experiment, this is a gap with an untested excuse attached, and it is listed as
a gap in `COMPONENT_PARITY.md`.

## 8. CSS node name on a subclass — **unverified**

Upstream sets the widget's CSS node name to `dragoverlay` in `class_init`
(`src/drag_overlay.rs:30`). I have **not** established that the bindings cannot
do this. The port adds a `dragoverlay` style class instead and `lib/style.rb`
matches both `dragoverlay` and `.dragoverlay` with upstream's rule body, so the
rendered result is the same; the claim that the bindings leave no other way is
untested.

## 9. Screenshots under broadway go stale — a harness limitation

`test/drive_main_window.rb` captures the window correctly on the first frames,
but a shot taken after a `Gtk::Stack` crossfade shows the previous page even
though `visible_child_name` has already changed. No browser is attached to
`gtk4-broadwayd`, so GTK has no reason to produce new frames. This is a
property of the headless harness, not of the port; checks on widget state are
reliable, later screenshots are not.

---

## Reported upstream

Nothing yet. One suspected upstream bug is owed a report and has not had one:

> **`output-format` is stored as an index into a list that is not the schema's
> enum.** `save_selected_output()` writes
> `settings.set_enum("output-format", FileType::output_formats().position(…))`
> (`src/window.rs:2127`), where `output_formats()` is alphabetical —
> `[Avif, Bmp, Dds, Gif, Heic, Heif, Ico, Jpg, Jxl, Pdf, Png, Tiff, Webp]` —
> while `data/io.gitlab.adhami3310.Converter.gschema.xml.in` declares
> `Png=0, Jpg=1, Webp=2, Heif=3, …`. The two orderings do not agree, so the
> enum nick stored in dconf does not name the format the user chose, and a
> fresh profile whose default is `'Jpg'` (value 1) starts on BMP. The same
> shape is in `save_selected_compression()`, where `[Zip, Directory]` happens
> to agree with `Zip=0, Dir=1`, so it is harmless there.
>
> The port **reproduces this exactly** rather than correcting it, because the
> stored bytes are what an upgrading user's dconf already holds; the previous
> round diverged silently and called the divergence a fix. Filing this is
> outstanding work and is named in `PORTING.md`.
