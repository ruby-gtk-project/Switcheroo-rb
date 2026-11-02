# Component identification — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe83ec0bf7ebaa7ed783339c0e0016` |
| Port | `ruby` @ `341104dabaa5d95e2ac1d0c0911ab79bb5c017df` |
| Method | `component-identification/scripts/component-scan.sh` on both trees, then every file on both sides read |

This supersedes `.reports/component-inventory.md`, which was written before the
i18n/GSettings/metainfo commit and no longer matches either tree.

## Step 1 — the declarative UI

Upstream has three blueprint files and they *are* the component inventory:

```
data/resources/blueprints/window.blp          513 lines
data/resources/blueprints/image-thumbnail.blp  56 lines
data/resources/blueprints/image-rest.blp       27 lines
```

Roots: `template $AppWindow: Adw.ApplicationWindow`,
`template $ImageThumbnail : Widget`, `template $ImageRest : FlowBoxChild`,
plus two standalone top-level objects in `window.blp` that belong to no widget
subclass — `Adw.ShortcutsDialog help_overlay` and `menu primary_menu`. Those
two are units in their own right (identification's "one unit per standalone
object with no backing source file").

The port has **no** `.blp` or `.ui` files on disk — but it is not purely
declarative-free either: `lib/convert_page.rb` embeds **two GtkBuilder XML
fragments as Ruby heredocs** (`quality_markup`, `resize_type_markup`) because
the accessibility blocks of `window.blp:155-159` and `window.blp:255-259`
cannot be written from Ruby any other way. Those heredocs are declarative UI
and were read as such.

## Step 2/3 — scan totals

| Axis | Upstream | Port |
|---|---:|---:|
| Widget instances (summed counts) | 169 | 110 |
| Distinct widget types | 40 | 37 |
| `css` attachment rows | 26 | 33 |
| `signal` rows | 13 | 23 |
| `css-name` rows | 1 (`dragoverlay`) | 0 (expressed as a class) |

The upstream widget total double-counts every template root and every
`#[template_child]` (the blueprint declares the widget, the Rust declares the
field), so it is not comparable to the port's directly — see
`.reports/component-parity.md`, which unions per unit before comparing.

The scan **under-reports the port** in two known ways, both confirmed by
reading:

- `lib/convert_page.rb:619` `pixel_entry` is a shared factory called from four
  memoized methods. The scan sees 2 `Gtk::Entry.new` call sites; the port
  builds **five** entries (dpi, width, height, scale-width, scale-height).
- `lib/app_window.rb:227` installs six window actions from a loop over
  `WINDOW_ACTIONS`, so none of `win.close/add/clear/show-help-overlay/about/paste`
  appears in the `action` stream.

## The unit list

Read in the order a user meets them.

### 1. application — `src/application.rs` + `src/main.rs` + `src/config.rs.in` → `lib/application.rb`, `lib/main.rb`, `lib/config.rb`

| Item | × | Notes |
|---|---:|---|
| `Gio::SimpleAction` `app.quit` | 1 | quits |
| `Gio::SimpleAction` `app.new-window` | 1 | `present_main_window` |
| accelerators | 7 | `app.new-window`→`<Control>n`, `app.quit`→`<Control>q`, `win.clear`→`<Control>r`, `win.add`→`<Control>o`, `win.close`→`<Control>w`, `win.paste`→`<Control>v`, `win.show-help-overlay`→`<Control>question` |
| main option | 1 | `--new-window` / `-w`, msgid `Open a new window` |
| signals | 4 | `startup`, `activate`, `open`, `handle-local-options` |

Startup also sets the default icon name and adds `PKGDATADIR/icons` to the
icon theme search path. No widgets.

### 2. window shell — `window.blp:4-47` + `src/window.rs` → `lib/app_window.rb`

| Widget | × | CSS | Signals/actions | Notes |
|---|---:|---|---|---|
| `Adw.ApplicationWindow` | 1 | — | `close-request` | 750×750 default, 300×300 minimum, title `Switcheroo` |
| `Gtk.Box` (vertical) | 1 | — | — | root |
| `$DragOverlay` | 1 | `dragoverlay` (css **name** upstream) | — | title `Drop Here to Open` |
| `Adw.ToastOverlay` | 1 | — | — | host for 5 toasts |
| `Adw.NavigationView` | 1 | — | — | two pages, tags `main` / `all_images` |
| `Adw.ToolbarView` | 1 | — | — | |
| `Adw.HeaderBar` | 1 | — | — | `show-title: false` |
| `Gtk.Button` add | 1 | `flat` | `win.add` | icon `plus-large-symbolic`, tooltip `Add Images (Ctrl+O)`, starts hidden |
| `Gtk.MenuButton` | 1 | — | model `primary_menu` | icon `open-menu-symbolic`, tooltip `Primary Menu`, `primary: true` |
| `Gtk.WindowHandle` | 1 | — | — | `vexpand` |
| `Gtk.Stack` | 1 | — | — | crossfade, 5 named children |
| `Gtk.DropTarget` (controller) | 1 | — | `drop`, `notify::current-drop` | `Gdk::FileList`, COPY |

Window actions installed here: `win.close`, `win.add`, `win.clear`,
`win.show-help-overlay`, `win.about`, `win.paste`.

Toasts: `Unsupported filetype`, `Unable to access dropped files`,
`Error copied to clipboard`, `Image converted` (+ `Open` button),
`Converting Cancelled`.

### 3. drag overlay — `src/drag_overlay.rs` → `lib/drag_overlay.rb`

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.Bin` (root) | 1 | css **name** `dragoverlay` | — | |
| `Gtk.Overlay` | 1 | — | — | |
| `Gtk.Revealer` | 1 | — | — | crossfade, `can-target: false` |
| `Adw.StatusPage` | 1 | `drag-overlay-status-page` | — | icon `document-send-symbolic` |

### 4. welcome page — `window.blp:53-84` → `lib/welcome_page.rb`

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.StatusPage` | 1 | `icon-dropshadow` | — | icon `io.gitlab.adhami3310.Converter`, title `Switcheroo`, description `Drag and drop images here` |
| `Gtk.Box` | 1 | — | — | spacing 12 |
| `Gtk.Button` | 1 | `suggested-action`, `pill` | upstream `clicked`; port `win.add` | `_Open Images…`, `use-underline` |

### 5. loading page — `window.blp:86-97` → `lib/loading_page.rb`

`Adw.StatusPage` ×1, `Gtk.Spinner` ×1 (32×32, centred). No CSS, no signals.

### 6. invalid-image page — `window.blp:331-341` → `lib/invalid_image_page.rb`

`Adw.StatusPage` ×1, icon `im-symbolic`, title `Could not Load Image`,
description `This image could be corrupted or may use an unsupported file format.`

### 7. converting page — `window.blp:343-374` → `lib/converting_page.rb`

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.StatusPage` | 1 | — | — | title `Converting`, description `This could take a while` |
| `Gtk.Box` | 1 | — | — | spacing 36 |
| `Gtk.ProgressBar` | 1 | — | — | `show-text`, text `Loading…` → `done/total` → `Collecting files` |
| `Gtk.Button` cancel | 1 | `destructive-action`, `pill` | `clicked` | `_Cancel` |

### 8. convert page — `window.blp:99-329` + the `WindowUI`/`ConvertArguments`/`SettingsStore` impls of `src/window.rs` → `lib/convert_page.rb`

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.Bin` | 2 | — | — | two nested wrappers around the page |
| `Adw.PreferencesPage` | 1 | — | — | |
| `Adw.PreferencesGroup` | 4 | — | — | thumbnails / output / options / convert (last `valign: end`, `halign: center`) |
| `Gtk.FlowBox` image_container | 1 | — | filter func | homogeneous, 12/12 spacing, `selection-mode: none` |
| `Adw.ComboRow` output_filetype | 1 | `output-filetype-drop` | `notify::selected` | title `Export Format`, `Gtk.StringList` model |
| `Adw.ActionRow` single_pdf | 1 | — | — | `Save as multi-page PDF` |
| `Gtk.Switch` single_pdf_value | 1 | — | upstream `notify::state`; port `notify::active` | |
| `Adw.ActionRow` output_compression | 1 | — | — | `Save To ZIP` |
| `Gtk.Switch` output_compression_value | 1 | — | — | |
| `Adw.ActionRow` quality_row | 1 | — | — | `Quality`; `labelled-by` target of the scale |
| `Gtk.Scale` quality | 1 | — | — | `Gtk.Adjustment` 1..100, digits 0, value right |
| `Adw.ActionRow` bgcolor_row | 1 | — | — | `Background Color` / `Replaces original transparency layer` |
| `Gtk.ColorDialogButton` bgcolor | 1 | — | `notify::rgba` | `Gtk.ColorDialog` with-alpha, rgba `#00000000` |
| `Adw.ActionRow` dpi_row | 1 | — | — | `Pixel Density Per Inch` |
| `Adw.Bin` + `Gtk.Entry` dpi_value | 1+1 | — | — | |
| `Adw.ActionRow` resize_amount_row | 1 | — | — | `Resize` |
| `Gtk.Box` | 1 | — | — | spacing 5 |
| `Gtk.Entry` resize_width_value | 1 | — | `changed` | placeholder+tooltip `Width`, digits, 8 chars |
| `Gtk.Entry` resize_scale_width_value | 1 | — | `changed` | placeholder `Width`, tooltip `Width` |
| `Gtk.ToggleButton` link_axis | 1 | `raised`, `circular`, `lock` | `clicked` | `chain-link-symbolic` ↔ `chain-link-loose-symbolic`, tooltip `Preserve aspect ratio`, starts active |
| `Gtk.Entry` resize_height_value | 1 | — | `changed` | placeholder+tooltip `Height` |
| `Gtk.Entry` resize_scale_height_value | 1 | — | `changed` | placeholder `Width`, tooltip `Height` (upstream's own mismatch) |
| `Adw.Bin` + `Gtk.Box` | 1+1 | — | — | holds the unit dropdown |
| `Gtk.DropDown` resize_type | 1 | `flat`, `unit-drop` | `notify::selected` | model `%`/`px`; accessible label `Choose between resizing with percentages or using exact pixels` — **no tooltip upstream** |
| `Adw.ActionRow` resize_filter_row | 1 | — | — | `Resize Algorithm` |
| `Gtk.Box` | 1 | `linked` | — | |
| `Gtk.ToggleButton` resize_filter_default | 1 | — | `toggled` | `Default`, starts active |
| `Gtk.ToggleButton` resize_filter_pixel | 1 | — | `toggled` | `Pixel Art` |
| `Adw.ActionRow` strip_row | 1 | — | — | `Remove Metadata` |
| `Gtk.Switch` strip | 1 | — | — | |
| `Gtk.Button` convert_button | 1 | `suggested-action`, `pill`, `long` | `clicked` | `_Convert` |

Conditional (not repeaters): `quality_row` visible only for a lossy output;
`bgcolor_row` only when some input carries alpha; `dpi_row` only when some
input is a PDF; `strip_row` only when some input carries metadata;
`resize_filter_row` hidden when every input is an SVG; `single_pdf` /
`output_compression` only when the run produces more than one file; exactly one
of the pixel pair / percentage pair visible; `link_axis` hidden for pixels when
the images do not share a size.

Repeater: `image_container` holds up to 6 `Gtk.FlowBoxChild`, each wrapping an
`ImageThumbnail`, driven by the loaded-file list; the 6th slot becomes an
`ImageRest` when more remain.

### 9. all-images page — `window.blp:380-441` → `lib/all_images_page.rb`

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.NavigationPage` | 1 | — | — | tag `all_images`, title `All Images` |
| `Adw.ToolbarView` + `Adw.HeaderBar` | 1+1 | — | — | |
| `Gtk.Button` other_add_button | 1 | `flat` | `win.add` | tooltip `Add Images (Ctrl+O)` |
| `Gtk.WindowHandle` | 1 | — | — | |
| `Gtk.Stack` | 1 | — | — | crossfade, `all_images` / `stack_loading` |
| `Gtk.ScrolledWindow` | 1 | — | — | |
| `Gtk.FlowBox` full_image_container | 1 | — | filter func | 4 per line, 16px margins, 12/12 spacing |
| `Adw.StatusPage` + `Gtk.Spinner` | 1+1 | — | — | 32×32 |

Repeater: one `Gtk.FlowBoxChild` + `ImageThumbnail` per loaded file, unbounded.

### 10. image thumbnail — `image-thumbnail.blp` + `src/widgets/image_thumbnail.rs` → `lib/image_thumbnail.rb`

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| root | 1 | `card`, `image-thumbnail` (added in `new()`, not the template) | — | `overflow: hidden`; upstream's parent is bare `Gtk.Widget`, the port's is `Adwaita::Bin` |
| `Gtk.Box` root | 1 | `card-content` | — | |
| `Gtk.Box` child | 1 | `image-container` | — | |
| `Gtk.Overlay` | 1 | — | — | |
| `Gtk.Box` | 3 | — | — | vertical content, picture row |
| `Gtk.Picture` | 1 | — | — | 150×150, `content-fit: cover`; visible only with a texture |
| `Gtk.Image` | 1 | — | — | 150×150, `image-symbolic`, `icon-size: large`; the no-texture fallback |
| `Adw.Bin` caption | 1 | `image-caption`, `caption` | — | `overflow: hidden` |
| `Gtk.Label` content | 1 | — | — | `FORMAT · W×H`, untranslated by design |
| `Gtk.Button` remove_image | 1 | `circular`, `image-remove`, `osd` | `clicked` | name `remove_image`, icon `user-trash-symbolic`, tooltip `Remove image` |

Behaviour in the imp, not the template: `measure()` clamps the **horizontal**
orientation to min = nat = 150 whenever the file's dimensions are known;
`size_allocate()` allocates `root` the full size.

### 11. image rest — `image-rest.blp` + `src/widgets/image_rest.rs` → `lib/image_rest.rb`

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk.FlowBoxChild` | 1 | `no-padding` | — | `focusable: false` |
| `Adw.Bin` | 1 | — | — | |
| `Gtk.Button` image | 1 | `image-container`, `card`, `image-rest-button` | `clicked` | 150×150, `view-more-horizontal-symbolic`, tooltip `Show {} more images` (set in `new()`) |
| `Gtk.Box` | 1 | — | — | |
| `Gtk.Label` content | 1 | `large_number` | — | `+{}` with the count substituted after lookup |
| `Gtk.Label` | 1 | — | — | `Show All` |

### 12. primary menu — `window.blp:484-513` → `lib/primary_menu.rb`

2 sections, 5 items: `Paste From Clipboard`→`win.paste`,
`New Window`→`app.new-window`, `Clear Window`→`win.clear`;
`Keyboard Shortcuts`→`win.show-help-overlay`, `About Switcheroo`→`win.about`.
No `custom:` slots.

### 13. shortcuts dialog — `window.blp:448-482` → `lib/shortcuts_dialog.rb`

`Adw.ShortcutsDialog` ×1, `Adw.ShortcutsSection` ×1 (title
`C_("shortcut window", "General")`), `Adw.ShortcutsItem` ×6: Show Shortcuts,
Quit, New Window, Clear Window, Paste From Clipboard, Add Images — all with
the `shortcut window` msgctxt, each naming an action rather than an accelerator.

### 14. error dialog — `src/window.rs:1463-1505` → `lib/error_dialog.rb`

`Adw.AlertDialog` ×1 (heading `Error While Processing`, no body),
`Gtk.ScrolledWindow` ×1 (`card`, 200..400px),
`Gtk.Label` ×1 (`monospace`, 12px margins, xalign/yalign 0, wrap word-char).
Responses `ok`→`_Close`, `copy`→`_Copy to Clipboard` (suggested).

### 15. stop-converting dialog — `src/window.rs:572-608` and `:1543-1583` → `lib/stop_converting_dialog.rb`

`Adw.AlertDialog` ×1, heading `Stop converting?`, body
`You will lose all progress.`, responses `cancel`→`_Cancel`,
`stop`→`_Stop` (destructive). Upstream builds this twice, identically; the port
factors it into one class — a correspondence, named here so the 2→1 count is
not read as a gap.

### 16. about dialog — `src/widgets/about_window.rs` → `lib/about_dialog.rb`

`Adw.AboutDialog` ×1, built from the AppStream metainfo, plus: 1 developer,
`translator-credits`, 2 other apps (`Impression` / `Create bootable drives`,
`Footage` / `Polish your videos`), 2 acknowledgement sections
(`Code and Design Borrowed from` ×7 entries, `Sample Image from` ×1), 1 legal
section (`ImageMagick`, MIT/X11).

### 17. stylesheet — `data/resources/style.css` → `lib/style.rb`

21 rules + 1 `@media (prefers-contrast: more)` block. One element selector
(`dragoverlay`), one pseudo-element selector (`value`), one descendant-of-row
selector pair (`row.property label.title/.subtitle`), the rest
app-namespaced classes. No variant stylesheet.

## Non-widget units read as part of the inventory

- `src/filetypes.rs` → `lib/file_type.rb` — 15 input formats, 13 output
  formats, 2 compression types, 6 capability predicates.
- `src/magick.rs` + `ResizeFilter`/`StripType` from `src/window.rs` →
  `lib/magick.rb` — the probe, the argument builder, the job runner.
- `src/file_chooser.rs` → `lib/file_chooser.rb` — 3 dialogs, 1 filter name
  (`Images`), 1 accept label (`_Select Images`), 4 error msgids.
- `src/input_file.rs` → `lib/input_file.rb`.
- `src/temp.rs` → `lib/temp_dir.rb` (+ `JobFile`).
- `src/color.rs` → `lib/color.rb`.
- `data/*.gschema.xml.in`, `*.metainfo.xml.in.in`, `*.service.in`,
  `*.desktop.in.in` → carried into `data/` (the desktop file renamed to
  `switcheroo.desktop.in` and installed as `<app-id>.desktop` by the Rakefile).
