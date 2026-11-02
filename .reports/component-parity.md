# Component parity — Switcheroo-rb

| | |
|---|---|
| Upstream | `origin/main` @ `ae72daf9fefe` |
| Port | `ruby` @ `e50a6654ab1c` |
| Units | 17 |
| Units with parity | **0 / 17** |

Nothing authorises a skip. Every row below is either `parity` — with the port
file and line that proves it — or **gap**. There is no third state, and no
sentence in `lib/` creates one.

**The text axis fails in every single unit**, for one reason: the port contains
**zero** translation markers. `grep -rE '\b(_|N_|C_|NC_|n_|p_|s_|np_|ngettext|pgettext)\(' lib/ exe/`
returns nothing. Every user-visible string is a bare Ruby literal. So the
`Text` column below is `✗` wherever the widget shows text, in all 17 units, and
is not repeated in prose per unit. The 91 msgid rows are itemised in
`.reports/translation-parity.md`.

---

## Unit: application object — `src/main.rs` + `src/application.rs` → `lib/application.rb`, `lib/main.rb`

| Item | Up | Port | Verdict |
|---|---|---|---|
| App id `io.gitlab.adhami3310.Converter` | ✓ | `lib/application.rb:51` | parity |
| `HANDLES_OPEN` flag | ✓ | `lib/application.rb:58` | parity |
| `--new-window` main option + local handling | ✓ | `lib/application.rb:65`, `:119` | parity |
| `app.quit`, `app.new-window` | ✓ | `lib/application.rb:132`, `:137` | parity |
| 7 accelerators | ✓ | `lib/application.rb:36-44` | parity |
| Icon search path | ✓ | `lib/application.rb:158` | parity |
| Base class `adw::Application` | ✓ | `Gtk::Application` + `Adwaita.init` (`lib/application.rb:79`) | **gap** — see `accountability-ensurance.md` hit 1 |
| `gettext` text domain actually in effect | ✓ `src/main.rs` | `lib/application.rb:170` binds a domain no string looks up | **gap** |
| GResource bundle registration | ✓ | none | correspondence — no bundle; assets read from `data/` |

## Unit: main window — `window.blp` ($AppWindow shell) + `src/window.rs` → `lib/app_window.rb`

| Widget | Up × | Port × | CSS | Signals / actions | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Adw.ApplicationWindow` | 1 | 1 | — | ✓ `close-request` | ✗ | **gap** (text) |
| `Gtk.Box` (root) | 1 | 1 | — | — | — | parity |
| `Adw.ToastOverlay` | 1 | 1 | — | — | — | parity |
| `Adw.NavigationView` | 1 | 1 | — | — | — | parity |
| `Adw.NavigationPage` (main) | 1 | 1 | — | — | ✗ | **gap** (text) |
| `Adw.ToolbarView` | 1 | 1 | — | — | — | parity |
| `Adw.HeaderBar` | 1 | 1 | — | — | — | parity |
| `Gtk.Button` (add) | 1 | 1 | ✓ `flat` | `clicked` upstream → `win.add` here | ✗ | **gap** (text); signal is a correspondence (`lib/app_window.rb:174`) |
| `Gtk.MenuButton` | 1 | 1 | — | ✓ menu-model, `primary` | ✗ | **gap** (text) |
| `Gtk.WindowHandle` | 1 | 1 | — | — | — | parity |
| `Gtk.Stack` (5 pages) | 1 | 1 | — | — | — | parity |
| `Gtk.FlowBoxChild` | 4 | 4 | — | — | — | parity |
| `Gtk.DropTarget` | 1 | 1 | — | ✓ `drop`, `notify::current-drop` | — | parity |
| `Adw.Toast` | 6 sites | 6 sites | — | ✓ `button-clicked` | ✗ | **gap** (text) |

Actions: upstream installs `close add clear show-help-overlay about paste`
(`src/window.rs:279-337`); the port installs the same six
(`lib/app_window.rb:60`, built at `:271`). parity.

Behaviour verified by reading, matching upstream:
`close_request` saves geometry then holds the window open mid-run
(`lib/app_window.rb:929`); `is_canceled` initial value `true` is mirrored by
`Children#initialize` setting `@canceled = true` (`lib/magick.rb:302`);
`remove_file` keeps the store and records the index (`:493`);
`construct_short_thumbnail` look-ahead (`:519`); the 1–2 / 3+ flow-box width
switch (`:601`).

