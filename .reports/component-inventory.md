# Switcheroo — upstream component inventory

Survey for the full-parity port. Upstream is **Rust (gtk-rs + libadwaita)** on
`origin/main`; app id `io.gitlab.adhami3310.Converter`, user-visible name
**Switcheroo** — a batch image converter that shells out to ImageMagick to
convert, resize, re-quality, strip metadata and re-background one or many
dropped/opened images, optionally bundling the results into a ZIP, a directory
or a single multi-page PDF.

Upstream is three blueprint files plus eleven Rust modules. The widget tree is
almost entirely in `data/resources/blueprints/window.blp`; `src/window.rs`
(2281 lines) is its callbacks, actions, dialogs and state machine. Per the
`component-identification` skill a component is the *set* of files, so each
section below unions the `.blp` with the `.rs` that drives it.

The `ruby` branch carries 28 flat `lib/*.rb` files (4715 lines). Every
user-facing component below is **present**; what remains are the behavioural
divergences recorded in `.reports/component-parity.md`, not missing
components. Read this file for *what exists and where*; read
`.reports/component-identification.md` for the per-widget facet detail (CSS
classes, signals, counts) and `.reports/component-parity.md` for the gap list.

Scope note: `lib/switcheroo.rb`, `lib/switcheroo/application.rb` and
`lib/switcheroo/rb/version.rb` are gem-packaging shims, not components —
`Switcheroo::Application` is an alias for the top-level `App`.

---

## Component map

| # | Upstream file(s) | → `lib/*.rb` | Kind | Present |
|---:|---|---|---|:---:|
| 1 | `src/main.rs`, `src/application.rs` | `lib/application.rb`, `lib/main.rb` | application object | yes |
| 2 | `src/config.rs.in` | `lib/config.rb` | build constants | yes |
| 3 | `blueprints/window.blp` (`template $AppWindow`) + `src/window.rs` | `lib/app_window.rb` | main window | yes |
| 4 | `window.blp` stack page `stack_welcome_page` | `lib/welcome_page.rb` | empty state | yes |
| 5 | `window.blp` stack pages `stack_loading` | `lib/loading_page.rb` | loading state | yes |
| 6 | `window.blp` stack page `stack_invalid_image` | `lib/invalid_image_page.rb` | error state | yes |
| 7 | `window.blp` stack page `stack_convert` + `src/window.rs` | `lib/convert_page.rb` | options page | yes |
| 8 | `window.blp` stack page `stack_converting` + `src/window.rs` | `lib/converting_page.rb` | progress page | yes |
| 9 | `window.blp` navigation page `all_images` | `lib/all_images_page.rb` | navigation page | yes |
| 10 | `window.blp` `Adw.ShortcutsDialog help_overlay` | `lib/shortcuts_dialog.rb` | keyboard shortcuts | yes |
| 11 | `window.blp` `menu primary_menu` | `lib/primary_menu.rb` | menu model | yes |
| 12 | `src/drag_overlay.rs` | `lib/drag_overlay.rb` | drag-and-drop overlay | yes |
| 13 | `src/widgets/image_thumbnail.rs` + `blueprints/image-thumbnail.blp` | `lib/image_thumbnail.rb` | repeated tile widget | yes |
| 14 | `src/widgets/image_rest.rs` + `blueprints/image-rest.blp` | `lib/image_rest.rb` | "+N / Show All" tile | yes |
| 15 | `src/widgets/about_window.rs` | `lib/about_dialog.rb` | dialog | yes |
| 16 | `src/window.rs` `convert_failed()` | `lib/error_dialog.rb` | error dialog | yes |
| 17 | `src/window.rs` `close_dialog()` + `convert_cancel()` | `lib/stop_converting_dialog.rb` | confirmation dialog | yes |
| 18 | `src/file_chooser.rs` | `lib/file_chooser.rb` | file dialogs | yes |
| 19 | `src/filetypes.rs` | `lib/file_type.rb` | format model | yes |
| 20 | `src/input_file.rs` | `lib/input_file.rb` | model | yes |
| 21 | `src/magick.rs` | `lib/magick.rb` | backend | yes |
| 22 | `src/temp.rs` | `lib/temp_dir.rb` | backend | yes |
| 23 | `src/color.rs` | `lib/color.rb` | model | yes |
| 24 | `data/…Converter.gschema.xml.in` | `lib/settings.rb` (+ `data/…gschema.xml.in`) | persisted settings | yes |
| 25 | `data/resources/style.css` | `lib/style.rb` | stylesheet | yes |
| 26 | `src/main.rs` gettext setup + `po/` | `lib/translations.rb` (+ `po/`, `locale/`) | i18n | yes |
| 27 | `data/resources/resources.gresource.xml` + `icons/**` | `data/icons/**` | resources | yes (no bundle) |
| 28 | `data/…desktop.in.in`, `…service.in`, `…metainfo.xml.in.in` | `data/switcheroo.desktop.in`, `data/…service.in`, `data/…metainfo.xml.in.in` | shell integration | yes |

