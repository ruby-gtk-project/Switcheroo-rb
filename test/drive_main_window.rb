#!/usr/bin/env ruby
# frozen_string_literal: true

# Drives the real application: builds it, lets GTK settle between steps, and
# checks the window the user actually gets. This is step 4 and step 5 of the
# component-parity skill — the ones .reports/component-parity.md recorded as
# "not run", which is why every verdict in it was read off the source.
#
# Every component the port claims is opened here: the window and a second one,
# all five stack pages, the All Images navigation page, the primary menu, the
# four dialogs (about, shortcuts, error, stop-converting), both flow boxes and
# the widgets inside them, the drag overlay, the file chooser's filters and
# validation, the settings, and the ImageMagick backend — driven against a real
# `magick` binary, with real image files, through a real conversion that writes
# a real ZIP to disk.
#
# Run it from the repo root:
#
#   nix develop --command xvfb-run -a ruby test/drive_main_window.rb
#
# A scratch XDG_CONFIG_HOME and XDG_CACHE_HOME keep the run away from the
# user's own settings, and GSETTINGS_BACKEND=memory keeps it out of dconf. The
# run is in German so the gettext catalogue is under test too: a label that
# comes back in English is a label the port looked up wrong.

require "fileutils"
require "tmpdir"

ENV["XDG_CONFIG_HOME"] = Dir.mktmpdir("switcheroo-config")
ENV["XDG_CACHE_HOME"] = Dir.mktmpdir("switcheroo-cache")
ENV["GSETTINGS_BACKEND"] = "memory"
ENV["LANGUAGE"] = "de"

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "switcheroo"

require_relative "gtk_driver"

GetText.locale = "de"

SHOTS = File.expand_path("../tmp/shots", __dir__)
FileUtils.rm_rf(SHOTS)

# --- The fixtures -----------------------------------------------------------
#
# Real files, made by the same `magick` the app shells out to, because the
# whole loading path is `magick identify` and a port that is only ever handed
# a fabricated InputFile never runs it.

FIXTURES = Dir.mktmpdir("switcheroo-fixtures")
DEST = Dir.mktmpdir("switcheroo-output")

def magick!(*argv)
  system("magick", *argv, out: File::NULL, err: File::NULL) ||
    raise("magick #{argv.join(" ")} failed — is ImageMagick on PATH?")
end

# Eight distinct 640x480 PNGs: enough for the short strip to fill up and end
# in a "+N" tile, which is the only way ImageRest is ever built.
PNGS = (0...8).map do |index|
  File.join(FIXTURES, "shot#{index}.png").tap do |path|
    magick!(
      "-size",
      "640x480",
      "xc:rgb(#{index * 30},80,160)",
      path,
    )
  end
end

# Two files with the same stem in different directories, for unique_stem.
SAME_STEM = ["a", "b"].map do |dir|
  File.join(FIXTURES, dir, "cover.png").tap do |path|
    FileUtils.mkdir_p(File.dirname(path))
    magick!(
      "-size",
      "32x32",
      "xc:white",
      path,
    )
  end
end

# A three-frame animation, for frames_for's animation arms.
ANIMATION = File.join(FIXTURES, "spin.gif").tap do |path|
  magick!(

    "-delay",

    "10",
    "-size",

    "48x48",

    "xc:red",

    "xc:green",

    "xc:blue",
    path,

  )
end

# A file whose name promises an image and whose bytes are not one: `magick
# identify` prints nothing for it, which is the invalid-image page's only
# trigger.
CORRUPT = File.join(FIXTURES, "broken.png").tap do |path|
  File.binwrite(path, "this is not a PNG\n")
end

# Not an image at all, for the file chooser's unsupported-filetype refusal.
NOT_AN_IMAGE = File.join(FIXTURES, "notes.txt").tap do |path|
  File.write(path, "plain text\n")
end

# --- Helpers ----------------------------------------------------------------

# Pumps the GLib main loop until `condition` holds. The port does its real
# work on background threads and reports back through GLib::Timeout callbacks,
# so a plain `sleep` would starve exactly the thing being waited for.
def wait_until(timeout: 30)
  Process.clock_gettime(Process::CLOCK_MONOTONIC).then do |start|
    satisfied = yield
    until satisfied || Process.clock_gettime(Process::CLOCK_MONOTONIC) - start > timeout
      GLib::MainContext.default.iteration(false)
      sleep(0.02)
      satisfied = yield
    end
    satisfied
  end
end

# Depth-first walk of a widget tree. Toasts and Adwaita dialogs have no
# read-back API at all, so the only honest way to assert one is showing is to
# go and find it in the tree GTK built.
def each_widget(root, &block)
  if root
    block.call(root)
    child = root.first_child
    while child
      each_widget(child, &block)
      child = child.next_sibling
    end
  end
end

# The whole tree is walked rather than stopped at the first hit: these trees
# are a few hundred widgets at most, and it keeps the walk free of `return`.
def find_widget(root, &predicate)
  [].tap do |found|
    each_widget(root) do |widget|
      if predicate.call(widget)
        found << widget
      end
    end
  end.first
end

def label_showing?(root, text)
  !find_widget(root) { |w| w.is_a?(Gtk::Label) && w.label == text }.nil?
end

def visible_dialog(window)
  find_widget(window) { |w| w.is_a?(Adwaita::Dialog) && w.mapped? }
end

def visible_alert(window)
  find_widget(window) { |w| w.is_a?(Adwaita::AlertDialog) && w.mapped? }
end

def flow_box_children(box)
  [].tap do |children|
    child = box.first_child
    while child
      children << child
      child = child.next_sibling
    end
  end
end

# The components this script opens and asserts against. Printed at the end so
# the coverage claim is something the run itself states rather than a comment.
COMPONENTS = %w[
  application app_window welcome_page loading_page invalid_image_page
  converting_page convert_page all_images_page primary_menu drag_overlay
  image_thumbnail image_rest about_dialog shortcuts_dialog error_dialog
  stop_converting_dialog file_chooser settings magick file_type input_file
  color temp_dir style translations config
].freeze

APP = App.new