| Gap | Detail |
|---|---|
| **gap** | `New transparency layer color: {}` — upstream refreshes the colour button's accessible label on every pick (`src/window.rs:525-530`). The port connects **no** `notify::rgba` handler at all. One upstream signal (`rgba-notify`) has nothing opposite it, and a screen-reader user is told nothing about the colour they chose. |
| **gap** | `Unknown IO error happened` — upstream's `wait_for_child` reports this translated string when the spawn itself fails (`src/magick.rs:301`). The port reports `"#{command.first}: #{e.message}"` (`lib/magick.rb:538`), an interpolated, untranslatable string with different content. |
| extra, explained | The port calls `convert_clean` from both the cancel dialog and the close dialog (`lib/app_window.rb:918`, `:930`); upstream leaves the temp directory behind in those two paths. Strictly better; recorded so it is not mistaken for a misread. |

Signal axis reconciliation (set, not count, per the skill):
upstream 7 `clicked` → port 4 `clicked` + 3 buttons carrying `action-name="win.add"`
(`lib/welcome_page.rb:48`, `lib/app_window.rb:174`, `lib/all_images_page.rb:73`).
Both reach `add_dialog`; correspondence, located. Upstream
`single_pdf_value.connect_state_notify` (`src/window.rs:385`) → port
`notify::active` (`lib/convert_page.rb:473`): correspondence on a `Gtk::Switch`,
where `state` and `active` coincide absent a `::state-set` handler, and neither
side has one.

## Unit: convert page — `window.blp` `stack_convert` + `window.rs` option handlers → `lib/convert_page.rb`

| Widget | Up × | Port × | CSS | Signals | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Adw.PreferencesPage` | 1 | 1 | — | — | — | parity |
| `Adw.PreferencesGroup` | 4 | 4 | — | — | — | parity |
| `Adw.Bin` | 4 | 2 | — | — | — | correspondence: the two outer property-less `Adw.Bin`s wrapping the `PreferencesPage` (`window.blp:116-118`) are pure layout wrappers the port builds the page without; `dpi_bin` and `resize_type_bin` are both present |
| `Gtk.FlowBox` | 1 | 1 | — | ✓ filter func | — | parity |
| `Adw.ComboRow` | 1 | 1 | ✓ `output-filetype-drop` | ✓ `notify::selected` | ✗ | **gap** (text) |
| `Adw.ActionRow` | 8 | 8 | — | — | ✗ | **gap** (text) |
| `Gtk.Switch` | 3 | 3 | — | ✓ | — | parity |
| `Gtk.Scale` | 1 | 1 | — | — | — | parity |
| `Gtk.ColorDialogButton` | 1 | 1 | — | ✗ `notify::rgba` | — | **gap**: accessible label never updated |
| `Gtk.Entry` | 5 | 5 | — | ✓ `changed` ×4 | ✗ | **gap** (text: placeholders and tooltips) |
| `Gtk.ToggleButton` | 3 | 3 | ✓ `raised` `circular` `lock`, `linked` | ✓ `clicked`, `toggled` ×2 | ✗ | **gap** (text) |
| `Gtk.DropDown` | 1 | 1 | ✓ `flat` `unit-drop` | ✓ `notify::selected` | ✗ | **gap** (text: `%`, `px`, and the accessibility label) |
| `Gtk.Box` | 3 | 3 | ✓ `linked` | — | — | parity |
| `Gtk.Button` (Convert) | 1 | 1 | ✓ `suggested-action` `pill` `long` | ✓ `clicked` | ✗ | **gap** (text) |

Also **gap**: `window.blp:155-159` attaches `accessibility { labelled-by: quality_row }`
to the quality `Scale`, and `window.blp:245` an `accessibility { label: … }` to
`resize_type`. Neither is reproduced; `grep -n 'accessib' lib/convert_page.rb`
finds only the comment at `:33` explaining their absence.

## Unit: welcome page → `lib/welcome_page.rb`

| Widget | Up × | Port × | CSS | Signals | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Adw.StatusPage` | 1 | 1 | ✓ `icon-dropshadow` | — | ✗ | **gap** (text ×2) |
| `Gtk.Box` | 1 | 1 | — | — | — | parity |
| `Gtk.Button` | 1 | 1 | ✓ `suggested-action` `pill` | `clicked` → `win.add` (correspondence) | ✗ | **gap** (text) |