---

## 1. `src/main.rs` + `src/application.rs` + `src/config.rs.in` — the application object

Not a widget, but it owns the app id, the `HANDLES_OPEN` flag, the
`--new-window` command-line option, the `app.*` actions and every accelerator.

| Item | Detail |
|---|---|
| App id | `io.gitlab.adhami3310.Converter`, resource base `/io/gitlab/adhami3310/Converter/` |
| Flags | `gio::ApplicationFlags::HANDLES_OPEN` — shell-opened files land in `open()` |
| CLI option | `--new-window` / `-w`, "Open a new window"; a remote instance activates `app.new-window` and exits |
| Actions | `app.quit`, `app.new-window` |
| Accelerators | `app.new-window` `<Control>n`; `app.quit` `<Control>q`; `win.clear` `<Control>r`; `win.add` `<Control>o`; `win.close` `<Control>w`; `win.paste` `<Control>v`; `win.show-help-overlay` `<Control>question` |
| Startup | `gtk::Window::set_default_icon_name(APP_ID)`; gettext domain `switcheroo` |
| Multi-window | `present_main_window` builds a fresh `AppWindow` each call — genuinely multi-window |

→ `lib/application.rb` (both actions, all seven accelerators, the
`--new-window` option and the open handler) plus `lib/main.rb` for the
one-expression launcher, and `lib/config.rb` for what meson would generate.
**Present.** Note `Adwaita::Application` is broken in the Ruby bindings, so the
port uses `Gtk::Application`; a correspondence, not a gap.

## 3. `blueprints/window.blp` + `src/window.rs` — the main window

`template $AppWindow : Adw.ApplicationWindow`, 750×750 default, 300×300
minimum, title "Switcheroo". Root chain: `Box(vertical)` → `$DragOverlay` →
`Adw.ToastOverlay` → `Adw.NavigationView` with two pages (`main`,
`all_images`).

| Widget | × | CSS | Signals / behaviour |
|---|---:|---|---|
| `Adw.ApplicationWindow` | 1 | — | `close-request` → stop-converting dialog mid-run, else persists geometry to GSettings |
| `Adw.ToastOverlay` | 1 | — | hosts every toast |
| `Adw.NavigationView` | 1 | — | `push_by_tag("all_images")` |
| `Adw.NavigationPage` | 2 | — | tags `main` / `all_images` |
| `Adw.ToolbarView` | 2 | — | top bar + content |
| `Adw.HeaderBar` | 2 | — | `show-title: false` on the main page |
| `Gtk.Button` `add_button` / `other_add_button` | 2 | `flat` | `clicked` → `add_dialog`; `add_button` starts hidden and is revealed once images load |
| `Gtk.MenuButton` | 1 | — | `primary: true`, `menu-model: primary_menu` |
| `Gtk.WindowHandle` | 2 | — | drag region over the content |
| `Gtk.Stack` | 2 | — | `crossfade`; `stack` has 5 pages, `all_images_stack` 2 |

