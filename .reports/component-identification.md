# Component identification — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` |
| Port | `ruby` @ `d15487b137763f668e1bf23284beb7f99989a1da` |
| Symbol table | `.claude/skills/component-identification/scripts/symbols.tsv` |
| Scan | `component-scan.sh` over both trees, materialised with `git archive` (upstream never checked out) |
| Units | 17 widget units + 8 non-widget units |

## Step 1 — declarative UI, both sides

Upstream has three blueprint files and they are the unit list:

| `.blp` | Template root | Named roots |
|---|---|---|
| `data/resources/blueprints/window.blp` | `template $AppWindow: Adw.ApplicationWindow` | `Adw.ShortcutsDialog help_overlay`, `menu primary_menu` |
| `data/resources/blueprints/image-thumbnail.blp` | `template $ImageThumbnail : Widget` | — |
| `data/resources/blueprints/image-rest.blp` | `template $ImageRest : FlowBoxChild` | — |

The port has **no** `.ui`/`.blp` files, by house style — but it is not
free of GtkBuilder. Three XML fragments are built at runtime and each exists
only because an accessibility block cannot be attached any other way:

- `lib/convert_page.rb:586-610` (`quality_markup`) — `GtkAdjustment` + `AdwActionRow` + `GtkScale` with `<relation name="labelled-by">`
- `lib/convert_page.rb:resize_type_markup` — `GtkDropDown` with `<property name="label">`
- `lib/app_window.rb:flow_box_child_markup` — `GtkFlowBoxChild` with `<property name="label">`

## Step 2/3 — scan totals

| Axis | Upstream distinct | Port distinct |
|---|---:|---:|
| `widget` | 40 | 38 |
| `controller` | 1 | 1 |
| `type` | 24 | 18 |
| `css` | 23 | 24 |
| `css-name` | 1 | **0** |
| `signal` | 11 | 18 |
| `action` | 8 | 2 |

Read as a map, not a verdict. Three of these rows are scan artefacts and are
resolved in `component-parity.md`:

- **`action` 8 → 2.** The port installs all eight. Six come out of a loop over
  `AppWindow::WINDOW_ACTIONS` and two out of `App#setup_actions`, so the names
  are variables and the scan cannot see them. Read off the install sites and
  confirmed live: the drive run asserts all seven accelerators and all six
  window actions.
- **`type` 24 → 18.** `Gtk.StackPage`, `Gtk.Align`, `Gtk.Orientation`,
  `Gtk.RevealerTransitionType`, `Gtk.Root`, `Gtk.Native`, `Gtk.Buildable`,
  `Gtk.ConstraintTarget`, `Gtk.ShortcutManager`, `Gtk.StringObject` are
  `<child>` wrappers, enums and interface lists. Not components.
- **`signal` 11 → 18.** The port connects *more* names because the bindings
  spell `connect_current_drop_notify` as `notify::current-drop`,
  `connect_selected_notify` as `notify::selected`, `connect_rgba_notify` as
  `notify::rgba`. Same connections, different spelling.

The one row that is a real finding is **`css-name` 1 → 0**: upstream's
`DragOverlay` names its CSS node, the port does not. See
`component-parity.md`, gap G4.

## Step 4/5 — the inventory

### `src/application.rs` + `src/main.rs` + `src/config.rs.in` — the application object

| Widget | × | CSS | Signals | Actions | Notes |
|---|---:|---|---|---|---|
| `Adw.Application` | 1 | — | `startup`, `activate`, `open`, `handle-local-options` | installs `app.quit`, `app.new-window` | `HANDLES_OPEN`; `--new-window` main option; seven accelerators |

Non-widget behaviour in this unit: `glib::set_application_name(gettext("Switcheroo"))`,
`Gtk::Window::set_default_icon_name(APP_ID)`, the `PKGDATADIR/icons` search
path, `setlocale`/`bindtextdomain`/`textdomain`, the GResource registration.