## Unit: loading page → `lib/loading_page.rb`

`Adw.StatusPage` 1/1, `Gtk.Spinner` 1/1 at 32×32 with `valign`/`halign` centre.
No text. **parity** — the only unit whose failure is not the text axis, and it
has no text to fail on.

## Unit: invalid-image page → `lib/invalid_image_page.rb`

`Adw.StatusPage` 1/1, icon `im-symbolic`, `hexpand`/`vexpand`. Title and
description bytes match upstream. Text ✗. **gap** (text ×2).

## Unit: converting page → `lib/converting_page.rb`

| Widget | Up × | Port × | CSS | Signals | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Adw.StatusPage` | 1 | 1 | — | — | ✗ | **gap** (text ×2) |
| `Gtk.Box` | 1 | 1 | — | — | — | parity |
| `Gtk.ProgressBar` | 1 | 1 | — | — | ✗ | **gap** (text: "Loading…", "Collecting files") |
| `Gtk.Button` | 1 | 1 | ✓ `destructive-action` `pill` | ✓ `clicked` | ✗ | **gap** (text) |

`done/total` progress text is a number pair on both sides, correctly left
unmarked. `set_convert_progress` / `set_collecting_progress` both reproduced
(`lib/converting_page.rb:43`, `:50`).

## Unit: all-images page → `lib/all_images_page.rb`

Widgets 10/10 — `Adw.NavigationPage`, `Adw.ToolbarView`, `Adw.HeaderBar`,
`Gtk.Button` (`flat`), `Gtk.WindowHandle`, `Gtk.Stack`, `Gtk.ScrolledWindow`,
`Gtk.FlowBox`, `Adw.StatusPage`, `Gtk.Spinner`. CSS ✓. Signals ✓ (filter func,
`win.add`). Text ✗ ("All Images", "Add Images (Ctrl+O)"). **gap** (text).

## Unit: drag overlay — `src/drag_overlay.rs` → `lib/drag_overlay.rb`

| Widget | Up × | Port × | CSS | Signals | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Adw.Bin` (self) | 1 | 1 | `css-name` `dragoverlay` → class `dragoverlay` | — | — | correspondence, located: `lib/drag_overlay.rb:32`, rule at `lib/style.rb:35` matches both selectors |
| `Gtk.Overlay` | 1 | 1 | — | — | — | parity |
| `Gtk.Revealer` | 1 | 1 | — | ✓ `can_target false`, crossfade | — | parity |
| `Adw.StatusPage` | 1 | 1 | ✓ `drag-overlay-status-page` | — | ✗ | **gap** (text: "Drop Here to Open") |
| `Gtk.DropTarget` | 1 | 1 | — | ✓ `notify::current-drop`, one-at-a-time swap with handler disconnect | — | parity |

The `child`/`title`/`drop-target` GObject properties upstream declares are
plain Ruby accessors here — correspondence, `lib/drag_overlay.rb:48`, `:56`.

## Unit: image thumbnail — `image-thumbnail.blp` + `image_thumbnail.rs` → `lib/image_thumbnail.rb`