Window actions: `win.close`, `win.add`, `win.clear`, `win.show-help-overlay`,
`win.about`, `win.paste`. Toasts: "Image converted" (with an **Open** button),
"Error copied to clipboard", "Converting Cancelled", plus the file-chooser
error strings.

→ `lib/app_window.rb`. **Present** — all six window actions are installed from
`WINDOW_ACTIONS`, both header bars, both stacks and the toast overlay exist,
and the toast's Open button uses `Gtk::FileLauncher` in place of upstream's
ashpd portal request.

## 4. `stack_welcome_page` — empty state

`Adw.StatusPage` (icon `io.gitlab.adhami3310.Converter`, title "Switcheroo",
description "Drag and drop images here", `icon-dropshadow`) → `Box(vertical, 12)`
→ `Gtk.Button open_button` ("_Open Images…", `suggested-action pill`,
underline). → `lib/welcome_page.rb`. **Present**; the button names `win.add`
instead of connecting `clicked`.

## 5. `stack_loading` — loading state

An empty `Adw.StatusPage` whose only child is a 32×32 `Gtk.Spinner`. Upstream
declares it twice (`loading_spinner`, `loading_spinner_images`) so each
navigation page has its own. → `lib/loading_page.rb`, instantiated twice.
**Present.**

## 6. `stack_invalid_image` — error state

`Adw.StatusPage invalid_image`, icon `im-symbolic`, title "Could not Load
Image", description "This image could be corrupted or may use an unsupported
file format." → `lib/invalid_image_page.rb`. **Present.**

## 7. `stack_convert` — the options page

`Adw.Bin` → `Adw.Bin` → `Adw.PreferencesPage` with four groups.

| Widget | × | CSS | Signals / behaviour |
|---|---:|---|---|
| `Gtk.FlowBox image_container` | 1 | — | homogeneous, 12px gaps, selection none; holds the short thumbnail strip + `+N` tile |
| `Adw.ComboRow output_filetype` | 1 | `output-filetype-drop` | `notify::selected`; model `StringList supported_output_filetypes` |
| `Adw.ActionRow single_pdf` + `Gtk.Switch` | 1 | — | "Save as multi-page PDF"; `notify::state` |
| `Adw.ActionRow output_compression` + `Gtk.Switch` | 1 | — | "Save To ZIP" |
| `Adw.ActionRow quality_row` + `Gtk.Scale quality` | 1 | — | adjustment 1–100 step 1, `draw-value`, value right, `labelled-by: quality_row`; visible only for lossy output |
| `Adw.ActionRow bgcolor_row` + `Gtk.ColorDialogButton` | 1 | — | `notify::rgba`; `ColorDialog with-alpha`; visible only when an input has alpha |
| `Adw.ActionRow dpi_row` + `Gtk.Entry dpi_value` | 1 | — | "Pixel Density Per Inch" |
| `Adw.ActionRow resize_amount_row` | 1 | — | 4 `Gtk.Entry` (width/height × px/%), `ToggleButton link_axis` (`raised circular lock`, `chain-link-symbolic` ⇄ `chain-link-loose-symbolic`), `DropDown resize_type` (`flat unit-drop`, model `%`/`px`) |
| `Adw.ActionRow resize_filter_row` | 1 | `linked` box | `ToggleButton` ×2 — "Default", "Pixel Art" |
| `Adw.ActionRow strip_row` + `Gtk.Switch strip` | 1 | — | "Remove Metadata" |
| `Gtk.Button convert_button` | 1 | `suggested-action pill long` | `clicked` → convert |

→ `lib/convert_page.rb` (794 lines). **Present.** The quality scale and the
resize-unit dropdown are built through small `Gtk::Builder` XML snippets
because the accessibility `labelled-by` relation and the dropdown's
accessible label cannot be set from the Ruby bindings; the four resize entries
come from one shared factory method, so the textual count is lower than the
widget count.