### `window.blp:4-47` + `src/window.rs` — the application window

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.ApplicationWindow` | 1 | — | `close-request` | 750×750 default, 300×300 minimum, title `_("Switcheroo")` |
| `Gtk.Box` (vertical) | 1 | — | — | root |
| `$DragOverlay` | 1 | — | — | composite, own unit |
| `Adw.ToastOverlay` | 1 | — | — | every toast goes here |
| `Adw.NavigationView` | 1 | — | — | two pages, `push_by_tag` |
| `Adw.NavigationPage` | 1 | — | — | tag `main` |
| `Adw.ToolbarView` | 1 | — | — | |
| `Adw.HeaderBar` | 1 | — | — | `show-title: false` |
| `Gtk.Button` (add) | 1 | `flat` | → `win.add` | tooltip `_("Add Images (Ctrl+O)")`, starts hidden |
| `Gtk.MenuButton` | 1 | — | — | `primary: true`, `primary_menu` model |
| `Gtk.WindowHandle` | 1 | — | — | |
| `Gtk.Stack` | 1 | — | — | crossfade, five named children |
| `Gtk.DropTarget` *(controller)* | 1 | — | `drop`, `notify::current-drop` | `Gdk.FileList`, `COPY` |
| `Gtk.FlowBoxChild` | repeater | — | — | one per loaded file + one for the `+N` tile; accessible `Label` = the file's caption |

Repeaters: the two thumbnail strips. Conditional: the `+N` tile only when more
than six files are visible; the add button only on the convert page.

### `window.blp:53-84` — welcome page (empty state)

`Adw.StatusPage` ×1 (`icon-dropshadow`, app icon, `_("Switcheroo")`,
`_("Drag and drop images here")`) · `Gtk.Box` ×1 · `Gtk.Button` ×1
(`suggested-action`, `pill`, `_("_Open Images…")`, → `win.add`).

### `window.blp:86-97` — loading page

`Adw.StatusPage` ×1 · `Gtk.Spinner` ×1 (32×32), started/stopped by the window.

### `window.blp:331-341` — invalid-image page (error state)

`Adw.StatusPage` ×1 — `im-symbolic`, `_("Could not Load Image")`,
`_("This image could be corrupted or may use an unsupported file format.")`.

### `window.blp:343-374` — converting page

`Adw.StatusPage` ×1 (`_("Converting")`, `_("This could take a while")`) ·
`Gtk.Box` ×1 · `Gtk.ProgressBar` ×1 (`show-text`, `_("Loading…")` →
`"done/total"` → `_("Collecting files")`) · `Gtk.Button` ×1
(`destructive-action`, `pill`, `_("_Cancel")`, `clicked` → `convert_cancel`).

### `window.blp:99-329` + `src/window.rs` (WindowUI/ConvertArguments/SettingsStore) — convert page

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.Bin` | 2 | — | — | the two nested wrappers of `window.blp:102-103` |
| `Adw.PreferencesPage` | 1 | — | — | |
| `Adw.PreferencesGroup` | 4 | — | — | 4th is `valign: end`, `halign: center` |
| `Gtk.FlowBox` | 1 | — | — | homogeneous, 12/12 spacing, `selection-mode: none` |
| `Adw.ComboRow` | 1 | `output-filetype-drop` | `notify::selected` | `_("Export Format")`, model rebuilt per update |
| `Adw.ActionRow` | 8 | — | — | single-PDF, ZIP, quality, bgcolor, dpi, resize, filter, strip |
| `Gtk.Switch` | 3 | — | `notify::active`/`state` | single-PDF, ZIP, strip |
| `Gtk.Scale` | 1 | — | — | 1..100, digits 0, value right, `labelled-by: quality_row` |
| `Gtk.ColorDialogButton` | 1 | — | `notify::rgba` | `with-alpha` toggled by output format |
| `Gtk.Entry` | 5 | — | `changed` ×4 | dpi + 4 resize entries, `input-purpose: digits`, 8 chars |
| `Gtk.ToggleButton` | 3 | `raised`/`circular`/`lock`; `linked` ×2 | `clicked`, `toggled` ×2 | chain link + the two filter radios |
| `Gtk.DropDown` | 1 | `flat`, `unit-drop` | `notify::selected` | `%`/`px`, accessible label |
| `Gtk.Box` | 3 | `linked` on one | — | resize entries, unit wrapper, filter pair |
| `Gtk.Button` (convert) | 1 | `suggested-action`, `pill`, `long` | `clicked` | `_("_Convert")` |

Conditional rows, all six driven by the formats in play: quality (lossy
output), bgcolor (any input with alpha), dpi (any PDF input), filter (not all
SVG), strip (any input with metadata), ZIP/single-PDF (the run produces more
than one file).

### `window.blp:380-441` — all-images page

`Adw.NavigationPage` ×1 (tag `all_images`, `_("All Images")`) ·
`Adw.ToolbarView` ×1 · `Adw.HeaderBar` ×1 · `Gtk.Button` ×1 (`flat`, →
`win.add`) · `Gtk.WindowHandle` ×1 · `Gtk.Stack` ×1 (crossfade) ·
`Gtk.ScrolledWindow` ×1 · `Gtk.FlowBox` ×1 (4 per line, 16px margins,
centred) · `Adw.StatusPage` ×1 · `Gtk.Spinner` ×1.

### `image-thumbnail.blp` + `src/widgets/image_thumbnail.rs` — one thumbnail

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| root | 1 | `card`, `image-thumbnail` | — | `overflow: hidden`; `measure()` clamps the width to min = nat = 150 |
| `Gtk.Box` | 3 | `card-content`, `image-container` | — | |
| `Gtk.Overlay` | 1 | — | — | |
| `Gtk.Picture` | 1 | — | — | 150×150, `content-fit: cover`, shown when a texture loaded |
| `Gtk.Image` | 1 | — | — | 150×150, `image-symbolic`, `icon-size: large`, the fallback |
| `Adw.Bin` | 1 | `image-caption`, `caption` | — | `overflow: hidden` |
| `Gtk.Label` | 1 | — | — | `"PNG · 1920×1080"` |
| `Gtk.Button` | 1 | `circular`, `image-remove`, `osd` | `clicked` → `remove-clicked` | `_("Remove image")` |