| Widget | Up × | Port × | CSS | Signals | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| root | `Gtk.Widget` subclass | `Adwaita::Bin` | ✓ `card` `image-thumbnail` | — | — | correspondence |
| `Gtk.Box` | 5 | 5 | ✓ `card-content`, `image-container` | — | — | parity |
| `Gtk.Overlay` | 1 | 1 | — | — | — | parity |
| `Gtk.Picture` | 1 | 1 | — | — | — | parity |
| `Gtk.Image` | 1 | 1 | — | — | — | parity |
| `Adw.Bin` (caption) | 1 | 1 | ✓ `image-caption` `caption` | — | — | parity |
| `Gtk.Label` | 1 | 1 | — | — | — | parity |
| `Gtk.Button` (remove) | 1 | 1 | ✓ `circular` `image-remove` `osd` | ✓ `clicked` | ✗ | **gap** (text: "Remove image") |

| Gap | Detail |
|---|---|
| **gap** | `measure()` is not reproduced. Upstream clamps **only the horizontal** orientation to min 150 / nat 150 and passes the vertical measure straight through (`src/widgets/image_thumbnail.rs:120-127`). The port sets `set_size_request(150, 150)` on both axes (`lib/image_thumbnail.rb:165`), so the tile's height is pinned at 150 instead of 150 + the caption strip, and the caption strip is squeezed against the picture. Every thumbnail in both flow boxes is affected. |
| **gap** | `size_allocate()` is not reproduced: upstream hands the full allocation to the root box (`:129-131`). Nothing in the port does. |
| **gap** | `Button remove_image { name: "remove_image"; }` (`image-thumbnail.blp:46`) — the widget name is dropped. `lib/image_thumbnail.rb:146` sets no `name`. A name is a selector handle and a test handle. |

## Unit: "+N" tile — `image-rest.blp` + `image_rest.rs` → `lib/image_rest.rb`

| Widget | Up × | Port × | CSS | Signals | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Gtk.FlowBoxChild` | 1 | 1 | ✓ `no-padding` | `focusable false` | — | parity |
| `Adw.Bin` | 1 | 1 | — | — | — | parity |
| `Gtk.Button` | 1 | 1 | ✓ `image-container` `card` `image-rest-button` | ✓ `clicked` | ✗ | **gap**: `icon-name: "view-more-horizontal-symbolic"` (`image-rest.blp:9`) dropped; and the tooltip is interpolated |
| `Gtk.Box` | 1 | 1 | — | — | — | parity |
| `Gtk.Label` | 2 | 2 | ✓ `large_number` | — | ✗ | **gap** |

| Gap | Detail |
|---|---|
| **gap** | `+{}` — upstream's msgid is literally `+{}` with the count substituted after lookup (`src/widgets/image_rest.rs:65`). The port writes `Gtk::Label.new("+#{@count}")` (`lib/image_rest.rb:71`). The msgid never reaches a catalogue. |
| **gap** | `Show {} more images` — same shape, upstream `:67`, port `lib/image_rest.rb:79` writes `"Show #{@count} more images"`. |
| **gap** | the button's `icon-name` is dropped, with the comment "the child is what GTK actually shows, so only the child is built here" (`lib/image_rest.rb:14`). The rendered result is the same, but the sentence is a reason in a reasoning slot; see `accountability-ensurance.md` hit 7. |

## Unit: About dialog — `src/widgets/about_window.rs` → `lib/about_dialog.rb`

| Item | Up | Port | Verdict |
|---|---|---|---|
| construction | `from_appdata(metainfo, VERSION)` | 10 fields set by hand (`lib/about_dialog.rb:74-87`) | **gap**, see below |
| developers | ✓ | ✓ `:30` | parity |
| translator credits | ✓ | ✓ `:85` | parity (text ✗) |
| 2 other apps | ✓ | ✓ `:32` | parity (text ✗) |
| 2 acknowledgement sections | ✓ | ✓ `:36` | parity (text ✗) |
| ImageMagick legal section | ✓ | ✓ `:62` | parity |

| Gap | Detail |
|---|---|
| **gap** | The appdata is not shipped, so everything `from_appdata` reads and the port does not re-set is gone from the dialog: the `<developer><name>` block ("Khaleel Al-Adhami", `metainfo:6-8`), the `<description>` paragraph, the donation URL (`https://opencollective.com/switcheroo`), the help / vcs-browser / translate / contribute URLs, and all **14 `<release>` entries** — so the About dialog has no "What's New" at all. |
| **gap** | `VERSION` is hardcoded to `'2.6.0'` (`lib/about_dialog.rb:19`) against upstream's `meson.build:3`. Nothing keeps the two in step, and upstream also appends `-devel` for the devel profile (`meson.build:38`), which the port has no notion of. |

