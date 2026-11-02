# Switcheroo — upstream component inventory

Upstream is **Rust (gtk-rs + libadwaita)** on `origin/main`, app id
`io.gitlab.adhami3310.Converter`, user-visible name **Switcheroo**: a batch
image converter that shells out to ImageMagick (`magick`) to convert, resize,
re-quality, strip metadata and re-background one or many dropped/opened images,
optionally bundling the results into a ZIP, a directory or a single multi-page
PDF.

Upstream is three blueprint files plus eleven Rust modules. The widget tree is
almost entirely in `data/resources/blueprints/window.blp`; `src/window.rs`
(2281 lines) is its callbacks, actions, dialogs and state machine. Per the
`component-identification` skill the component is the *set* of files, so each
row below unions the `.blp` with the `.rs` that drives it.

The `ruby` branch today has three files — `lib/switcheroo.rb`,
`lib/switcheroo/application.rb` (a blank Adwaita window with a "not written
yet" status page) and `lib/switcheroo/rb/version.rb`. **Nothing user-facing is
implemented.** The port's house shape is flat `lib/<thing>.rb`, one upstream
source file per file, as in the pilot `gnome-contacts-rb`.

---

## src/main.rs + src/application.rs + src/config.rs.in — the application object

Not a widget, but it owns the app id, the `HANDLES_OPEN` flag, the
`--new-window` command-line option, the `app.*` actions and every accelerator.

| Item | Detail |
|---|---|
| App id | `io.gitlab.adhami3310.Converter`, resource base `/io/gitlab/adhami3310/Converter/` |
| Flags | `gio::ApplicationFlags::HANDLES_OPEN` — files opened from the shell land in `open()` |
| CLI option | `--new-window` / `-w`, "Open a new window"; remote instances activate `app.new-window` and exit |
| Actions | `app.quit`, `app.new-window` |
| Accelerators | `app.new-window` `<Control>n`; `app.quit` `<Control>q`; `win.clear` `<Control>r`; `win.add` `<Control>o`; `win.close` `<Control>w`; `win.paste` `<Control>v`; `win.show-help-overlay` `<Control>question` |
| Startup | `Gtk::Window.set_default_icon_name(APP_ID)`; i18n via gettext domain `switcheroo` |
| Multi-window | `present_main_window` builds a fresh `AppWindow` each time — the app is genuinely multi-window |

→ `lib/application.rb` (plus `lib/main.rb` for the one-expression launcher).
**Not present** — the current `lib/switcheroo/application.rb` is a skeleton
window with no actions, no accels, no open handling.

## data/resources/blueprints/window.blp + src/window.rs — the main window

`template $AppWindow : Adw.ApplicationWindow`, 750×750 default, 300×300
minimum, title "Switcheroo". Root chain: `Box(vertical)` → `$DragOverlay` →
`Adw.ToastOverlay` → `Adw.NavigationView` with two pages (`main`,
`all_images`).

| Widget | × | CSS | Signals / behaviour | Notes |
|---|---:|---|---|---|
| `Adw.ApplicationWindow` | 1 | — | `close-request` → `close_dialog` when a conversion is running, else saves window size | geometry persisted to GSettings |
| `Adw.ToastOverlay` | 1 | — | `add_toast` | all toasts below |
| `Adw.NavigationView` | 1 | — | `push_by_tag("all_images")` | two pages |
| `Adw.NavigationPage` | 2 | — | tags `main` / `all_images`, titles "Switcheroo" / "All Images" | |
| `Adw.ToolbarView` | 2 | — | — | one per page |
| `Adw.HeaderBar` | 2 | — | `show-title: false` on the main one | |
| `Gtk::Button` `add_button` | 1 | `flat` | `clicked` → `add_dialog`; starts `visible: false`, shown only on the convert stack | icon `plus-large-symbolic`, tooltip "Add Images (Ctrl+O)" |
| `Gtk::Button` `other_add_button` | 1 | `flat` | `clicked` → `add_dialog` | the All Images header's copy |
| `Gtk::MenuButton` | 1 | — | `primary: true`, `menu-model: primary_menu` | icon `open-menu-symbolic`, tooltip "Primary Menu" |
| `Gtk::WindowHandle` | 2 | — | — | drag-the-window surface per page |
| `Gtk::Stack` `stack` | 1 | — | `crossfade`; 5 pages | the main state machine |
| `Gtk::Stack` `all_images_stack` | 1 | — | `crossfade`; 2 pages | All Images / loading |

**Window `win.*` actions** (all installed in `setup_gactions`):
`win.close` (destroy), `win.add` (file chooser), `win.clear` (reset to welcome),
`win.show-help-overlay`, `win.about`, `win.paste` (clipboard import).

**Toasts**: "Unable to access dropped files", "Unsupported filetype",
"Error copied to clipboard", "Converting Cancelled", and "Image converted"
with an **Open** button that opens the result through the XDG OpenURI portal
(directory vs file variant).

→ `lib/app_window.rb`. **Not present.**

### `stack` page `stack_welcome_page` — empty state

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.StatusPage` | 1 | `icon-dropshadow` | — | icon = app id, title "Switcheroo", description "Drag and drop images here" |
| `Gtk::Box` | 1 | — | — | vertical, spacing 12 |
| `Gtk::Button` `open_button` | 1 | `suggested-action`, `pill` | `clicked` → `add_dialog` | label "_Open Images…", mnemonic |

### `stack` page `stack_loading` — loading state

`Adw.StatusPage` + `Gtk::Spinner loading_spinner` (32×32, `start()`/`stop()`).

### `stack` page `stack_invalid_image` — error state

`Adw.StatusPage invalid_image`, icon `im-symbolic`, title "Could not Load
Image", description "This image could be corrupted or may use an unsupported
file format."

### `stack` page `stack_convert` — the options page

`Adw.Bin` → `Adw.Bin` → `Adw.PreferencesPage` with four groups.

| Widget | × | CSS | Signals / behaviour | Notes |
|---|---:|---|---|---|
| `Adw.PreferencesPage` | 1 | — | — | |
| `Adw.PreferencesGroup` | 4 | — | 4th is `valign: end`, `halign: center` | thumbnails / output / advanced / convert |
| `Gtk::FlowBox` `image_container` | 1 | — | `invalidate_filter`; `max-children-per-line` 1/2/3 and `hexpand`+`halign` recomputed by file count | homogeneous, 12px gaps, `selection-mode: none` |
| `Adw.ComboRow` `output_filetype` | 1 | `output-filetype-drop` | `notify::selected` → `update_advanced_options` + `update_compression_options` + `update_resize` | title "Export Format", model rebuilt from `FileType::output_formats()` (13 entries) |
| `Gtk::StringList` `supported_output_filetypes` | 1 | — | — | model, replaced at runtime |
| `Adw.ActionRow` `single_pdf` | 1 | — | visible only when PDF is selected | title "Save as multi-page PDF" |
| `Gtk::Switch` `single_pdf_value` | 1 | — | `notify::state` → `update_compression_options` | |
| `Adw.ActionRow` `output_compression` | 1 | — | visible when multiple files/frames and not a single-PDF export | title "Save To ZIP" |
| `Gtk::Switch` `output_compression_value` | 1 | — | — | ZIP vs directory |
| `Adw.ActionRow` `quality_row` | 1 | — | visible only for lossy outputs | title "Quality" |
| `Gtk::Scale` `quality` | 1 | — | `accessibility labelled-by: quality_row` | `Gtk::Adjustment percentage` 1–100 step 1, `draw-value`, value at right |
| `Adw.ActionRow` `bgcolor_row` | 1 | — | visible when input has alpha and output does not | title "Background Color", subtitle "Replaces original transparency layer" |
| `Gtk::ColorDialogButton` `bgcolor` | 1 | — | — | `Gtk::ColorDialog` with alpha, initial `#00000000` |
| `Adw.ActionRow` `dpi_row` | 1 | — | visible for vector/PDF inputs | title "Pixel Density Per Inch" |
| `Gtk::Entry` `dpi_value` | 1 | — | — | inside an `Adw.Bin` |
| `Adw.ActionRow` `resize_amount_row` | 1 | — | — | title "Resize" |
| `Gtk::Entry` `resize_width_value` | 1 | — | `changed` → `update_height_from_width` | pixel mode, placeholder/tooltip "Width", `input-purpose: digits`, 8 chars |
| `Gtk::Entry` `resize_height_value` | 1 | — | `changed` → `update_width_from_height` | pixel mode, "Height" |
| `Gtk::Entry` `resize_scale_width_value` | 1 | — | — | percentage mode |
| `Gtk::Entry` `resize_scale_height_value` | 1 | — | — | percentage mode |
| `Gtk::ToggleButton` `link_axis` | 1 | `raised`, `circular`, `lock` | `clicked` toggles icon `chain-link-symbolic` ⇄ `chain-link-loose-symbolic` and re-derives the paired value | tooltip "Preserve aspect ratio", starts active |
| `Gtk::DropDown` `resize_type` | 1 | `flat`, `unit-drop` | `notify::selected` → `update_resize` | `Gtk::StringList resize_types` = "%", "px"; a11y label "Choose between resizing with percentages or using exact pixels" |
| `Adw.ActionRow` `resize_filter_row` | 1 | — | hidden when the output cannot use it | title "Resize Algorithm" |
| `Gtk::Box` (filter) | 1 | `linked` | — | holds the two toggles |
| `Gtk::ToggleButton` `resize_filter_default` | 1 | — | — | label "Default", starts active |
| `Gtk::ToggleButton` `resize_filter_pixel` | 1 | — | — | label "Pixel Art" (`-filter Point`) |
| `Adw.ActionRow` `strip_row` | 1 | — | visible when the output supports metadata | title "Remove Metadata" |
| `Gtk::Switch` `strip` | 1 | — | — | `-auto-orient -strip` |
| `Gtk::Button` `convert_button` | 1 | `suggested-action`, `pill`, `long` | `clicked` → `save_files` | label "_Convert", desensitised while converting |

Repeaters: `image_container` is filled by `update_image_container(count,
remaining_visible)` with up to 5 `ImageThumbnail`s wrapped in
`Gtk::FlowBoxChild` (each given an a11y `Property::Label` of the caption), a
blank `FlowBoxChild` placeholder per removed index, and one `ImageRest` tail
when more than 5 files are loaded.

Conditional rows: `quality_row`, `bgcolor_row`, `dpi_row`, `strip_row`,
`resize_filter_row`, `single_pdf`, `output_compression`, and the four resize
entries plus `link_axis` are all shown/hidden from the selected output and the
input file types. **Upstream's visibility toggling is driven by real format
capability, not by empty data** — it is behaviour to port, not the house rule
against data-driven visibility.

→ `lib/convert_page.rb` (the options page, extracted from the window — well
over ten widget methods on its own). **Not present.**

### `stack` page `stack_converting` — progress state

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.StatusPage` | 1 | — | — | title "Converting", description "This could take a while" |
| `Gtk::Box` | 1 | — | — | vertical, spacing 36 |
| `Gtk::ProgressBar` `progress_bar` | 1 | — | text set to `"{done}/{total}"`, or "Collecting files" | initial text "Loading…", `show-text` |
| `Gtk::Button` `cancel_button` | 1 | `destructive-action`, `pill` | `clicked` → `convert_cancel` | label "_Cancel" |

### `all_images_stack` page `all_images` — the All Images navigation page

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk::ScrolledWindow` | 1 | — | — | |
| `Gtk::FlowBox` `full_image_container` | 1 | — | rebuilt by `update_full_image_container`; one `ImageThumbnail` per file, `remove-clicked` → `remove_file` | `max-children-per-line: 4`, 16px margins, 12px gaps |
| `Gtk::Spinner` `loading_spinner_images` | 1 | — | — | on the page's own `stack_loading` |

→ `lib/all_images_page.rb`. **Not present.**

### window.blp `help_overlay` — keyboard shortcuts dialog

`Adw.ShortcutsDialog` with one `Adw.ShortcutsSection` "General" and six
`Adw.ShortcutsItem`s: Show Shortcuts (`win.show-help-overlay`), Quit
(`app.quit`), New Window (`app.new-window`), Clear Window (`win.clear`), Paste
From Clipboard (`win.paste`), Add Images (`win.add`). Presented by
`show_help_overlay`.

→ `lib/shortcuts_dialog.rb`. **Not present.**

### window.blp `primary_menu` — the hamburger menu model

`Gio::Menu`, two sections, five items: Paste From Clipboard (`win.paste`), New
Window (`app.new-window`), Clear Window (`win.clear`) | Keyboard Shortcuts
(`win.show-help-overlay`), About Switcheroo (`win.about`).

→ `lib/primary_menu.rb`. **Not present.**

## src/drag_overlay.rs — the drag-and-drop overlay

`$DragOverlay : Adw.Bin`, CSS name `dragoverlay`. Internals: a
`Gtk::Overlay`, a `Gtk::Revealer` (crossfade, `can-target: false`, revealed on
`notify::current-drop`) holding an `Adw.StatusPage` with icon
`document-send-symbolic` and CSS class `drag-overlay-status-page`. Properties
`title` ("Drop Here to Open"), `child`, `drop-target`. The window attaches a
`Gtk::DropTarget` named `file-drop-target`, action `COPY`, format
`Gdk::FileList`, whose `drop` handler calls `open_files` or toasts "Unable to
access dropped files".

→ `lib/drag_overlay.rb`. **Not present.**

## src/widgets/image_thumbnail.rs + blueprints/image-thumbnail.blp — one image tile

`$ImageThumbnail : Gtk::Widget` with a custom `measure` (clamps to 150×150
horizontally when dimensions are known) and `size_allocate`.

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| root | 1 | `card`, `image-thumbnail` (added in code) | — | `overflow: hidden` |
| `Gtk::Box` `root` | 1 | `card-content` | — | 60px radius |
| `Gtk::Box` `child` | 1 | `image-container` | — | |
| `Gtk::Overlay` | 1 | — | — | |
| `Gtk::Box` | 3 | — | — | vertical wrapper, picture row, caption centring box |
| `Gtk::Picture` `picture` | 1 | — | — | 150×150, `content-fit: cover`; shown when a texture loaded |
| `Gtk::Image` `image` | 1 | — | — | 150×150, `icon-size: large`, `image-symbolic`; shown when no texture |
| `Adw.Bin` (caption) | 1 | `image-caption`, `caption` | — | `overflow: hidden` |
| `Gtk::Label` `content` | 1 | — | — | caption `"JPG · 1920×1080"` |
| `Gtk::Button` `remove_image` | 1 | `circular`, `image-remove`, `osd` | `clicked` → `remove_file(index)` | overlay, `valign: start`, `halign: end`, icon `user-trash-symbolic`, tooltip "Remove image" |

Properties: `image` (write-only `Gdk::Texture`), `content`, `width`, `height`
(write-only), `remove` (read-only). Picture/Image visibility swap on the
`image` property.

→ `lib/image_thumbnail.rb`. **Not present.**

## src/widgets/image_rest.rs + blueprints/image-rest.blp — the "+N more" tile

`$ImageRest : Gtk::FlowBoxChild`, `focusable: false`, CSS `no-padding`.
`Adw.Bin` → `Gtk::Button image` (150×150, icon
`view-more-horizontal-symbolic`, CSS `image-container`, `card`,
`image-rest-button`, tooltip "Show {} more images") → vertical `Gtk::Box` with
`Gtk::Label content` (CSS `large_number`, text `"+{N}"`) and a `Gtk::Label`
"Show All". `clicked` pushes the `all_images` navigation page.

→ `lib/image_rest.rb`. **Not present.**

## src/widgets/about_window.rs — the About dialog

`Adw.AboutDialog::from_appdata` on the bundled metainfo, plus developers,
`translator-credits`, two `add_other_app` entries (Impression "Create bootable
drives", Footage "Polish your videos"), two acknowledgement sections ("Code and
Design Borrowed from" with 7 projects, "Sample Image from"), and a legal
section for ImageMagick (MIT/X11). Fired by `win.about`.

→ `lib/about_dialog.rb`. **Not present.**

## src/window.rs — the "Stop converting?" alert (two call sites)

`Adw.AlertDialog`, heading "Stop converting?", body "You will lose all
progress.", responses `cancel` "_Cancel" and `stop` "_Stop" (destructive).
Raised both by `close-request` while converting (stops jobs, then closes the
window) and by `cancel_button` (stops jobs, returns to the convert page, toasts
"Converting Cancelled").

→ `lib/stop_converting_dialog.rb`. **Not present.**

## src/window.rs — the "Error While Processing" alert

`Adw.AlertDialog`, heading "Error While Processing", `extra_child` a
`Gtk::ScrolledWindow` (CSS `card`, min 200 / max 400 content height) holding a
`Gtk::Label` (CSS `monospace`, 12px margins, `xalign`/`yalign` 0, wrap
`WordChar`) with the ImageMagick stderr. Responses `ok` "_Close" and `copy`
"_Copy to Clipboard" (suggested); copy puts the text on the clipboard and
toasts "Error copied to clipboard". Returns to the convert page.

→ `lib/error_dialog.rb`. **Not present.**

## src/file_chooser.rs — the three file dialogs

| Dialog | Detail |
|---|---|
| Open | `Gtk::FileDialog`, `open_multiple`, accept label "_Select Images", modal, default filter "Images" built from every input MIME type |
| Save file | `Gtk::FileDialog.save`, filter = the chosen output MIME, initial name `<stem>.<ext>`, initial folder = the first input's directory; validates the chosen extension and errors with "Unspecified filetype" / "Unknown filetype" / "Used the wrong filetype" |
| Select folder | `Gtk::FileDialog.select_folder` for directory output |

Also `load_files`, which rejects non-input types with "Unsupported filetype".

→ `lib/file_chooser.rb`. **Not present.**

## src/filetypes.rs — the format table

`FileType` (15: PNG JPEG JPG WEBP SVG HEIF HEIC BMP AVIF JXL TIFF PDF GIF ICO
DDS + Unknown) with `is_input`, `is_output`, `supports_animation`, `is_lossy`,
`supports_alpha`, `supports_metadata`, `supports_pixbuf`, MIME/extension/
display-string mappings; 13 output formats in the combo row's order.
`OutputType` (File / Compression) and `CompressionType` (Zip / Directory). This
table is what every conditional row above keys off, so it is user-facing.

→ `lib/file_type.rb`. **Not present.**

## src/input_file.rs — the loaded-image model

A `GObject` with `path`, `kind` (`FileType`), `pixbuf` (`Gdk::Texture`),
`frame_count`, `is_behind_sandbox`, `width`, `height`; held in a
`Gio::ListStore`. Backs the thumbnails, the captions, the frame counting and
the aspect-ratio arithmetic.

→ `lib/input_file.rb`. **Not present.**

## src/magick.rs + src/temp.rs + src/color.rs — the conversion backend

`count_frames` (`magick identify`, parses frame count and `WxH` dimensions),
`MagickConvertJob` (`-filter`, `-strip -auto-orient`, `-resize W%xH%` or
`WxH!`, `-quality`, `-density`, `-background`/`-flatten`, first-frame
selection), `generate_job`, `wait_for_child` with a cancellable
`SharedChild`, the `zip` binary for ZIP output, `JobFile` naming, temp dirs
(sandbox-aware, under `XDG_CACHE_HOME/tmp` when flatpaked) and `Color`
↔ `Gdk::RGBA` with `#rrggbbaa` formatting.

→ `lib/magick.rb`, `lib/temp_dir.rb`, `lib/color.rb`. **Not present.**

## data/io.gitlab.adhami3310.Converter.gschema.xml.in — persisted settings

Keys: `window-width` 750, `window-height` 750, `is-maximized` false, `quality`
92, `dpi` 300, `output-format` enum (13 values, default `Jpg`),
`compression-format` enum (Zip/Dir, default `Dir`), `resize-type` enum
(Percentage/ExactPixels, default `Percentage`). Read in `load_window_size` /
`load_options` / `load_selected_output` / `load_selected_compression`, written
on close and on convert.

Following the pilot (`gnome-contacts-rb/lib/settings.rb`), this becomes a JSON
file under `XDG_CONFIG_HOME` with the same keys and defaults, so the port runs
from a checkout without installing a compiled schema.

→ `lib/settings.rb`. **Not present.**

## data/resources/style.css — the stylesheet

19 rules the widgets above reference by class: `dragoverlay`,
`.drag-overlay-status-page`, `.card-content`, `flowboxchild:focus`,
`.image-caption`, `.image-remove` (+`:focus`, +`prefers-contrast: more`),
`.image-rest-button:focus`, `value`, `.lock`, `.large_number`,
`.unit-drop .menu contents`, `.long`, `.no-padding`,
`.output-filetype-drop popover > contents`, and two `row.property` label rules.
Loaded through a `Gtk::CssProvider` (upstream holds one in the window struct).

→ `lib/style.rb` (the CSS as a heredoc plus the provider). **Not present.**

## data/resources/icons/…/actions/*.svg — bundled symbolic icons

Seven app-shipped symbolics the widgets name directly:
`chain-link-symbolic`, `chain-link-loose-symbolic`, `im-symbolic`,
`image-symbolic`, `plus-large-symbolic`, `user-trash-symbolic`,
`view-more-horizontal-symbolic`. Upstream registers them by adding
`PKGDATADIR/icons` to the `Gtk::IconTheme` search path.

→ `data/icons/` + a search-path call in `lib/application.rb`. **Not present.**

## po/ — translations

19 languages (`po/LINGUAS`: ar bg cs de es fr hi hr it ka kw nl oc pt pt_BR ru
sv tr uk) against `po/switcheroo.pot`, domain `switcheroo`. `POTFILES.in`
covers the desktop file, the gschema, the metainfo, both translatable
blueprints and five Rust files. Strings include one `C_("shortcut window", …)`
context and two `gettext("…").replace("{}", …)` plural-ish forms in
`image_rest.rs`.

→ `po/` carried over as-is; the port's strings must match the catalogue's
msgids. **Not present.**

## data/io.gitlab.adhami3310.Converter.desktop.in.in — shell integration

14 MIME types registered, `DBusActivatable=true`, and a `new-window` desktop
action ("New Window", icon `window-new`, `--new-window`).

→ `data/switcheroo.desktop`. **Not present.**

---

## Blockers

- **ImageMagick is a hard runtime dependency.** Every conversion shells out to
  `magick`; `magick identify` also supplies frame counts and dimensions. This
  ports as `Open3`/`spawn` rather than a library binding, and the port is
  useless without the binary on `PATH`.
- **ZIP output needs the `zip` binary** (`ZIP_BINARY_NAME`), the same way.
- **Upstream's tokio runtime and `SharedChild` cancellation have no Ruby
  equivalent.** The port needs `GLib::Timeout`/`Thread` + `Process.kill` with
  the GTK main loop, which changes the cancellation and progress plumbing even
  though the UI stays identical.
- **The XDG portals are not in the Ruby bindings.** `ashpd` is used for
  `is_sandboxed()` (temp-dir placement) and for the OpenFile/OpenDirectory
  requests behind the "Open" button on the success toast. The toast and its
  button port; the portal call has to fall back to `Gio::AppInfo.launch_default_for_uri`.
- **`Adwaita::Application` / `Adwaita::ApplicationWindow` quirk.** Upstream
  subclasses `adw::Application` and `adw::ApplicationWindow`; per the
  `ruby-gtk` skill the port must use `Gtk::Application` with an
  `Adwaita::ApplicationWindow`, and `Adwaita::Application` is off the table.
- **GSettings schema compilation.** Running from a checkout cannot rely on an
  installed schema, so the eight keys move to a JSON settings file (pilot
  precedent) — same keys, same defaults, different storage.
- **Custom widget layout.** `ImageThumbnail` overrides `measure` and
  `size_allocate` to clamp tiles to 150×150. Overriding GTK vfuncs from a Ruby
  subclass is unreliable; the port will have to approximate with size requests
  and `Gtk::AspectFrame`/`Adwaita::Bin` wrapping.
- **`Adw.AboutDialog.from_appdata`** reads the metainfo out of a GResource
  bundle. The port has no GResource, so the About dialog's fields must be
  written out literally.
- **Accessibility `update_property` / blueprint `accessibility` blocks** (the
  `labelled-by` on the quality scale, the resize-type label, the per-thumbnail
  flow-box-child labels) may not be reachable from the Ruby bindings; worth
  attempting, not worth blocking on.