### `image-rest.blp` + `src/widgets/image_rest.rs` — the `+N` tile

`Gtk.FlowBoxChild` root ×1 (`no-padding`, `focusable: false`) · `Adw.Bin` ×1 ·
`Gtk.Button` ×1 (`image-container`, `card`, `image-rest-button`,
`view-more-horizontal-symbolic`, 150×150, tooltip
`_("Show {} more images")`, `clicked`) · `Gtk.Box` ×1 · `Gtk.Label` ×2
(`large_number` carrying `_("+{}")`, and `_("Show All")`).

### `window.blp:484-513` — primary menu

`Gio.Menu`, two sections, five items: `_("Paste From Clipboard")` → `win.paste`,
`_("New Window")` → `app.new-window`, `_("Clear Window")` → `win.clear` ‖
`_("Keyboard Shortcuts")` → `win.show-help-overlay`,
`_("About Switcheroo")` → `win.about`.

### `window.blp:448-482` — shortcuts dialog

`Adw.ShortcutsDialog` ×1 · `Adw.ShortcutsSection` ×1
(`C_("shortcut window","General")`) · `Adw.ShortcutsItem` ×6, each naming an
action so Adwaita looks the accelerator up.

### `src/window.rs:1463-1505` — error dialog (error state)

`Adw.AlertDialog` ×1 (`_("Error While Processing")`) ·
`Gtk.ScrolledWindow` ×1 (`card`, 200→400px) · `Gtk.Label` ×1 (`monospace`,
`word_char` wrap, 12px margins, xalign/yalign 0) · responses `_("_Close")` and
`_("_Copy to Clipboard")` (suggested) · `response` → clipboard +
`_("Error copied to clipboard")` toast.

### `src/window.rs:572-608` + `:1543-1583` — stop-converting dialog

`Adw.AlertDialog` ×1 (`_("Stop converting?")`,
`_("You will lose all progress.")`) · responses `_("_Cancel")` and `_("_Stop")`
(destructive). Built twice upstream, once in the port — the ledger records the
2→1.

### `src/widgets/about_window.rs` — about dialog

`Adw.AboutDialog` ×1, from the AppStream metainfo, plus the developer list,
`_("translator-credits")`, two `add_other_app` rows (`_("Impression")` /
`_("Create bootable drives")`, `_("Footage")` / `_("Polish your videos")`),
two `add_acknowledgement_section`s (`_("Code and Design Borrowed from")` with
seven entries, `_("Sample Image from")` with one) and one
`add_legal_section("ImageMagick", MIT/X11)`.

### `data/resources/style.css` — the stylesheet

Twelve app-namespaced classes (`drag-overlay-status-page`, `card-content`,
`image-caption`, `image-remove`, `image-rest-button`, `lock`, `large_number`,
`unit-drop`, `long`, `no-padding`, `output-filetype-drop`, plus the
`image-container`/`image-thumbnail` pair that is attached and never defined),
three element selectors (`dragoverlay`, `value`, `flowboxchild:focus`), two
`row.property` descendant rules and one
`@media (prefers-contrast: more)` block.

### Non-widget units

| Upstream | What it is |
|---|---|
| `src/magick.rs` | `count_frames`, `MagickConvertJob#get_command`, `JobFile`, `generate_job`, `wait_for_child` |
| `src/filetypes.rs` | `FileType` (15), `CompressionType` (2), `OutputType`, and their eight capability predicates |
| `src/file_chooser.rs` | the open / save / choose-folder dialogs and their four error messages |
| `src/input_file.rs` | one loaded image: path, kind, texture, frame count, dimensions, caption |
| `src/temp.rs` | the scratch directory, sandboxed or not |
| `src/color.rs` | `Color` ↔ `Gdk.RGBA` ↔ `#rrggbbaa` |
| `gio::Settings` + `…gschema.xml.in` | six keys, three of them enums |
| `src/main.rs` locale setup | domain binding |

## What the scan could not see, and was read instead

- **Both thumbnail strips are repeaters.** One scan row, N tiles.
- **A removed file still gets an empty `Gtk.FlowBoxChild`**, so the indices the
  two filter functions use keep lining up with the store. Conditional widget
  the scan reports as unconditional.
- **The `+N` tile is a `FlowBoxChild` inside a `FlowBoxChild`.** Upstream's
  `ImageRest` *is* a `FlowBoxChild` and is then wrapped in another one
  (`src/window.rs:1977-1984`). Both sides do it; neither is a gap.
- **`add_button` visibility is set from five different stack switches**, not
  from the blueprint.
- **Eight actions built from loops** (above).
- **The `styles [ … ]` arrays in `window.blp` span lines**, so the scan under-reports
  `flat` as 1 where there are 3 sites, and misses `raised`/`lock` entirely.
  Read off the blueprint by hand; the port attaches all of them.
- **`Gtk.CompositeTemplate` ×3 and `Gtk.Widget` ×9** are gtk-rs subclass
  plumbing, not widgets.