## Unit: shortcuts dialog — `window.blp` `help_overlay` → `lib/shortcuts_dialog.rb`

`Adw.ShortcutsDialog` 1/1, `Adw.ShortcutsSection` 1/1, `Adw.ShortcutsItem` 6/6,
each with the same `action-name`. Widgets and actions **parity**.

| Gap | Detail |
|---|---|
| **gap** | All 7 strings upstream marks with `C_("shortcut window", …)` are bare literals here. These carry a **msgctxt**, so even once markers are added, `_()` would produce the wrong key — they need `p_("shortcut window", "General")` and friends. 7 keys, every one translated in up to 20 languages today. |

## Unit: primary menu — `window.blp` `menu primary_menu` → `lib/primary_menu.rb`

2 sections / 5 items, same labels, same actions, same order. Widgets and
actions **parity**; text ✗ on all five labels. **gap** (text).

## Unit: stop-converting alert → `lib/stop_converting_dialog.rb`

`Adw.AlertDialog` 1/1 at 2/2 call sites. Responses `cancel`/`stop`, `stop`
destructive, `response` handler acts only on `stop`. Behaviour **parity**;
text ✗ on all four strings. **gap** (text).

## Unit: error alert → `lib/error_dialog.rb`

`Adw.AlertDialog` 1/1, `Gtk.ScrolledWindow` 1/1 (`card`, 200–400), `Gtk.Label`
1/1 (`monospace`, wrap `word_char`, 12px margins, `xalign`/`yalign` 0). Every
property matches `src/window.rs:1463-1485`. Behaviour **parity**; text ✗ on
three strings. **gap** (text).

## Unit: file chooser — `src/file_chooser.rs` → `lib/file_chooser.rb`

`Gtk.FileDialog` 3/3, `Gtk.FileFilter` 2/2. Six strings present as literals and
byte-correct, none marked. **gap** (text).

## Stylesheet

`diff` of upstream `data/resources/style.css` against the heredoc in
`lib/style.rb`: identical rule for rule, 18 rules plus the
`prefers-contrast: more` block, with two deliberate differences — the commented-out
`background-color` in `.image-remove` is dropped (a comment, no effect) and
`dragoverlay` is written `dragoverlay, .dragoverlay` to cover the class
standing in for upstream's CSS node name. **Stylesheet: parity.** Every one of
the 14 app-namespaced classes attached in `lib/` has its rule. No variant
stylesheet upstream, so none owed.

## Not run

Steps 4 (screenshot) and 5 (drive the signals) of the skill were **not run**:
the port cannot be loaded in this environment (`require 'adwaita'` →
`LoadError`, and `require "switcheroo/rb"` from `spec/spec_helper.rb` →
`LoadError`, see `.reports/test-parity.md`). Every verdict above is from
reading, which is why the signal rows say "connected", not "fires". A handler
connected to a method that does nothing passes every check in this document.

## Axis totals

| Axis | Upstream distinct | Port distinct | In upstream, not in port |
|---|---:|---:|---:|
| Widget types | 30 | 29 | 1 (`Gtk.ApplicationWindow` — an `Adw.ApplicationWindow` ancestor row, struck) |
| CSS classes | 22 | 22 | 0 |
| Signals (sets, reconciled) | 10 | 9 | 1 (`rgba-notify`) |
| Actions | 8 | 8 | 0 |
| **Messages** | **91** | **0** | **91** |

The widget, CSS and action axes are nearly closed. The text axis is at zero and
the behaviour axis is one accessibility handler and three vfunc behaviours
short. That is the shape of a port whose UI is laid out and whose
internationalisation and accessibility were never started.
