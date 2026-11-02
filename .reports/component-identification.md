# Component identification — Switcheroo-rb, both sides

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe` (Rust, gtk-rs + libadwaita) |
| Port | `ruby` @ `e50a6654ab1c` |
| Scan | `.claude/skills/component-identification/scripts/component-scan.sh` with the committed `symbols.tsv` (1301 rows) |
| Upstream rows | 176 |
| Port rows | 145 |

`.reports/component-inventory.md` (commit `65ec8d0`) is the upstream-only
inventory and is **stale**: its "The `ruby` branch today has three files …
Nothing user-facing is implemented" paragraph was written before `e50a665`
landed the port. It is kept for its upstream reading; this document is the
current one and covers both sides.

## Step 1 — the declarative UI

Upstream has three blueprint files and they are the component inventory:

```
data/resources/blueprints/window.blp          513 lines
data/resources/blueprints/image-thumbnail.blp  56 lines
data/resources/blueprints/image-rest.blp       27 lines
```

Three `template $Name :` roots (`$AppWindow`, `$ImageThumbnail`,
`$ImageRest`), plus two standalone top-level named objects in `window.blp`
that no widget subclass owns — `Adw.ShortcutsDialog help_overlay` and
`menu primary_menu` (5 `item` entries across 2 sections). The port has no
`.ui`/`.blp` files (`find . -name '*.blp' -o -name '*.ui'` is empty), by
design — widgets are memoized methods.

## The file mapping

Many-to-one on the upstream side, one-to-many on the port side: the port
splits `window.blp`'s five stack pages and two navigation pages into one file
each, which is the house shape.

| Upstream | Port |
|---|---|
| `src/main.rs` + `src/application.rs` + `src/config.rs.in` | `lib/main.rb`, `lib/application.rb`, `exe/switcheroo`, `lib/switcheroo/application.rb` |
| `window.blp` (`$AppWindow` shell) + `src/window.rs` | `lib/app_window.rb` |
| `window.blp` `stack_welcome_page` | `lib/welcome_page.rb` |
| `window.blp` `stack_loading` | `lib/loading_page.rb` |
| `window.blp` `stack_convert` + `window.rs` option handlers | `lib/convert_page.rb` |
| `window.blp` `stack_invalid_image` | `lib/invalid_image_page.rb` |
| `window.blp` `stack_converting` + `window.rs` progress helpers | `lib/converting_page.rb` |
| `window.blp` `all_images` navigation page | `lib/all_images_page.rb` |
| `window.blp` `menu primary_menu` | `lib/primary_menu.rb` |
| `window.blp` `Adw.ShortcutsDialog help_overlay` | `lib/shortcuts_dialog.rb` |
| `src/drag_overlay.rs` | `lib/drag_overlay.rb` |
| `src/widgets/image_thumbnail.rs` + `image-thumbnail.blp` | `lib/image_thumbnail.rb` |
| `src/widgets/image_rest.rs` + `image-rest.blp` | `lib/image_rest.rb` |
| `src/widgets/about_window.rs` | `lib/about_dialog.rb` |
| `src/window.rs` `close_dialog()` + `convert_cancel()` alerts | `lib/stop_converting_dialog.rb` |
| `src/window.rs` `convert_failed()` alert | `lib/error_dialog.rb` |
| `src/file_chooser.rs` | `lib/file_chooser.rb` |
| `src/filetypes.rs` | `lib/file_type.rb` |
| `src/input_file.rs` | `lib/input_file.rb` |
| `src/magick.rs` + `src/temp.rs` | `lib/magick.rb`, `lib/temp_dir.rb` |
| `src/color.rs` | `lib/color.rb` |
| `data/resources/style.css` | `lib/style.rb` (heredoc + `Gtk::CssProvider`) |
| `data/…Converter.gschema.xml.in` | `lib/settings.rb` (JSON file, **not** GSettings) |
| `data/…Converter.desktop.in.in` | `data/switcheroo.desktop` |
| `data/…Converter.metainfo.xml.in.in` | **nothing** |
| `data/…Converter.service.in` | **nothing** |
| `data/resources/resources.gresource.xml` + `data/meson.build` + `meson.build` | **nothing** (no bundle, no install) |
| `data/resources/icons/**` | `data/icons/**` (8 of 10 svg; see below) |
| `data/resources/screenshots/{0,1}.png` | **nothing** |
| `po/**` | `po/**` (byte-identical, verified) |

Two upstream files have no port file opposite them and are gaps found here
rather than in any diff: the AppStream metainfo and the D-Bus service file.

## Per-component inventory

### `lib/app_window.rb` — the application window and its state machine

| Widget | × | CSS | Signals / actions | Notes |
|---|---:|---|---|---|
| `Adwaita::ApplicationWindow` | 1 | — | `close-request` | 750×750 default, 300×300 minimum, title "Switcheroo" |
| `Gtk::Box` (root, vertical) | 1 | — | — | |
| `DragOverlay` | 1 | `dragoverlay` | — | composite, see below |
| `Adwaita::ToastOverlay` | 1 | — | — | six toasts raised through it |
| `Adwaita::NavigationView` | 1 | — | — | 2 pages |
| `Adwaita::NavigationPage` | 1 | — | — | tag `main` |
| `Adwaita::ToolbarView` | 1 | — | — | |
| `Adwaita::HeaderBar` | 1 | — | — | `show_title = false` |
| `Gtk::Button` (add) | 1 | `flat` | action `win.add` | `visible = false` until images load |
| `Gtk::MenuButton` | 1 | — | `PrimaryMenu.build` | `primary = true` |
| `Gtk::WindowHandle` | 1 | — | — | `vexpand` |
| `Gtk::Stack` | 1 | — | — | 5 named children, crossfade |
| `Gtk::FlowBoxChild` | repeater | — | — | one per file in each flow box, plus the `+N` tile |
| `Gtk::DropTarget` (controller) | 1 | — | `drop` | `Gdk::FileList`, `:copy` |
| `Adwaita::Toast` | 6 sites | — | `button-clicked` (1) | |
| `Gtk::FileLauncher` (type) | 1 | — | — | the toast's Open button |

Actions installed: `win.close`, `win.add`, `win.clear`, `win.show-help-overlay`,
`win.about`, `win.paste` — built in a loop from `WINDOW_ACTIONS`, so the scan's
`action` stream shows none of them. Read off `lib/app_window.rb:271-278`.

### `lib/convert_page.rb` — the conversion options page

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adwaita::PreferencesPage` | 1 | — | — | |
| `Adwaita::PreferencesGroup` | 4 | — | — | thumbnails, output, options, convert |
| `Gtk::FlowBox` (short strip) | 1 | — | filter func | homogeneous, 12px gaps |
| `Adwaita::ComboRow` (export format) | 1 | `output-filetype-drop` | `notify::selected` | `Gtk::StringList` model |
| `Adwaita::ActionRow` | 8 | — | — | single-pdf, zip, quality, bgcolor, dpi, resize, filter, strip |
| `Gtk::Switch` | 3 | — | `notify::active` (1) | single-pdf, zip, strip |
| `Gtk::Scale` + `Gtk::Adjustment` | 1 | — | — | 1–100, digits 0, value right |
| `Gtk::ColorDialogButton` + `Gtk::ColorDialog` | 1 | — | **none** | alpha enabled |
| `Adwaita::Bin` | 2 | — | — | dpi wrapper, unit-dropdown wrapper |
| `Gtk::Entry` | 5 | — | `changed` (4) | dpi, w, h, %w, %h — built by a shared `pixel_entry` factory, so the scan counts 2 |
| `Gtk::ToggleButton` | 3 | `raised` `circular` `lock` (link); `linked` on the box | `clicked` (1), `toggled` (2) | link-axis, Default, Pixel Art |
| `Gtk::DropDown` (unit) | 1 | `flat` `unit-drop` | `notify::selected` | `%` / `px` |
| `Gtk::Box` | 3 | `linked` (1) | — | resize row, unit box, filter box |
| `Gtk::Button` (Convert) | 1 | `suggested-action` `pill` `long` | `clicked` | |

Dynamic visibility: every row above hides itself when the loaded formats do
not support the option (`update_options`, `lib/convert_page.rb:597-640`).

### `lib/welcome_page.rb` — the empty state

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adwaita::StatusPage` | 1 | `icon-dropshadow` | — | app icon, "Switcheroo", "Drag and drop images here" |
| `Gtk::Box` | 1 | — | — | vertical, 12 |
| `Gtk::Button` | 1 | `suggested-action` `pill` | action `win.add` | `_Open Images…`, `use_underline` |

### `lib/loading_page.rb`

`Adwaita::StatusPage` ×1 (no icon, no title) holding `Gtk::Spinner` ×1 at 32×32.

### `lib/invalid_image_page.rb` — the error state

`Adwaita::StatusPage` ×1, icon `im-symbolic`, title "Could not Load Image",
description "This image could be corrupted or may use an unsupported file
format.". No child, no signals.

### `lib/converting_page.rb` — the progress state

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adwaita::StatusPage` | 1 | — | — | "Converting" / "This could take a while" |
| `Gtk::Box` | 1 | — | — | vertical, 36 |
| `Gtk::ProgressBar` | 1 | — | — | `show_text`, text "Loading…" → `done/total` → "Collecting files" |
| `Gtk::Button` | 1 | `destructive-action` `pill` | `clicked` | `_Cancel` |

### `lib/all_images_page.rb` — the second navigation page

| Widget | × | CSS | Signals / actions | Notes |
|---|---:|---|---|---|
| `Adwaita::NavigationPage` | 1 | — | — | tag `all_images`, title "All Images" |
| `Adwaita::ToolbarView` | 1 | — | — | |
| `Adwaita::HeaderBar` | 1 | — | — | |
| `Gtk::Button` | 1 | `flat` | action `win.add` | `plus-large-symbolic` |
| `Gtk::WindowHandle` | 1 | — | — | |
| `Gtk::Stack` | 1 | — | — | grid / loading |
| `Gtk::ScrolledWindow` | 1 | — | — | |
| `Gtk::FlowBox` | 1 | — | filter func | max 4 per line, centred |
| `Adwaita::StatusPage` + `Gtk::Spinner` | 1 + 1 | — | — | loading child |

### `lib/drag_overlay.rb` — the drop target overlay

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adwaita::Bin` (self) | 1 | `dragoverlay` | — | upstream names the CSS **node**; this is the class standing in for it |
| `Gtk::Overlay` | 1 | — | — | |
| `Gtk::Revealer` | 1 | — | — | `can_target = false`, crossfade |
| `Adwaita::StatusPage` | 1 | `drag-overlay-status-page` | — | `document-send-symbolic`, "Drop Here to Open" |
| `Gtk::DropTarget` (controller) | 1 (handed in) | — | `notify::current-drop` | added as a controller on self |

### `lib/image_thumbnail.rb` — one image tile (repeater)

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adwaita::Bin` (self) | 1 | `card` `image-thumbnail` | — | `overflow = :hidden` |
| `Gtk::Box` | 5 | `card-content` (root), `image-container` (child) | — | root, child, content, image, caption |
| `Gtk::Overlay` | 1 | — | — | |
| `Gtk::Picture` | 1 | — | — | 150×150, `content_fit :cover`, shown only with a texture |
| `Gtk::Image` | 1 | — | — | `image-symbolic`, large, shown only without one |
| `Adwaita::Bin` (caption) | 1 | `image-caption` `caption` | — | |
| `Gtk::Label` | 1 | — | — | "FORMAT w×h" |
| `Gtk::Button` | 1 | `circular` `image-remove` `osd` | `clicked` | `user-trash-symbolic`, tooltip "Remove image" |

### `lib/image_rest.rb` — the "+N / Show All" tile

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk::FlowBoxChild` (self) | 1 | `no-padding` | — | `focusable = false` |
| `Adwaita::Bin` | 1 | — | — | |
| `Gtk::Button` | 1 | `image-container` `card` `image-rest-button` | `clicked` | 150×150; **no `icon-name`** |
| `Gtk::Box` | 1 | — | — | vertical, centred |
| `Gtk::Label` | 2 | `large_number` (1st) | — | `+N`, "Show All" |

### `lib/about_dialog.rb`

`Adwaita::AboutDialog` ×1, built field by field (no appdata). 2 other apps,
2 acknowledgement sections, 1 legal section.

### `lib/shortcuts_dialog.rb`

`Adwaita::ShortcutsDialog` ×1 → `Adwaita::ShortcutsSection` ×1 ("General") →
`Adwaita::ShortcutsItem` ×6, each carrying an `action_name`. Built in a loop
from `ITEMS`, so the scan sees one.

### `lib/primary_menu.rb`

`Gio::Menu` with 2 sections and 5 items: `win.paste`, `app.new-window`,
`win.clear` | `win.show-help-overlay`, `win.about`. No `custom:` slots.

### `lib/stop_converting_dialog.rb` / `lib/error_dialog.rb`

`Adwaita::AlertDialog` ×1 each, instantiated at 2 and 1 call sites
respectively. Stop: responses `cancel`/`stop`, `stop` destructive. Error:
responses `ok`/`copy`, `copy` suggested, `extra_child` a `Gtk::ScrolledWindow`
(`card`, 200–400px) holding a wrapping `monospace` `Gtk::Label`.

### `lib/application.rb`

Not a widget. `Gtk::Application` (not `Adwaita::Application`) with
`:handles_open`, the `--new-window` main option, actions `app.quit` and
`app.new-window`, and the seven accelerators. Also the icon search path, the
stylesheet load and the (ineffective, see `translation-parity.md`) text-domain
bind.

## Non-widget inventory, port side

| Item | State |
|---|---|
| `lib/file_type.rb` | 13 output formats, 2 compression types, 2 resize filters, alpha/animation/pixbuf predicates |
| `lib/input_file.rb` | path, kind, frame count, dimensions, texture, caption |
| `lib/magick.rb` | `identify` probe, job generation, parallel spawn with a pid registry, zip/dir/pdf collection |
| `lib/temp_dir.rb` | per-run temp directory |
| `lib/color.rb` | `Gdk::RGBA` → `#rrggbbaa` |
| `lib/settings.rb` | JSON under `XDG_CONFIG_HOME/switcheroo-rb/settings.json`, **not** GSettings |
| `lib/style.rb` | the stylesheet as a heredoc |
| `data/icons` | 8 svg: 7 action icons + `io.gitlab.adhami3310.Converter.svg`. Missing upstream's `…Converter.Devel.svg` and `symbolic/apps/…Converter-symbolic.svg` (and the three sibling-app icons, which upstream bundles for the About dialog's "other apps" tiles) |

## Scan over- and under-reports read, per Step 4

- Struck as not widgets (classifier agrees): `Gtk.StackPage` ×7, `Adw.ShortcutsItem`/`Section`, `Gtk.ColorDialog`, `Gtk.StringList`/`StringObject`, `Gtk.Adjustment`, `Gtk.IconTheme`, `Gtk.CssProvider`/`StyleContext`/`StyleProvider`, `Gtk.FileDialog`/`FileFilter`, `Gtk.FileLauncher`, `Adw.Toast`, `Adw.ResponseAppearance`, `Gtk.Align`, `Gtk.Orientation`, `Gtk.RevealerTransitionType`, `Gtk.License`, and every interface row (`Accessible`, `Buildable`, `ConstraintTarget`, `Root`, `Native`, `ShortcutManager`).
- `Gtk.CompositeTemplate` ×3 upstream is gtk-rs template plumbing; the widgets it stands for are in the `.blp`.
- Controllers compared on the signal axis, never the widget axis: `Gtk.DropTarget` (1 real instance upstream, built once in `setup_drop_target` and handed to `DragOverlay`; the 4 rows in `drag_overlay.rs` and 1 in `window.rs` are type mentions).
- Repeaters: `ImageThumbnail` (one per loaded file, two flow boxes), `Gtk::FlowBoxChild` (same), `Adwaita::ShortcutsItem` (×6 from a loop), menu `item` (×5 from two loops), `Gtk::Entry` (×5 from one factory), `Adwaita::Toast` (6 construction sites).
- Shared factories that make the scan undercount on the port side: `ConvertPage#pixel_entry` (4 call sites), `ShortcutsDialog#item` (6), `PrimaryMenu.section` (2), `AppWindow#thumbnail_child` (2).
- Actions built from variables on both sides and therefore absent from the `action` stream: upstream's `gio::ActionEntry::builder(...)` chain (`src/window.rs:279-337`, `src/application.rs:143`), the port's `WINDOW_ACTIONS` loop (`lib/app_window.rb:271`) and `setup_actions` (`lib/application.rb:131-145`).
- Dynamic CSS classes: none on either side. Every class is attached literally. The only dynamic *styling* is the link-axis icon swap (`chain-link-symbolic` ↔ `chain-link-loose-symbolic`).
- Stylesheet classes defined and never attached: none. App-namespaced classes attached: `image-container`, `image-rest-button`, `large_number`, `no-padding`, `card-content`, `image-caption`, `image-remove`, `image-thumbnail`, `drag-overlay-status-page`, `dragoverlay`, `lock`, `long`, `unit-drop`, `output-filetype-drop`. All 14 have rules in `lib/style.rb`.
- No submodules (`.gitmodules` absent on both sides). No libraries beyond GTK4 and libadwaita.