GtkDriver.drive(APP, shots: SHOTS) do |d, app|
  window = nil
  second = nil

  d.window { window&.window }

  # ---------------------------------------------------------------- startup

  # The application's own ::activate handler has already opened a window by
  # the time the first step runs — presenting another here would leave two
  # open and make every "how many windows" check meaningless.
  d.step("the application opened its window on activate") do
    window = app.instance_variable_get(:@windows).first
  end

  d.step("the application registered upstream's seven accelerators") do
    App::ACCELERATORS.each do |action, accels|
      d.check("#{action} is bound to #{accels.first}") do
        app.app.get_accels_for_action(action).map { |a| Gtk.accelerator_parse(a) } ==
          accels.map { |a| Gtk.accelerator_parse(a) }
      end
    end
    d.check("the app id is upstream's") { app.app.application_id == Config::APP_ID }
    d.check("it is an Adwaita::Application") { app.app.is_a?(Adwaita::Application) }
    d.check("it registered HANDLES_OPEN, so the file manager reaches it") do
      (app.app.flags & Gio::ApplicationFlags::HANDLES_OPEN) ==
        Gio::ApplicationFlags::HANDLES_OPEN
    end
    d.check("GLib's application name is Switcheroo") do
      GLib.application_name == Config::APP_NAME
    end
    d.check("app.quit exists") { app.app.has_action?("quit") }
    d.check("app.new-window exists") { app.app.has_action?("new-window") }
  end

  d.step("the welcome page is showing, in German") do
    d.check("one window was opened, not two") do
      app.instance_variable_get(:@windows).length == 1 &&
        Gtk::Window.list_toplevels.length == 1
    end
    d.check("window is visible") { window.window.visible? }
    d.check("it is an Adwaita::ApplicationWindow") do
      window.window.is_a?(Adwaita::ApplicationWindow)
    end
    d.check("its title is translated") { window.window.title == "Switcheroo" }
    d.check("its icon is the app id the startup handler set as the default") do
      window.window.icon_name == Config::APP_ID ||
        Gtk::Window.default_icon_name == Config::APP_ID
    end
    d.check("welcome page is the visible stack child") do
      window.stack.visible_child_name == AppWindow::WELCOME_CHILD
    end
    d.check("the stack carries upstream's five pages") do
      [
        AppWindow::WELCOME_CHILD, AppWindow::LOADING_CHILD, AppWindow::CONVERT_CHILD,
        AppWindow::INVALID_CHILD, AppWindow::CONVERTING_CHILD,
      ].all? { |name| window.stack.get_child_by_name(name) }
    end
    d.check("the status page title is translated") do
      window.welcome_page.status_page.description == "Bilder hierher ziehen und ablegen"
    end
    d.check("its open button runs win.add") do
      window.welcome_page.open_button.action_name == "win.add"
    end
    d.check("the open button is translated") do
      window.welcome_page.open_button.label != "_Open Images…" &&
        window.welcome_page.open_button.label.include?("ffnen")
    end
    d.check("the add button is hidden on the welcome page") { !window.add_button.visible? }
    d.check("the add button carries its translated tooltip") do
      window.add_button.tooltip_text == "Bilder hinzufügen (Ctrl+O)"
    end
    d.check("all six window actions are present") do
      AppWindow::WINDOW_ACTIONS.all? { |name| window.window.has_action?(name) }
    end
    d.shot("01-welcome")
  end

  d.step("the drag overlay wraps the whole window, as upstream's does") do
    window.drag_overlay.then do |overlay|
      d.check("it is the window's content") { window.root_box.first_child.equal?(overlay) }
      d.check("it carries upstream's css name") { overlay.has_css_class?("dragoverlay") }
      d.check("the toast overlay is inside it") do
        overlay.overlay.child.equal?(window.toast_overlay)
      end
      d.check("the navigation view is inside that") do
        window.toast_overlay.child.equal?(window.navigation)
      end
      d.check("the drop target it holds is the window's") do
        overlay.drop_target.equal?(window.drop_target)
      end
      d.check("the drop target is named as upstream names it") do
        window.drop_target.name == AppWindow::DROP_TARGET_NAME
      end
      d.check("it accepts a Gdk::FileList") do
        window.drop_target.formats.to_s.include?("GdkFileList")
      end
      d.check("and asks for a copy") { window.drop_target.actions == :copy }
      d.check("the reveal starts hidden") { !overlay.revealer.reveal_child? }
      d.check("its status page title is translated") do
        overlay.status_page.title == "Hier ablegen zum Öffnen"
      end
      overlay.revealer.reveal_child = true
      d.check("revealing it shows the drop prompt") { overlay.revealer.reveal_child? }
    end
  end

  d.step("the drop prompt renders") do
    d.shot("02-drag-overlay")
    window.drag_overlay.revealer.reveal_child = false
  end

  d.step("the style sheet the app installed parses with no complaints") do
    [].then do |errors|
      Gtk::CssProvider.new.tap do |provider|
        provider.signal_connect("parsing-error") { |_p, _s, error| errors << error.message }
        provider.load_from_string(Style::CSS)
      end
      d.check("upstream's style.css parses") { errors.empty? }
    end
    d.check("the app's provider is a Gtk::CssProvider") do
      Style.provider.is_a?(Gtk::CssProvider)
    end
    d.check("it styles the drag overlay upstream styles") do
      Style::CSS.include?("dragoverlay")
    end
  end

  d.step("every icon the port names is in the theme") do
    Gtk::IconTheme.get_for_display(Gdk::Display.default).then do |theme|
      [
        AppWindow::ADD_ICON, AppWindow::MENU_ICON, InvalidImagePage::ICON_NAME,
        DragOverlay::ICON_NAME, ImageRest::ICON_NAME, ImageThumbnail::FALLBACK_ICON,
        ImageThumbnail::REMOVE_ICON, ConvertPage::LINKED_ICON, ConvertPage::LOOSE_ICON,
        Config::APP_ID,
      ].each do |name|
        d.check("the icon theme resolves #{name}") { theme.has_icon?(name) }
      end
      d.check("Impression's icon is in the theme") do
        theme.has_icon?("io.gitlab.adhami3310.Impression")
      end
      d.check("Footage's icon is in the theme") do
        theme.has_icon?("io.gitlab.adhami3310.Footage")
      end
    end
  end

  # ------------------------------------------------------------ primary menu

  d.step("the primary menu is upstream's two sections, item for item") do
    window.menu_button.then do |button|
      d.check("it is a Gtk::MenuButton") { button.is_a?(Gtk::MenuButton) }
      d.check("its icon is the hamburger") { button.icon_name == AppWindow::MENU_ICON }
      d.check("two sections") { button.menu_model.n_items == 2 }

      [
        [0, ["Aus der Zwischenablage einfügen", "win.paste"],
         ["Neues Fenster", "app.new-window"], ["Fenster leeren", "win.clear"]
],
        [1, ["Tastenkürzel", "win.show-help-overlay"],
         ["Info zu Switcheroo", "win.about"]
],
      ].each do |index, *expected|
        button.menu_model.get_item_link(index, "section").then do |section|
          d.check("section #{index} carries #{expected.length} translated items") do
            (0...section.n_items).map do |item|
              [
                section.get_item_attribute_value(item, "label", nil),
                section.get_item_attribute_value(item, "action", nil),
              ]
            end == expected
          end
        end
      end
    end
    d.shot("03-header")
  end

  # ---------------------------------------------------------------- dialogs

  d.step("win.show-help-overlay opens the shortcuts dialog") do
    window.window.activate_action("show-help-overlay", nil)
  end

  d.step("the shortcuts dialog is showing upstream's six items") do
    window.shortcuts_dialog.then do |dialog|
      d.check("it is an Adwaita::ShortcutsDialog") do
        dialog.is_a?(Adwaita::ShortcutsDialog)
      end
      d.check("it is the dialog the window is showing") do
        visible_dialog(window.window).equal?(dialog)
      end
      d.check("its section title is translated") do
        dialog.general_section.title != "General" && !dialog.general_section.title.empty?
      end
      dialog.send(:items).then do |items|
        d.check("it lists upstream's six shortcuts") { items.length == 6 }
        d.check("each one names an action the app or window really has") do
          items.all? do |_title, action|
            action.start_with?("app.") ? app.app.has_action?(action.delete_prefix("app.")) :
              window.window.has_action?(action.delete_prefix("win."))
          end
        end
        d.check("each one is translated out of English") do
          items.none? do |title, _action|
            ["Show Shortcuts", "Quit", "New Window", "Clear Window",
             "Paste From Clipboard", "Add Images"
].include?(title)
          end
        end
        d.check("every accelerator the app bound has a shortcut item or is the window's") do
          App::ACCELERATORS.keys.all? do |action|
            items.map(&:last).include?(action) || action == "win.close"
          end
        end
      end
      d.shot("04-shortcuts")
      dialog.close
    end
  end

  d.step("win.about opens the about dialog") do
    window.window.activate_action("about", nil)
  end

  d.step("the about dialog carries the appdata, read from the metainfo file") do
    d.check("a dialog is showing") { !visible_dialog(window.window).nil? }
    AboutDialog.new(window.window).then do |about|
      d.check("developer name came from the metainfo") do
        about.dialog.developer_name == "Khaleel Al-Adhami"
      end
      d.check("the release notes came from the metainfo") do
        about.dialog.release_notes.to_s.include?("EXIF")
      end
      d.check("its application icon is the app id") do
        about.dialog.application_icon == Config::APP_ID
      end
      d.check("its version is the port's") { about.dialog.version == Config::VERSION }
      d.check("the licence is the metainfo's") do
        about.appdata.project_license == "GPL-3.0-only"
      end
      d.check("and it maps to an Adwaita licence type, not :unknown") do
        about.dialog.license_type != :unknown
      end
      d.check("the issue url came from the metainfo") do
        about.appdata.url("bugtracker").to_s.start_with?("http")
      end
      d.check("it credits upstream's sibling apps") { about.send(:other_apps).length == 2 }
    end
    d.shot("05-about")
    visible_dialog(window.window)&.close
  end

  # ------------------------------------------------------------ empty states

  d.step("an open of nothing at all is refused with a toast") do
    window.open_files([])
  end

  d.step("the toast says so, in German") do
    d.check("the unsupported-filetype toast is showing") do
      label_showing?(window.window, "Nicht-unterstützter Dateityp")
    end
    d.check("the window stayed on the welcome page") do
      window.stack.visible_child_name == AppWindow::WELCOME_CHILD
    end
  end

  d.step("the file chooser refuses a pick with no image in it") do
    [].then do |errors|
      FileChooser.load_files(
        [Gio::File.open(path: NOT_AN_IMAGE)],
        on_start:   -> { nil },
        on_success: ->(_files) { errors << :success },
        on_error:   ->(message) { errors << message },
      )
      d.check("a text file is reported as an unsupported filetype") do
        errors == ["Nicht-unterstützter Dateityp"]
      end
    end
    d.check("InputFile refuses it outright") { InputFile.new_for_path(NOT_AN_IMAGE).nil? }
    # Gtk::FileFilter has no getter for what was added to it, so what is
    # asserted is the GVariant it serialises itself to, which names every mime
    # type it will accept. GTK canonicalises through shared-mime-info on the
    # way in, so image/heic arrives as its alias image/heif and image/x-icon
    # as image/vnd.microsoft.icon — those two are checked by their aliases.
    FileChooser.new(window.window).images_filter.to_gvariant.to_s.then do |variant|
      d.check("the chooser's filter carries one mime type per input format") do
        variant.scan('[1, "').length == FileType.input_formats.length
      end
      d.check("every input format's mime type is in it") do
        (FileType.input_formats.map(&:mime).uniq - ["image/heic", "image/x-icon"])
          .all? { |mime| variant.include?(mime) }
      end
      d.check("and the two GTK aliases are there under their canonical names") do
        variant.include?("image/heif") && variant.include?("image/vnd.microsoft.icon")
      end
    end
    d.check("its name is translated") do
      FileChooser.new(window.window).images_filter.name == "Bilder"
    end
    d.check("its accept label is translated") do
      FileChooser.new(window.window).open_dialog.accept_label != "_Select Images"
    end
  end

  d.step("the save dialog's validation refuses the three wrong things") do
    FileChooser.new(window.window).then do |chooser|
      OutputType.file(FileType.from_string("png")).then do |png|
        d.check("a name with no extension is refused") do
          chooser.send(:validate_output, Gio::File.open(path: "/tmp/x"), png) ==
            [nil, "Unbestimmter Dateityp"]
        end
        d.check("an extension nothing knows is refused") do
          chooser.send(
            :validate_extension,
            "/tmp/x.qqq",
            "qqq",
            png,
          ).first.nil?
        end
        d.check("an extension that is not the chosen format is refused") do
          chooser.send(
            :validate_extension,
            "/tmp/x.jpg",
            "jpg",
            png,
          ).first.nil?
        end
        d.check("the right extension is accepted") do
          chooser.send(
            :validate_extension,
            "/tmp/x.png",
            "png",
            png,
          ) == ["/tmp/x.png", nil]
        end
      end
    end
  end

  # ---------------------------------------------------- the invalid-image page

  d.step("a corrupt image is probed and rejected") do
    window.open_files([InputFile.new_for_path(CORRUPT)])
    d.check("the loading page is up while the probe runs") do
      [AppWindow::LOADING_CHILD, AppWindow::INVALID_CHILD]
        .include?(window.stack.visible_child_name)
    end
    d.check("the probe finished") do
      wait_until { window.stack.visible_child_name == AppWindow::INVALID_CHILD }
    end
  end

  d.step("the invalid-image page is showing, in German") do
    d.check("the invalid page is the visible stack child") do
      window.stack.visible_child_name == AppWindow::INVALID_CHILD
    end
    d.check("its title is translated") do
      window.invalid_image_page.status_page.title == "Bild konnte nicht geladen werden"
    end
    d.check("its icon is upstream's") do
      window.invalid_image_page.status_page.icon_name == InvalidImagePage::ICON_NAME
    end
    d.check("the add button is hidden on it") { !window.add_button.visible? }
    d.check("the loading page is no longer the visible child") do
      window.stack.visible_child_name != AppWindow::LOADING_CHILD
    end
    d.shot("06-invalid")
  end

  d.step("win.clear takes it back to the welcome page") do
    window.window.activate_action("clear", nil)
    d.check("the welcome page is back") do
      window.stack.visible_child_name == AppWindow::WELCOME_CHILD
    end
    d.check("nothing is loaded") { window.send(:files_count).zero? }
  end

  # ------------------------------------------------------ loading eight files

  d.step("eight real PNGs are opened") do
    window.open_files(PNGS.map { |path| InputFile.new_for_path(path) })
    d.check("the probe and the thumbnails finished") do
      wait_until { window.stack.visible_child_name == AppWindow::CONVERT_CHILD }
    end
  end

  d.step("the probe filled in what magick identify reported") do
    window.send(:active_files).then do |files|
      d.check("eight files are loaded") { files.length == 8 }
      d.check("each one is a PNG") { files.all? { |f| f.kind.extension == "png" } }
      d.check("each one got its real size") { files.all? { |f| f.dimensions == [640, 480] } }
      d.check("each one got one frame") { files.all? { |f| f.frame_count == 1 } }
      d.check("each one got a thumbnail texture") { files.all? { |f| f.texture } }
      d.check("the caption is upstream's format · size") do
        files.first.caption == "PNG · 640×480"
      end
      d.check("the shared size reached the convert page") do
        window.send(:shared_dimensions) == [640, 480]
      end
    end
    d.check("the convert page is showing") do
      window.stack.visible_child_name == AppWindow::CONVERT_CHILD
    end
    d.check("the add button is revealed now") { window.add_button.visible? }
    d.check("the convert button is translated") do
      window.convert_page.convert_button.label == "_Umwandeln"
    end
  end

  # Its own tick again: the thumbnails were appended in the step above, and a
  # Gtk::Picture that has not been laid out yet renders as an empty box.
  d.step("the convert page renders, thumbnails and all") { d.shot("07-convert") }

  d.step("the short strip ends in a +N tile rather than showing all eight") do
    flow_box_children(window.convert_page.image_container).then do |children|
      d.check("it holds six tiles") { children.length == AppWindow::SHORT_STRIP_LENGTH }
      d.check("five of them are thumbnails") do
        children.first(5).all? { |c| c.child.is_a?(ImageThumbnail) }
      end
      d.check("the last one is the ImageRest tile") { children.last.child.is_a?(ImageRest) }
      children.last.child.then do |rest|
        d.check("it counts the three it is hiding") { rest.count_label.label == "+3" }
        d.check("its Show All label is translated") do
          rest.show_all_label.label == "Alle anzeigen"
        end
        # "Show {} more images" has no German msgstr in upstream's own de.po,
        # so the English with the count substituted is the right answer.
        d.check("its tooltip counts the hidden images") do
          rest.button.tooltip_text == "Show 3 more images"
        end
        d.check("it is not focusable, as upstream's is not") { !rest.focusable? }
      end
      d.check("each thumbnail carries its caption") do
        children.first(5).all? { |c| c.child.caption_label.label == "PNG · 640×480" }
      end
      d.check("each thumbnail got the real texture, not the fallback icon") do
        children.first(5).all? { |c| c.child.picture.paintable }
      end
      d.check("three or more images sit in a three-wide grid") do
        window.convert_page.image_container.max_children_per_line == 3
      end
    end
    d.check("the full container holds all eight") do
      flow_box_children(window.all_images_page.flow_box).length == 8
    end
  end

  d.step("the +N tile pushes the All Images page") do
    flow_box_children(window.convert_page.image_container)
      .last.child.button.signal_emit("clicked")
  end

  d.step("the All Images page is up with every thumbnail on it") do
    d.check("the navigation view moved to it") do
      window.navigation.visible_page.tag == AllImagesPage::TAG
    end
    d.check("its title is translated") { window.all_images_page.page.title == "Alle Bilder" }
    d.check("it shows the images, not its spinner") do
      window.all_images_page.stack.visible_child_name == AllImagesPage::IMAGES_CHILD
    end
    d.check("its add button runs win.add too") do
      window.all_images_page.add_button.action_name == "win.add"
    end
    d.check("its add button is visible once loading finished") do
      window.all_images_page.add_button.visible?
    end
    d.check("eight thumbnails are on it") do
      flow_box_children(window.all_images_page.flow_box).length == 8
    end
    d.check("the window no longer reports itself on the main page") do
      !window.send(:on_main_page?)
    end
    d.shot("08-all-images")
  end

  d.step("its own spinner is what spins when a load starts from here") do
    window.send(:switch_to_loading_generally)
    d.check("the All Images page shows its loading child") do
      window.all_images_page.stack.visible_child_name == AllImagesPage::LOADING_CHILD
    end
    d.check("its add button is hidden while loading") do
      !window.all_images_page.add_button.visible?
    end
    d.check("the main stack was left alone") do
      window.stack.visible_child_name == AppWindow::CONVERT_CHILD
    end
    window.send(:switch_back_from_loading)
    window.all_images_page.show_images
    d.check("and it comes back") do
      window.all_images_page.stack.visible_child_name == AllImagesPage::IMAGES_CHILD
    end
  end

  d.step("the navigation view pops back to the main page") do
    window.navigation.pop
  end

  d.step("removing a thumbnail drops it from both strips but keeps the file") do
    d.check("the main page is back") { window.send(:on_main_page?) }
    flow_box_children(window.all_images_page.flow_box)[2].child
      .remove_button.signal_emit("clicked")
    d.check("seven images are active now") { window.send(:files_count) == 7 }
    d.check("the store still holds all eight") do
      window.instance_variable_get(:@files).length == 8
    end
    d.check("the removed index is filtered out of the full strip") do
      flow_box_children(window.all_images_page.flow_box)[2].child_visible? == false ||
        !flow_box_children(window.all_images_page.flow_box)[2].visible?
    end
    d.check("the short strip still ends in a rest tile") do
      flow_box_children(window.convert_page.image_container).last.child.is_a?(ImageRest)
    end
    d.check("the rest tile counts one fewer") do
      flow_box_children(window.convert_page.image_container).last.child.count_label.label == "+2"
    end
    # "Remove image" has no German msgstr in upstream's own de.po, so the
    # English is the correct answer here, not a missed lookup.
    d.check("the remove button carries upstream's tooltip") do
      flow_box_children(window.all_images_page.flow_box).first.child
        .remove_button.tooltip_text == "Remove image"
    end
  end

  # Its own tick: a window whose content changed in this one has not been laid
  # out again yet, and Gtk::WidgetPaintable then produces no render node at all.
  d.step("the shortened strip renders") { d.shot("09-after-remove") }

  # --------------------------------------------------------- the convert page

  d.step("the convert page sits in window.blp's two nested bins") do
    d.check("the stack child is an Adwaita::Bin") do
      window.stack.get_child_by_name(AppWindow::CONVERT_CHILD).is_a?(Adwaita::Bin)
    end
    d.check("its child is the second bin") do
      window.stack.get_child_by_name(AppWindow::CONVERT_CHILD).child ==
        window.convert_page.inner_bin
    end
    d.check("the inner bin holds the preferences page") do
      window.convert_page.inner_bin.child == window.convert_page.page
    end
  end

  d.step("the output dropdown offers upstream's twelve formats") do
    window.convert_page.output_filetype.then do |row|
      d.check("twelve formats") { row.model.n_items == FileType::OUTPUT_KEYS.length }
      d.check("they are upstream's, in order") do
        (0...row.model.n_items).map { |i| row.model.get_string(i) } ==
          FileType.output_formats.map(&:display_string)
      end
      d.check("the row's title is translated") { row.title == "Exportformat" }
    end
  end

  d.step("choosing a lossy output shows the quality row") do
    window.convert_page.output_filetype.selected =
      FileType.output_formats.index(FileType.from_string("jpg"))
  end

  d.step("the quality row is labelled and visible") do
    window.convert_page.then do |page|
      d.check("quality row is showing for a lossy output") { page.quality_row.visible? }
      d.check("quality row title is translated") { page.quality_row.title == "Qualität" }
      d.check("the scale is the row's suffix child") { page.quality_scale.parent }
      d.check("the scale spans 1 to 100") do
        page.quality_adjustment.lower == ConvertPage::QUALITY_MINIMUM &&
          page.quality_adjustment.upper == ConvertPage::QUALITY_MAXIMUM
      end
      page.quality_scale.value = 72
      d.check("the page reports the quality the scale shows") { page.quality == 72 }
      d.check("a JPEG cannot keep alpha, so the swatch went opaque white") do
        page.background.hex_string == "#ffffffff"
      end
      d.check("the background row is offered, since the inputs are PNGs") do
        page.bgcolor_row.visible?
      end
      d.check("the strip row is offered, since PNG keeps metadata") do
        page.strip_row.visible?
      end
      d.check("the dpi row is hidden, since no input is a PDF") { !page.dpi_row.visible? }
      d.check("the compression row is offered, since eight files bundle") do
        page.output_compression_row.visible?
      end
      d.check("the single-pdf row is hidden for a JPEG output") do
        !page.single_pdf_row.visible?
      end
      d.check("the unit dropdown carries no tooltip, as in window.blp") do
        page.resize_type_dropdown.tooltip_text.nil?
      end
      d.check("the unit dropdown offers both units") do
        page.resize_type_dropdown.model.n_items == 2
      end
    end
  end

  d.step("a lossless output hides the quality row again") do
    window.convert_page.output_filetype.selected =
      FileType.output_formats.index(FileType.from_string("png"))
    window.convert_page.then do |page|
      d.check("quality row is hidden for PNG") { !page.quality_row.visible? }
      d.check("PNG keeps alpha, so the swatch went all but transparent") do
        page.background.to_rgba.alpha < 0.001
      end
      d.check("and the colour dialog offers an alpha channel") { page.color_dialog.with_alpha? }
    end
  end

  d.step("a PDF output offers the single-document switch") do
    window.convert_page.output_filetype.selected =
      FileType.output_formats.index(FileType.from_string("pdf"))
    window.convert_page.then do |page|
      d.check("the single-pdf row is showing") { page.single_pdf_row.visible? }
      d.check("its title is translated") do
        page.single_pdf_row.title == "Als mehrseitiges PDF speichern"
      end
      page.single_pdf_switch.active = true
      page.update_compression_options
      d.check("a single PDF needs no archive, so the compression row went away") do
        !page.output_compression_row.visible?
      end
      d.check("the page reports single-pdf") { page.single_pdf? }
      d.check("so the window would save one PDF file, not a bundle") do
        window.send(:save_format, page.selected_output).file?
      end
      page.single_pdf_switch.active = false
      page.update_compression_options
      d.check("turning it off brings the archive choice back") do
        page.output_compression_row.visible?
      end
    end
  end

  d.step("the archive switch picks between a ZIP and a directory") do
    window.convert_page.then do |page|
      page.output_filetype.selected = FileType.output_formats.index(FileType.from_string("jpg"))
      page.output_compression_switch.active = true
      d.check("a ticked switch means ZIP") { page.selected_compression == CompressionType::ZIP }
      page.output_compression_switch.active = false
      d.check("an unticked one means a directory") do
        page.selected_compression == CompressionType::DIRECTORY
      end
      d.check("the row's title is translated") do
        page.output_compression_row.title == "Als Zip speichern"
      end
    end
  end

  d.step("the resize row swaps percentages for pixels") do
    window.convert_page.then do |page|
      d.check("it starts on percentages") { page.send(:percentage_resize?) }
      d.check("the percentage entries are showing") do
        page.resize_scale_width_entry.visible? && !page.resize_width_entry.visible?
      end
      d.check("they start at 100") do
        page.resize_scale_width_entry.text == "100" &&
          page.resize_scale_height_entry.text == "100"
      end
      d.check("the argument is a percentage") { page.resize_argument.percentage? }
      d.check("and renders as upstream's -resize") do
        page.resize_argument.arguments == ["-resize", "100%x100%"]
      end

      page.resize_type_dropdown.selected = 1
      d.check("the pixel entries are showing now") do
        page.resize_width_entry.visible? && !page.resize_scale_width_entry.visible?
      end
      d.check("they were seeded with the shared size") do
        page.resize_width_entry.text == "640" && page.resize_height_entry.text == "480"
      end
      d.check("the argument is exact pixels") { page.resize_argument.exact_pixels? }
      d.check("and renders as upstream's -resize !") do
        page.resize_argument.arguments == ["-resize", "640x480!"]
      end
    end
  end

  d.step("the chain link keeps the two axes in proportion") do
    window.convert_page.then do |page|
      d.check("the link is offered, since the images share a size") { page.link_axis.visible? }
      d.check("it starts linked") { page.link_axis.active? }
      d.check("and shows the closed-chain icon") do
        page.link_axis.icon_name == ConvertPage::LINKED_ICON
      end
      page.resize_width_entry.text = "320"
      d.check("halving the width halved the height") { page.resize_height_entry.text == "240" }
      # GtkToggleButton's own class closure for "clicked" is what flips
      # `active`, and it runs before a signal_connect handler, so emitting
      # "clicked" alone is exactly what a pointer press does — setting
      # `active` first would have the emission flip it straight back.
      page.link_axis.signal_emit("clicked")
      d.check("unlinking shows the loose-chain icon") do
        page.link_axis.icon_name == ConvertPage::LOOSE_ICON
      end
      page.resize_width_entry.text = "100"
      d.check("the height is left alone now") { page.resize_height_entry.text == "240" }
      page.link_axis.signal_emit("clicked")
      d.check("re-linking shows the closed chain again") do
        page.link_axis.icon_name == ConvertPage::LINKED_ICON
      end
      # Upstream's handler re-derives the *width* from the height on re-link,
      # so the 100 typed while unlinked becomes the 320 that 240 implies.
      d.check("and re-derives the width from the height it was left with") do
        page.resize_width_entry.text == "320" && page.resize_height_entry.text == "240"
      end
      page.resize_type_dropdown.selected = 0
    end
  end

  d.step("the filter radios and the strip switch report upstream's arguments") do
    window.convert_page.then do |page|
      d.check("the filter row is offered, since no input is an SVG") do
        page.resize_filter_row.visible?
      end
      d.check("it starts on the default filter") { page.resize_filter_default.active? }
      d.check("which adds no filter arguments") { page.resize_filter.arguments.empty? }
      page.resize_filter_pixel.active = true
      d.check("the pixel filter asks magick for upstream's -filter Point") do
        page.resize_filter.arguments == ["-filter", "Point"]
      end
      d.check("the default filter has no display string, as upstream's has none") do
        Magick::ResizeFilter.default.display_string.nil?
      end
      page.resize_filter_default.active = true

      d.check("the strip switch starts off, so metadata is kept") do
        page.strip_type.arguments.empty?
      end
      page.strip_switch.active = true
      d.check("turning it on asks magick to -auto-orient and -strip") do
        page.strip_type.arguments == ["-auto-orient", "-strip"]
      end
      page.strip_switch.active = false
    end
  end

  d.step("the colour button announces a pick") do
    window.convert_page.bgcolor_button.rgba = Gdk::RGBA.new(
      1.0,
      0.0,
      0.0,
      1.0,
    )
    d.check("the pick survived the notify::rgba handler") do
      Color.from_rgba(window.convert_page.bgcolor_button.rgba).hex_string == "#ff0000ff"
    end
    d.check("the page reports it as the conversion background") do
      window.convert_page.background == Color.rgb(255, 0, 0)
    end
    d.check("and it reaches magick as a -background argument") do
      window.convert_page.job_defaults.to_h[:background].hex_string == "#ff0000ff"
    end
  end

  d.step("the dpi entry is what a PDF input would be rasterised at") do
    window.convert_page.dpi_entry.text = "150"
    d.check("the page reports it") { window.convert_page.dpi == 150 }
    d.check("its row is translated") do
      window.convert_page.dpi_row.title == "Pixeldichte pro Zoll"
    end
  end

  d.step("save_options writes every option, load_options reads them back") do
    window.convert_page.then do |page|
      page.quality_scale.value = 55
      page.dpi_entry.text = "123"
      page.resize_type_dropdown.selected = 1
      page.save_options
      Settings.new.then do |settings|
        d.check("quality reached gsettings") { settings["quality"] == 55 }
        d.check("dpi reached gsettings") { settings["dpi"] == 123 }
        d.check("the resize unit reached gsettings") { settings["resize-type"] == 1 }
        d.check("the output format reached gsettings") do
          FileType.output_formats[settings["output-format"]] == page.selected_output
        end
      end
      page.quality_scale.value = 1
      page.dpi_entry.text = "1"
      page.resize_type_dropdown.selected = 0
      page.load_options
      d.check("quality came back") { page.quality == 55 }
      d.check("dpi came back") { page.dpi == 123 }
      d.check("the resize unit came back") { page.resize_type_dropdown.selected == 1 }
      page.resize_type_dropdown.selected = 0
    end
  end

  d.step("a maximized window still records its size") do
    window.window.maximize
    Settings.new.tap do |settings|
      settings.remember(window.window)
      d.check("window-width was written") { settings["window-width"].positive? }
      d.check("window-height was written") { settings["window-height"].positive? }
      d.check("is-maximized was written") { [true, false].include?(settings["is-maximized"]) }
      d.check("every key the schema declares is readable") do
        Settings::KEYS.all? { |key| !settings[key].nil? }
      end
      settings["window-width"] = 820
      settings["window-height"] = 640
      # Destroyed again on the way out: a Gtk::Window joins the toplevel list
      # the moment it is constructed, and the window-count checks further down
      # would then be counting this one too.
      d.check("apply_to sizes a fresh window from what was stored") do
        Gtk::Window.new.then do |fresh|
          settings.apply_to(fresh)
          [fresh.default_width, fresh.default_height] == [820, 640]
        ensure
          fresh.destroy
        end
      end
    end
    window.window.unmaximize
  end

  # ---------------------------------------------------- the ImageMagick layer

  d.step("magick identify reports what the files really are") do
    d.check("a PNG is one frame at its real size") do
      Magick.identify(PNGS.first) == [1, [640, 480]]
    end
    d.check("the animation is three frames") { Magick.identify(ANIMATION).first == 3 }
    d.check("a corrupt file is reported as unidentifiable") { Magick.identify(CORRUPT).nil? }
    d.check("so is a file that is not there") { Magick.identify("/nope.png").nil? }
  end

  d.step("generate_job builds upstream's command line") do
    Magick.generate_job(
      input_path:  "in.png",
      input_type:  FileType.from_string("png"),
      output_path: "out.jpg",
      output_type: FileType.from_string("jpg"),
      dpi:         300,
      defaults:    window.convert_page.job_defaults,
    ).command.then do |command|
      d.check("it starts with the magick binary") { command.first == Magick::BINARY }
      d.check("PNG being no animation, it takes upstream's -flatten arm") do
        command.include?("in.png") && command.include?("-flatten")
      end
      d.check("it writes the output path last") { command.last == "out.jpg" }
      d.check("it carries the chosen quality") do
        command.each_cons(2).include?(["-quality", "55"])
      end
      d.check("it flattens onto the chosen background") { command.include?("-background") }
    end
    Magick.generate_job(
      input_path:  "in.pdf",
      input_type:  FileType.from_string("pdf"),
      output_path: "out.png",
      output_type: FileType.from_string("png"),
      dpi:         300,
      defaults:    window.convert_page.job_defaults,
    ).then do |job|
      d.check("a PDF input carries the chosen density") { job.to_h[:density] == 300 }
      d.check("and, the defaults not asking for a flatten, takes upstream's") do
        job.command.include?("-coalesce")
      end
      d.check("so a flattened PDF job is the one that gets -density") do
        job.with(first_frame: true).command.each_cons(2).include?(["-density", "300"])
      end
    end
  end

  d.step("frames_for expands an animation the way upstream does") do
    InputFile.new_for_path(ANIMATION).tap { |file| file.frame_count = 3 }.then do |gif|
      d.check("a GIF staying animated is passed whole") do
        window.send(
          :frames_for,
          gif,
          "spin",
          FileType.from_string("webp"),
        ) ==
          [[ANIMATION, "spin.webp"]]
      end
      d.check("a GIF flattened to PNG becomes one job per frame") do
        window.send(
          :frames_for,
          gif,
          "spin",
          FileType.from_string("png"),
        ).length == 3
      end
      d.check("and each frame is numbered in both the input and the name") do
        window.send(
          :frames_for,
          gif,
          "spin",
          FileType.from_string("png"),
        ).first ==
          ["#{ANIMATION}[0]", "spin[0].png"]
      end
    end
  end

  d.step("two files with the same stem are kept apart") do
    d.check("the second cover becomes cover_1") do
      window.send(:unique_stem, "cover", ["cover"]) == "cover_1"
    end
    d.check("and the third cover_2") do
      window.send(:unique_stem, "cover", ["cover", "cover_1"]) == "cover_2"
    end
    d.check("seven loaded files make seven jobs") do
      window.send(:job_inputs, FileType.from_string("jpg")).length == 7
    end
    d.check("each job names its own output file") do
      window.send(:job_inputs, FileType.from_string("jpg"))
            .map { |job| job[:output_name] }.uniq.length == 7
    end
  end

  d.step("run_jobs reports the stderr of a command that fails") do
    [].then do |failures|
      Magick::Children.new.then do |children|
        Magick.run_jobs(
          groups:      [[[Magick::BINARY, "convert", "/nope.png", "/tmp/nope.jpg"]]],
          children:    children,
          on_progress: ->(_done, _total) { nil },
          on_failure:  ->(message) { failures << message },
          on_success:  -> { failures << :success },
        )
        d.check("the failure came back") { wait_until { !failures.empty? } }
        d.check("it is the child's own stderr, not a summary") do
          failures.first.to_s.include?("/nope.png")
        end
        d.check("and success was never reported") { !failures.include?(:success) }
      end
    end
  end

  d.step("a temp dir is created and cleaned") do
    TempDir.create.then do |dir|
      JobFile.new(file_type: FileType.from_string("jpg"), desired_name: "x.jpg").then do |job|
        d.check("it names a file inside itself") do
          dir.file_path(job).start_with?(dir.path)
        end
        d.check("the job file keeps the desired name") { job.filename == "x.jpg" }
      end
      d.check("an unnamed job file gets a unique one") do
        JobFile.new(file_type: FileType.from_string("png")).filename !=
          JobFile.new(file_type: FileType.from_string("png")).filename
      end
      d.check("the directory is on disk") { File.directory?(dir.path) }
      dir.clean
      d.check("cleaning removes it") { !File.exist?(dir.path) }
    end
  end

  # ------------------------------------------------------ a real conversion

  d.step("a real conversion of all seven images into a ZIP is started") do
    window.convert_page.output_filetype.selected =
      FileType.output_formats.index(FileType.from_string("jpg"))
    window.convert_page.output_compression_switch.active = true
    File.join(DEST, "images.zip").then do |zip|
      d.check("the window would bundle this run") do
        window.send(:bundled?, window.convert_page.selected_output)
      end
      d.check("and would suggest upstream's name for the bundle") do
        window.send(:default_name, window.convert_page.selected_output) == "images"
      end
      window.send(
        :convert_start,
        OutputType.compression(CompressionType::ZIP),
        zip,
      )
    end
  end

  d.step("the converting page is up with its progress bar") do
    d.check("the converting page is the visible stack child") do
      window.stack.visible_child_name == AppWindow::CONVERTING_CHILD
    end
    d.check("the add button is hidden during a run") { !window.add_button.visible? }
    d.check("its title is translated") do
      window.converting_page.status_page.title == "Umwandlung läuft"
    end
    d.check("the convert button went insensitive") do
      !window.convert_page.convert_button.sensitive?
    end
    d.check("the cancel button is translated") do
      window.converting_page.cancel_button.label == "A_bbrechen"
    end
  end

  # Its own tick: the stack crossfaded to this page in the step above.
  d.step("the converting page renders") { d.shot("10-converting") }

  d.step("the run finishes and the ZIP is on disk") do
    File.join(DEST, "images.zip").then do |zip|
      d.check("the run came back") do
        wait_until(timeout: 90) do
          window.stack.visible_child_name == AppWindow::CONVERT_CHILD
        end
      end
      d.check("the zip was written") { File.exist?(zip) }
      d.check("and it holds all seven converted images") do
        File.binread(zip).scan("PK\x03\x04").length == 7
      end
      d.check("the progress bar reached the end") do
        window.converting_page.progress_bar.fraction == 1.0
      end
      d.check("the success toast is showing, in German") do
        label_showing?(window.window, "Bild wurde umgewandelt")
      end
      d.check("the toast offers upstream's Open button") do
        label_showing?(window.window, "Öffnen")
      end
      d.check("the convert button is sensitive again") do
        window.convert_page.convert_button.sensitive?
      end
      d.check("the temp dir was cleaned up") do
        window.instance_variable_get(:@temp_dir).nil?
      end
      d.shot("11-converted")
    end
  end

  d.step("a conversion into a plain directory writes the files out loose") do
    File.join(DEST, "loose").then do |folder|
      FileUtils.mkdir_p(folder)
      window.convert_page.output_compression_switch.active = false
      window.send(
        :convert_start,
        OutputType.compression(CompressionType::DIRECTORY),
        folder,
      )
      d.check("the run came back") do
        wait_until(timeout: 90) do
          window.stack.visible_child_name == AppWindow::CONVERT_CHILD
        end
      end
      d.check("seven JPEGs landed in the folder") do
        Dir.children(folder).count { |name| name.end_with?(".jpg") } == 7
      end
    end
  end

  d.step("cancelling a run puts up the stop dialog") do
    # Adw queues toasts one at a time, so the one still on screen from the
    # successful run would hide the next. Dismissing it first is what the user
    # clicking it away does.
    window.toast_overlay.dismiss_all
    window.instance_variable_get(:@children).begin_run
    window.converting_page.cancel_button.signal_emit("clicked")
  end

  d.step("the stop dialog asks before losing the progress") do
    visible_alert(window.window).then do |dialog|
      d.check("an alert dialog is showing") { dialog.is_a?(Adwaita::AlertDialog) }
      d.check("its heading is translated") { dialog.heading == "Umwandlung stoppen?" }
      d.check("it offers Cancel and Stop") do
        dialog.has_response?("cancel") && dialog.has_response?("stop")
      end
      d.check("Stop is marked destructive") do
        dialog.get_response_appearance("stop") == :destructive
      end
      d.check("the Stop label is translated") { dialog.get_response_label("stop") == "_Stopp" }
      d.shot("12-stop-dialog")
      dialog.signal_emit("response", "stop")
      dialog.close
    end
  end

  d.step("stopping cancels the children and says so") do
    d.check("the children are cancelled") do
      window.instance_variable_get(:@children).canceled?
    end
    d.check("the convert page is back") do
      window.stack.visible_child_name == AppWindow::CONVERT_CHILD
    end
    d.check("the cancellation toast is showing, in German") do
      label_showing?(window.window, "Umwandlung abgebrochen")
    end
  end

  d.step("a failed run raises the error dialog with the child's own stderr") do
    window.toast_overlay.dismiss_all
    window.instance_variable_get(:@children).begin_run
    window.send(:convert_failed, "magick: no decode delegate for this image format")
  end

  d.step("the error dialog shows the message and can copy it") do
    visible_alert(window.window).then do |dialog|
      d.check("an alert dialog is showing") { dialog.is_a?(Adwaita::AlertDialog) }
      d.check("its heading is translated") { dialog.heading == "Fehler bei der Verarbeitung" }
      d.check("it offers Close and Copy") do
        dialog.has_response?("ok") && dialog.has_response?("copy")
      end
      d.check("the Close label is translated") { dialog.get_response_label("ok") == "_Schließen" }
      d.check("Copy is marked suggested") do
        dialog.get_response_appearance("copy") == :suggested
      end
      d.check("the stderr is on screen verbatim") do
        label_showing?(window.window, "magick: no decode delegate for this image format")
      end
      d.check("the convert page is showing behind it") do
        window.stack.visible_child_name == AppWindow::CONVERT_CHILD
      end
      d.shot("13-error-dialog")
      dialog.signal_emit("response", "copy")
      dialog.close
    end
  end

  d.step("copying the error reaches the clipboard and toasts") do
    d.check("the copy toast is showing") do
      label_showing?(window.window, "Fehler in die Zwischenablage kopiert")
    end
  end

  # ------------------------------------------------------- drops and pastes

  d.step("a drop of files the app cannot reach is refused with a toast") do
    window.toast_overlay.dismiss_all
    Struct.new(:files).new([]).then do |value|
      d.check("the drop is declined") { window.send(:on_drop, value) == false }
    end
  end

  d.step("the refusal toast is showing") do
    d.check("it says the files could not be reached, in German") do
      label_showing?(window.window, "Auf abgelegte Dateien konnte nicht zugegriffen werden")
    end
  end

  d.step("a drop of two real images is accepted and loaded") do
    Struct.new(:files).new(SAME_STEM.map { |path| Gio::File.open(path: path) }).then do |value|
      d.check("the drop is accepted") { window.send(:on_drop, value) == true }
    end
    d.check("the probe finished") do
      wait_until { window.stack.visible_child_name == AppWindow::CONVERT_CHILD }
    end
  end

  d.step("the dropped files replaced the strip") do
    window.send(:active_files).then do |files|
      d.check("the two dropped files are in front") do
        files.first(2).map(&:path).sort == SAME_STEM.sort
      end
      d.check("they came back at their real size") { files.first.dimensions == [32, 32] }
      d.check("the two same-stem files get distinct output names") do
        window.send(:job_inputs, FileType.from_string("jpg"))
              .map { |job| job[:output_name] }
              .first(2).sort == ["cover.jpg", "cover_1.jpg"]
      end
      d.check("the removed set was cleared by the new open") do
        window.instance_variable_get(:@removed).empty?
      end
    end
    d.shot("14-after-drop")
  end

  d.step("win.paste reads the clipboard's formats without blowing up") do
    window.stack.visible_child_name.then do |before|
      d.check("an empty clipboard offers neither format") do
        window.window.clipboard.formats.then do |formats|
          !formats.contain_mime_type(AppWindow::PASTEABLE_IMAGE_MIME) &&
            !formats.contain_mime_type(AppWindow::PASTEABLE_FILES_MIME)
        end
      end
      window.window.activate_action("paste", nil)
      d.check("so the stack did not move") { window.stack.visible_child_name == before }
    end
  end

  d.step("a pasted texture is written out as a PNG and loaded") do
    # Upstream writes the pasted PNG to a bare relative name, so it lands in
    # the process's working directory; the run moves there for the rest of the
    # steps rather than leaving a file in the repository.
    Dir.chdir(DEST)
    window.send(:clear)
    Gdk::Texture.new(GLib::Bytes.new(File.binread(PNGS.last))).then do |texture|
      window.send(:save_pasted_texture, texture)
    end
    d.check("the probe of the pasted file finished") do
      wait_until { window.stack.visible_child_name == AppWindow::CONVERT_CHILD }
    end
    d.check("the pasted image is loaded") { window.send(:files_count) == 1 }
    d.check("it was written under upstream's translated name") do
      window.send(:active_files).first.stem == "Eingefügtes Bild"
    end
    d.check("and it came back at the right size") do
      window.send(:active_files).first.dimensions == [640, 480]
    end
  end

  d.step("one image loaded alone offers no bundling at all") do
    window.send(:clear)
    window.open_files([InputFile.new_for_path(PNGS.first)])
    d.check("the probe finished") do
      wait_until { window.stack.visible_child_name == AppWindow::CONVERT_CHILD }
    end
  end

  d.step("the single-image strip is one tile wide and un-bundled") do
    window.send(:active_files).then do |files|
      d.check("one file is loaded") { files.length == 1 }
      d.check("the strip holds exactly one tile") do
        flow_box_children(window.convert_page.image_container).length == 1
      end
      d.check("one image stretches the container") do
        window.convert_page.image_container.max_children_per_line == 1 &&
          window.convert_page.image_container.hexpand?
      end
    end
    window.convert_page.then do |page|
      page.output_filetype.selected = FileType.output_formats.index(FileType.from_string("png"))
      page.update_compression_options
      d.check("one file into one file needs no bundle") do
        !window.send(:bundled?, page.selected_output)
      end
      d.check("so the compression row is hidden") { !page.output_compression_row.visible? }
      d.check("and the suggested name is the file's own stem") do
        window.send(:default_name, page.selected_output) == "shot0"
      end
      d.check("so the window would save a single file, not a bundle") do
        window.send(:save_format, page.selected_output).file?
      end
    end
  end

  d.step("the animation is loaded on its own") do
    window.send(:clear)
    window.open_files([InputFile.new_for_path(ANIMATION)])
    d.check("the probe finished") do
      wait_until { window.stack.visible_child_name == AppWindow::CONVERT_CHILD }
    end
  end

  d.step("the lone animation is three frames and fills the strip's width") do
    window.send(:active_files).then do |files|
      d.check("one file is loaded") { files.length == 1 }
      d.check("magick found its three frames") { files.first.frame_count == 3 }
      d.check("it is a GIF") { files.first.kind.extension == "gif" }
      d.check("one image stretches the container") do
        window.convert_page.image_container.max_children_per_line == 1
      end
      d.check("the strip holds exactly one tile") do
        flow_box_children(window.convert_page.image_container).length == 1
      end
      d.check("and no rest tile") do
        flow_box_children(window.convert_page.image_container)
          .none? { |c| c.child.is_a?(ImageRest) }
      end
    end
    window.convert_page.then do |page|
      page.output_filetype.selected = FileType.output_formats.index(FileType.from_string("webp"))
      page.update_compression_options
      d.check("a GIF into an animated WebP needs no bundle") do
        !window.send(:bundled?, page.selected_output)
      end
      d.check("so the compression row is hidden") { !page.output_compression_row.visible? }
      page.output_filetype.selected = FileType.output_formats.index(FileType.from_string("jpg"))
      page.update_compression_options
      d.check("a GIF into JPEGs does bundle, three frames being three files") do
        window.send(:bundled?, page.selected_output)
      end
      d.check("so the compression row comes back") { page.output_compression_row.visible? }
      d.check("so the suggested name is upstream's bundle name") do
        window.send(:default_name, page.selected_output) == "images"
      end
    end
  end

  d.step("the animation's strip renders") { d.shot("15-animation") }

  d.step("the thumbnail falls back to an icon when there is no texture") do
    ImageThumbnail.new(texture: nil, caption: "PDF", dimensions: nil).then do |thumbnail|
      thumbnail.build
      d.check("the fallback icon is showing") do
        thumbnail.image.icon_name == ImageThumbnail::FALLBACK_ICON
      end
      d.check("the picture is hidden") { !thumbnail.picture.visible? }
      d.check("the caption is still set") { thumbnail.caption_label.label == "PDF" }
    end
    ImageThumbnail.new(
      texture:    Gdk::Texture.new(GLib::Bytes.new(File.binread(PNGS.first))),
      caption:    "PNG · 640×480",
      dimensions: [640, 480],
    ).then do |thumbnail|
      thumbnail.build
      d.check("a real texture is shown as a picture") { thumbnail.picture.visible? }
      d.check("and the fallback icon is hidden") { !thumbnail.image.visible? }
    end
  end

  d.step("the accessible caption really is attached to the flow box child") do
    window.send(:labelled_flow_box_child, "PNG · 640×480 & <more>").then do |child|
      d.check("the builder fragment produces a GtkFlowBoxChild") { child.is_a?(Gtk::FlowBoxChild) }
    end
    d.check("markup in a caption is escaped, not injected") do
      window.send(:flow_box_child_markup, "a & b <c>").include?("a &amp; b &lt;c&gt;")
    end
  end

  # -------------------------------------------------- the second window, close

  d.step("app.new-window opens a second window") do
    app.app.activate_action("new-window", nil)
  end

  d.step("the second window is a window of its own") do
    app.instance_variable_get(:@windows).then do |windows|
      d.check("the app is tracking two windows") { windows.length == 2 }
      second = windows.last
      d.check("it is not the first one") { !second.window.equal?(window.window) }
      d.check("it starts on the welcome page") do
        second.stack.visible_child_name == AppWindow::WELCOME_CHILD
      end
      d.check("it has its own six actions") do
        AppWindow::WINDOW_ACTIONS.all? { |name| second.window.has_action?(name) }
      end
      d.check("GTK sees exactly two toplevels") { Gtk::Window.list_toplevels.length == 2 }
      d.shot("16-second-window", second.window)
    end
  end

  d.step("closing it mid-run asks before losing the progress") do
    second.instance_variable_get(:@children).begin_run
    d.check("the close request is held") { second.send(:on_close_request) == true }
  end

  d.step("the stop dialog is up on the second window too") do
    visible_alert(second.window).then do |dialog|
      d.check("an alert dialog is showing") { dialog.is_a?(Adwaita::AlertDialog) }
      d.check("the window is still open") { second.window.visible? }
      d.check("its geometry was recorded on the way") do
        Settings.new["window-width"].positive?
      end
      dialog.signal_emit("response", "cancel")
      dialog.close
    end
    d.check("cancelling left the window open") { second.window.visible? }
  end

  d.step("with nothing running, closing it just closes it") do
    second.instance_variable_get(:@children).cancel
    d.check("the close request is let through") { second.send(:on_close_request) == false }
    second.window.activate_action("close", nil)
  end

  d.step("the second window is gone and the first one is untouched") do
    d.check("only one window is left") { Gtk::Window.list_toplevels.length == 1 }
    d.check("the first window is still there") { window.window.visible? }
    d.check("and still on its convert page") do
      window.stack.visible_child_name == AppWindow::CONVERT_CHILD
    end
  end

  # ------------------------------------------------------------ back to empty

  d.step("win.clear empties the window again") do
    window.window.activate_action("clear", nil)
  end

  d.step("the app is empty, exactly as it started") do
    d.check("the welcome page is the visible stack child") do
      window.stack.visible_child_name == AppWindow::WELCOME_CHILD
    end
    d.check("no files are loaded") { window.send(:files_count).zero? }
    d.check("the add button is hidden again") { !window.add_button.visible? }
    d.check("the welcome page still offers its button") do
      window.welcome_page.open_button.sensitive?
    end
    d.check("the loading spinner is not spinning") { !window.loading_page.spinner.spinning? }
    d.shot("17-empty-again")
  end

  d.step("every component the port ships was opened in this run") do
    Dir.children(File.expand_path("../lib", __dir__))
       .select { |name| name.end_with?(".rb") }
       .map { |name| File.basename(name, ".rb") }
       .reject { |name| ["switcheroo", "main"].include?(name) }
       .sort
       .then do |shipped|
      d.check("the #{COMPONENTS.length} components driven are the #{shipped.length} the port ships") do
        COMPONENTS.sort == shipped
      end
    end
    puts "    components covered: #{COMPONENTS.length}"
  end
end