## 8. `stack_converting` — progress page

`Adw.StatusPage` ("Converting" / "This could take a while") → `Box(vertical, 36)`
→ `Gtk.ProgressBar` (`show-text`, initial text "Loading…") + `Gtk.Button
cancel_button` ("_Cancel", `destructive-action pill`). → `lib/converting_page.rb`,
including `set_convert_progress` ("done/total") and `set_collecting_progress`.
**Present.**

## 9. `all_images` navigation page

`Adw.ToolbarView` → `Adw.HeaderBar` with `other_add_button` (`flat`) →
`Gtk.WindowHandle` → `Stack all_images_stack` with `ScrolledWindow` →
`FlowBox full_image_container` (homogeneous, max 4 per line, 16px margins,
12px gaps, selection none), plus its own loading page. →
`lib/all_images_page.rb`. **Present.**

## 10. `help_overlay` — keyboard shortcuts dialog

`Adw.ShortcutsDialog` with one `Adw.ShortcutsSection` titled
`C_("shortcut window", "General")` and six `Adw.ShortcutsItem`s: Show
Shortcuts, Quit, New Window, Clear Window, Paste From Clipboard, Add Images —
each naming an action rather than an accelerator. → `lib/shortcuts_dialog.rb`,
same six items in the same order. **Present.**

## 11. `primary_menu` — the hamburger menu model

Two sections: (`win.paste` "Paste From Clipboard", `app.new-window` "New
Window", `win.clear` "Clear Window") and (`win.show-help-overlay` "Keyboard
Shortcuts", `win.about` "About Switcheroo"). → `lib/primary_menu.rb`.
**Present.**

## 12. `src/drag_overlay.rs` — the drag-and-drop overlay

`adw::Bin` subclass, css name `dragoverlay`, holding a `Gtk.Overlay` whose
overlay child is a crossfading `Gtk.Revealer` (`can-target: false`) over an
`Adw.StatusPage` (icon `document-send-symbolic`, class
`drag-overlay-status-page`, title "Drop Here to Open"). The window hands it a
configured `Gtk.DropTarget`; the overlay reveals on `notify::current-drop`. →
`lib/drag_overlay.rb`. **Present.**

## 13. `image_thumbnail.rs` + `image-thumbnail.blp` — one image tile

`Gtk.Widget` subclass. `Box root` (`card-content`) → `Box child`
(`image-container`) → `Gtk.Overlay` → `Box(vertical)` → [`Gtk.Picture picture`
150×150 `content-fit: cover` | `Gtk.Image image` 150×150 `icon-size: large`,
exactly one visible] + `Adw.Bin` (`image-caption caption`) → `Label content`;
overlay child `Gtk.Button remove_image` (`circular image-remove osd`,
`user-trash-symbolic`, tooltip "Remove image", top-end). Repeater — one per
loaded image in both flow boxes. → `lib/image_thumbnail.rb`. **Present.**

## 14. `image_rest.rs` + `image-rest.blp` — the "+N / Show All" tile

`Gtk.FlowBoxChild` (`no-padding`, not focusable) → `Adw.Bin` → `Gtk.Button
image` (`image-container card image-rest-button`, 150×150,
`view-more-horizontal-symbolic`, tooltip "Show {} more images") → `Box(vertical)`
→ `Label content` (`large_number`, text "+{}") + `Label` ("Show All").
`clicked` pushes the all-images page. → `lib/image_rest.rb`. **Present** (the
port drops the button's `icon-name`, which the blueprint also overrides with a
child box).

## 15. `src/widgets/about_window.rs` — the About dialog

`Adw.AboutDialog::from_appdata` over the bundled metainfo, plus 1 developer,
`translator-credits`, 2 other apps (Impression / "Create bootable drives",
Footage / "Polish your videos"), 2 acknowledgement sections ("Code and Design
Borrowed from" ×7, "Sample Image from" ×1) and a legal section (ImageMagick,
MIT/X11). → `lib/about_dialog.rb`, which parses the metainfo with REXML
because the Ruby bindings have no `from_appdata`. **Present**; the two other
apps' icons are not carried, so those rows render without art.

## 16. `src/window.rs` `convert_failed()` — the "Error While Processing" alert

`Adw.AlertDialog` (heading "Error While Processing") with an extra child
`Gtk.ScrolledWindow` (`card`, min 200 / max 400 content height) holding a
`Gtk.Label` (`monospace`, 12px margins, xalign/yalign 0, wrap word-char) of
the child process's stderr. Responses `ok` → "_Close" and `copy` → "_Copy to
Clipboard" (suggested), which copies and toasts "Error copied to clipboard".
→ `lib/error_dialog.rb`. **Present.**

## 17. `src/window.rs` `close_dialog()` / `convert_cancel()` — "Stop converting?"

`Adw.AlertDialog`, heading "Stop converting?", body "You will lose all
progress.", responses `cancel` → "_Cancel" and `stop` → "_Stop"
(destructive). Upstream builds it twice, identically; the port factors it into
one class the caller parameterises — a correspondence, not a 2→1 gap. →
`lib/stop_converting_dialog.rb`. **Present.**

## 18. `src/file_chooser.rs` — the three file dialogs

`Gtk.FileDialog` ×3: `open_multiple` (accept "_Select Images", filter named
"Images" over every input mime type), `save` (filter on the chosen output
mime, initial name and folder, with the "Unspecified filetype" / "Unknown
filetype" / "Used the wrong filetype" error paths) and `select_folder` (loose
files). Plus the "Unsupported filetype" error from `load_files`. →
`lib/file_chooser.rb`. **Present.**

## 19–23. The non-widget units

| Upstream | → | Content |
|---|---|---|
| `src/filetypes.rs` | `lib/file_type.rb` | 15 input formats, 13 output formats, 2 compression types, 6 capability predicates driving every conditional row on the convert page |
| `src/input_file.rs` | `lib/input_file.rb` | one loaded image: path, kind, sandbox flag, texture, frame count, dimensions |
| `src/magick.rs` | `lib/magick.rb` | the `magick identify` probe, the argument builder, the job runner, the zip/PDF collection step |
| `src/temp.rs` | `lib/temp_dir.rb` | the scratch directory and `JobFile` naming |
| `src/color.rs` | `lib/color.rb` | RGBA → `#rrggbbaa` for `-background` / `-fill` |

**All present.**

## 24. GSettings

`data/io.gitlab.adhami3310.Converter.gschema.xml.in`: three enums (output ×13,
compression ×2, resize ×2) and eight keys — `window-width` 750,
`window-height` 750, `is-maximized` false, `quality` 92, `dpi` 300,
`output-format` `Jpg`, `compression-format` `Dir`, `resize-type`
`Percentage`. The port ships the schema verbatim and reads it through
`lib/settings.rb`, so a user upgrading from upstream keeps every stored
preference. **Present.**

## 25. Stylesheet

`data/resources/style.css` — 21 rules plus one `@media (prefers-contrast: more)`
block. App-namespaced classes: `card-content`, `drag-overlay-status-page`,
`image-caption`, `image-remove`, `image-rest-button`, `large_number`, `lock`,
`long`, `no-padding`, `output-filetype-drop`, `unit-drop`; plus the element
selector `dragoverlay`, the `value` pseudo-element and the
`row.property label.title/.subtitle` pair. → `lib/style.rb`, rule for rule,
loaded through a `Gtk::CssProvider` because the port has no GResource bundle.
**Present.**

## 26. Translations

`po/`: 20 catalogues in `LINGUAS` (ar bg cs de es fr hi hr it ka kw nl oc pt
pt_BR ru sv tr uk) plus an unlisted `zh_cn.po`, and `switcheroo.pot`.
`POTFILES.in` covers the two metadata files, the schema, `image-rest.blp`,
`window.blp` and five Rust files. The port carries all of `po/`, compiles to
`locale/<lang>/LC_MESSAGES/switcheroo.mo` and looks msgids up through the
`gettext` gem in `lib/translations.rb` — upstream's msgids byte for byte, so
every catalogue answers. **Present**; see `.reports/translation-parity.md`.

## 27. Resources and icons

`resources.gresource.xml` bundles the three compiled blueprints, `style.css`,
the metainfo and ten SVGs. The port has no bundle (blueprints become Ruby,
the CSS becomes `lib/style.rb`), and the icons are installed to the icon theme
from `data/icons/` instead: `chain-link-loose-symbolic`,
`chain-link-symbolic`, `im-symbolic`, `image-symbolic`, `plus-large-symbolic`,
`user-trash-symbolic`, `view-more-horizontal-symbolic`, plus the app icon,
its `-symbolic` and `.Devel` variants. **Present** — the two other-app icons
(`io.gitlab.adhami3310.Impression.svg`, `io.gitlab.adhami3310.Footage.svg`)
used by the About dialog are the only ones not carried.

## 28. Shell integration

`…desktop.in.in` (with the `Convert` keyword list and mime types),
`…service.in` (D-Bus activation) and `…metainfo.xml.in.in` (AppStream, read at
runtime by the About dialog). All three are carried into `data/`, the desktop
file as `switcheroo.desktop.in` and installed under the app id by the
`Rakefile`. **Present.**

---

## Blockers

None for component work — every user-facing component upstream declares has a
`lib/*.rb` counterpart. The open items are behavioural and non-component, and
`COMPONENT_PARITY.md` (updated 2026-11-07, driven against the real app rather
than only read) has since closed most of what an earlier pass flagged here:

- **Tree content — now carried.** `COPYING`, `Switcheroo.doap`, `PRESS.md`,
  `update_translation.sh` and the two screenshots (`data/screenshots/{0,1}.png`)
  are all present in this tree; the previous round of this report predates
  them. The two other-app icons the About dialog's "Other Apps" rows want
  (`io.gitlab.adhami3310.Impression.svg`, `io.gitlab.adhami3310.Footage.svg`)
  are also now in `data/icons/hicolor/scalable/apps/`.
- **Remaining behavioural gaps** (`COMPONENT_PARITY.md` → "Remaining gaps"):
  `image_thumbnail.rb`'s `size_allocate()` vfunc is not reproducible (Ruby
  widget vfuncs are not dispatched); the transparency-colour accessible label
  is announced rather than set (`update_property` raises
  `NotImplementedError`); there is still no GResource bundle (assets are read
  from `data/` instead); and the Flatpak manifest (`io.gitlab.adhami3310.Converter.json`)
  is not started — there is no Ruby SDK extension to build it against, and no
  `flatpak-builder`/GNOME runtime here to build it even once.
- **Driven, not merely read.** `spec/` (70 examples) and
  `test/drive_main_window.rb` now exercise the window, the convert page, the
  thumbnail measurement and the magick spawn paths against a real headless
  display (`gtk4-broadwayd`); this caught and fixed a startup crash
  (`Gtk::IconTheme.for_display` → `get_for_display`) that a reading-only pass
  had marked parity. The all-images page, the drop-target reveal, clipboard
  paste and the full ZIP/PDF conversion pipeline are still not driven.
- **Binding constraints, recorded as correspondences, not gaps.**
  `Adwaita::Application`/`ApplicationWindow` are unusable from Ruby, so the
  port builds on `Gtk::Application`; `Adw.AboutDialog.from_appdata` and the
  accessibility relation setters are absent, so the About dialog parses the
  metainfo itself and two widgets are built from `Gtk::Builder` XML snippets.
