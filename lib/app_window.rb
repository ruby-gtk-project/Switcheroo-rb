# frozen_string_literal: true

require 'fileutils'

require 'adwaita'

require_relative 'about_dialog'
require_relative 'all_images_page'
require_relative 'convert_page'
require_relative 'converting_page'
require_relative 'drag_overlay'
require_relative 'error_dialog'
require_relative 'file_chooser'
require_relative 'file_type'
require_relative 'image_rest'
require_relative 'image_thumbnail'
require_relative 'input_file'
require_relative 'invalid_image_page'
require_relative 'loading_page'
require_relative 'magick'
require_relative 'primary_menu'
require_relative 'settings'
require_relative 'shortcuts_dialog'
require_relative 'stop_converting_dialog'
require_relative 'temp_dir'
require_relative 'translations'
require_relative 'welcome_page'

# AppWindow is the application window and the state machine behind it.
#
# Ported from upstream's data/resources/blueprints/window.blp and
# src/window.rs. The widget tree is the blueprint's: a DragOverlay wrapping a
# toast overlay wrapping an Adw.NavigationView whose first page holds a
# five-page stack (welcome, loading, convert, invalid image, converting) and
# whose second page lists every loaded image.
#
# The state lives here, exactly as upstream's imp does: the loaded files, the
# indices the user has removed, the shared size of the loaded images, how many
# of them the short thumbnail strip is showing, and the registry of child
# processes a run has spawned.
#
# Two behaviours are worth knowing:
#
# * Removing a thumbnail does not drop the file. Upstream keeps the store
#   intact and records the index in a `removed` set which both flow boxes
#   filter on, so the indices stay stable while thumbnails come and go.
# * Closing the window mid-conversion does not close it. The close-request
#   handler puts up the stop dialog and keeps the window open until the user
#   says to lose the progress, which is upstream's glib::Propagation::Stop.
#
class AppWindow
  include Translations

  DEFAULT_SIZE = 750
  MINIMUM_SIZE = 300
  MAIN_TAG = 'main'

  ADD_ICON = 'plus-large-symbolic'
  MENU_ICON = 'open-menu-symbolic'

  WELCOME_CHILD = 'stack_welcome_page'
  LOADING_CHILD = 'stack_loading'
  CONVERT_CHILD = 'stack_convert'
  INVALID_CHILD = 'stack_invalid_image'
  CONVERTING_CHILD = 'stack_converting'

  DROP_TARGET_NAME = 'file-drop-target'

  # Upstream's ACTION_ENTRIES; the accelerators are bound by Application.
  WINDOW_ACTIONS = %w[close add clear show-help-overlay about paste].freeze

  # How many thumbnails the short strip shows before it ends in a "+N" tile.
  SHORT_STRIP_LENGTH = 6

  # Upstream's load_pixbuf() limits: ten thumbnails, and nothing bigger than
  # four megapixels, so opening a hundred large photos stays responsive.
  TEXTURE_LIMIT = 10
  MAX_THUMBNAIL_AREA = 2000 * 2000

  PASTEABLE_IMAGE_MIME = 'image/png'
  PASTEABLE_FILES_MIME = 'application/vnd.portal.files'

  def initialize(app, settings)
    @app = app
    @settings = settings
    @files = []
    @removed = []
    @elements = 0
    @children = Magick::Children.new
  end

  def build
    window.tap do |win|
      win.content = root_box

      root_box.append(drag_overlay.build)

      drag_overlay.tap do |overlay|
        overlay.content = toast_overlay
        overlay.drop_target = drop_target

        toast_overlay.child = navigation

        navigation.tap do |nav|
          nav.add(main_page)
          nav.add(all_images_page.build)
        end
      end

      build_main_page
      setup_actions
      setup_callbacks
      switch_to_welcome
    end
  end

  def present = window.present

  # Upstream's open_files(): what the application hands over on an open
  # request, and what the drop target produces.
  def open_files(inputs)
    inputs.compact.then do |files|
      if files.empty?
        show_toast(_('Unsupported filetype'))
      else
        open_success(files)
      end
    end
  end

  # --- Memoized widget methods --------------------------------------------

  def window
    @window ||= Adwaita::ApplicationWindow.new(@app).tap do |win|
      win.title = _('Switcheroo')
      win.width_request = MINIMUM_SIZE
      win.height_request = MINIMUM_SIZE
      win.set_default_size(DEFAULT_SIZE, DEFAULT_SIZE)
      @settings.apply_to(win)
    end
  end

  def root_box = @root_box ||= Gtk::Box.new(:vertical, 0)
  def drag_overlay = @drag_overlay ||= DragOverlay.new
  def toast_overlay = @toast_overlay ||= Adwaita::ToastOverlay.new
  def navigation = @navigation ||= Adwaita::NavigationView.new

  def main_page
    @main_page ||= Adwaita::NavigationPage.new(toolbar_view, _('Switcheroo')).tap do |page|
      page.tag = MAIN_TAG
    end
  end

  def toolbar_view = @toolbar_view ||= Adwaita::ToolbarView.new

  def header_bar
    @header_bar ||= Adwaita::HeaderBar.new.tap do |bar|
      bar.show_title = false
    end
  end

  def add_button
    @add_button ||= Gtk::Button.new.tap do |btn|
      btn.icon_name = ADD_ICON
      btn.tooltip_text = _('Add Images (Ctrl+O)')
      btn.action_name = 'win.add'
      btn.visible = false
      btn.add_css_class('flat')
    end
  end

  def menu_button
    @menu_button ||= Gtk::MenuButton.new.tap do |btn|
      btn.icon_name = MENU_ICON
      btn.tooltip_text = _('Primary Menu')
      btn.menu_model = PrimaryMenu.build
      btn.primary = true
    end
  end

  def window_handle
    @window_handle ||= Gtk::WindowHandle.new.tap do |handle|
      handle.vexpand = true
    end
  end

  def stack
    @stack ||= Gtk::Stack.new.tap do |st|
      st.transition_type = :crossfade
    end
  end

  def welcome_page = @welcome_page ||= WelcomePage.new
  def loading_page = @loading_page ||= LoadingPage.new
  def invalid_image_page = @invalid_image_page ||= InvalidImagePage.new
  def convert_page = @convert_page ||= ConvertPage.new(@settings)
  def converting_page = @converting_page ||= ConvertingPage.new
  def all_images_page = @all_images_page ||= AllImagesPage.new
  def shortcuts_dialog = @shortcuts_dialog ||= ShortcutsDialog.new.build

  # Upstream's setup_drop_target(): a COPY-action target that accepts exactly
  # a Gdk.FileList, so a drag of anything else is refused by GTK itself.
  def drop_target
    @drop_target ||= Gtk::DropTarget.new(Gdk::FileList.gtype, :copy).tap do |target|
      target.name = DROP_TARGET_NAME
    end
  end

  private

    def build_main_page
      toolbar_view.tap do |view|
        view.add_top_bar(header_bar)
        view.content = window_handle

        header_bar.tap do |bar|
          bar.pack_start(add_button)
          bar.pack_end(menu_button)
        end

        window_handle.child = stack

        stack.tap do |st|
          st.add_named(welcome_page.build, WELCOME_CHILD)
          st.add_named(loading_page.build, LOADING_CHILD)
          st.add_named(convert_page.build, CONVERT_CHILD)
          st.add_named(invalid_image_page.build, INVALID_CHILD)
          st.add_named(converting_page.build, CONVERTING_CHILD)
        end
      end
    end

    def setup_callbacks
      convert_page.connect_convert { save_files }
      converting_page.connect_cancel { convert_cancel }

      drop_target.signal_connect('drop') do |_, value, _, _|
        on_drop(value)
      end

      window.signal_connect('close-request') do
        on_close_request
      end

      # Both flow boxes hide the thumbnails the user has removed. The short
      # strip also hides anything past the tiles it is showing, which is how
      # the "+N" tile stays last.
      convert_page.image_container.set_filter_func do |child|
        child.index >= @elements || !@removed.include?(child.index)
      end
      all_images_page.flow_box.set_filter_func do |child|
        !@removed.include?(child.index)
      end
    end

    def setup_actions
      WINDOW_ACTIONS.each do |name|
        Gio::SimpleAction.new(name, nil).tap do |action|
          action.signal_connect('activate') { send(:"action_#{name.tr('-', '_')}") }
          window.add_action(action)
        end
      end
    end

    # --- Actions ----------------------------------------------------------

    def action_close = window.destroy
    def action_add = add_dialog
    def action_clear = clear
    def action_about = AboutDialog.new(window).present
    def action_show_help_overlay = shortcuts_dialog.present(window)
    def action_paste = load_clipboard

    # --- Opening files ----------------------------------------------------

    def file_chooser = @file_chooser ||= FileChooser.new(window)

    # Upstream's add_dialog(), which passes no current paths: the dialog's
    # same-file guard is there for callers that have some, and this one adds
    # to what is loaded rather than replacing it.
    def add_dialog
      file_chooser.open_images(
        current_paths: [],
        on_start:      method(:open_load),
        on_success:    method(:open_success),
        on_error:      method(:open_error),
      )
    end

    def open_load
      switch_to_loading_generally
      loading_page.start
    end

    # Upstream's open_error(): a failed pick with a message is a file the app
    # cannot read, which is the invalid-image page; a dismissed dialog says
    # nothing at all.
    def open_error(error)
      if error
        switch_to_invalid_image
      end
    end

    # Upstream's open_success(): the new files go in front of the ones already
    # loaded, duplicates by path are dropped, and files that have since
    # disappeared are left out. The removed set is cleared, because the
    # indices it holds are about to mean something else.
    def open_success(files)
      active_files.then do |previous|
        previous.map(&:path).then do |paths|
          @files = files.reject { |file| paths.include?(file.path) }
                        .concat(previous)
                        .select(&:exists?)
        end
      end
      @removed = []
      switch_to_loading_generally
      load_frames
    end

    # Upstream's load_frames(): `magick identify` on every file, off the main
    # thread. A file that cannot be identified makes the whole pick invalid.
    def load_frames
      Magick.probe(@files.map(&:path)) do |results|
        if results.any?(&:nil?)
          switch_to_invalid_image
        else
          apply_probe_results(results)
          load_textures
        end
      end
    end

    def apply_probe_results(results)
      @files.zip(results).each do |file, (frame_count, dimensions)|
        file.frame_count = frame_count
        dimensions.then do |dims|
          if dims
            file.width = dims[0]
            file.height = dims[1]
          end
        end
      end
    end

    # Upstream's load_pixbuf(): a thumbnail is only loaded for a format a
    # pixbuf loader handles, only when the image is small enough to be cheap,
    # and only for the first ten such files.
    def load_textures
      loadable = 0
      @files.each do |file|
        if thumbnailable?(file) && loadable < TEXTURE_LIMIT
          loadable += 1
          file.texture = load_texture(file.path)
        end
      end
      load_textures_finished
    end

    def thumbnailable?(file)
      file.kind.supports_pixbuf? && file.area.to_i.positive? && file.area < MAX_THUMBNAIL_AREA
    end

    # Gdk::Texture.new takes a GLib::Bytes of encoded image data directly, so
    # the file is read here rather than handed over as a GFile.
    def load_texture(path)
      Gdk::Texture.new(GLib::Bytes.new(File.binread(path)))
    rescue GLib::Error, SystemCallError
      nil
    end

    # Upstream's load_pixbuf_finished(): the resize entries only get a size
    # when every loaded image shares one, the thumbnails are rebuilt, and the
    # convert page is shown if the user is still looking at the first page.
    def load_textures_finished
      shared_dimensions.then do |dims|
        @image_width = dims&.first
        @image_height = dims&.last
      end

      construct_short_thumbnail
      update_full_image_container
      convert_page.update(
        files:        active_files,
        image_width:  @image_width,
        image_height: @image_height,
      )
      switch_back_from_loading
      all_images_page.show_images
      if on_main_page?
        switch_to_convert
      end
    end

    def shared_dimensions
      active_files.map(&:dimensions).uniq.then do |all|
        if all.length == 1
          all.first
        end
      end
    end

    # Upstream's load_clipboard(): a pasted image is written out as a PNG
    # first, because every later step works on paths.
    def load_clipboard
      window.clipboard.then do |clipboard|
        if clipboard.formats.contain_mime_type?(PASTEABLE_IMAGE_MIME)
          paste_texture(clipboard)
        elsif clipboard.formats.contain_mime_type?(PASTEABLE_FILES_MIME)
          paste_file_list(clipboard)
        end
      end
    end

    def paste_texture(clipboard)
      clipboard.read_texture_async(nil) do |_, result|
        clipboard.read_texture_finish(result).then do |texture|
          if texture
            save_pasted_texture(texture)
          end
        end
      rescue GLib::Error => e
        warn "Paste failed: #{e.message}"
      end
    end

    def save_pasted_texture(texture)
      JobFile.from_clipboard.then do |job_file|
        File.join(TempDir.parent, job_file.filename).then do |path|
          FileUtils.mkdir_p(TempDir.parent)
          texture.save_to_png(path)
          InputFile.new_for_path(path).then do |input|
            if input
              open_success([input])
            end
          end
        end
      end
    end

    # The portal hands a pasted file selection over as newline-separated paths.
    def paste_file_list(clipboard)
      clipboard.read_text_async(nil) do |_, result|
        clipboard.read_text_finish(result).to_s.lines.map(&:strip).reject(&:empty?)
                 .filter_map { |path| InputFile.new_for_path(path) }
                 .then { |inputs| open_success(inputs) }
      rescue GLib::Error => e
        warn "Paste failed: #{e.message}"
      end
    end

    # Upstream's drop handler.
    def on_drop(value)
      value.files.then do |files|
        if files.empty?
          show_toast(_('Unable to access dropped files'))
          false
        else
          open_files(files.map { |file| InputFile.new_for_file(file) })
          true
        end
      end
    end

    # --- The thumbnail strips ---------------------------------------------

    def active_files
      @files.each_with_index
            .reject { |_, index| @removed.include?(index) }
            .map { |file, _| file }
    end

    def files_count = @files.length - @removed.length

    # Upstream's remove_file(): the last thumbnail removed clears the window.
    def remove_file(index)
      @removed << index
      if files_count.zero?
        clear
      else
        construct_short_thumbnail
        convert_page.update(
          files:        active_files,
          image_width:  @image_width,
          image_height: @image_height,
        )
      end
    end

    # Upstream's clear().
    def clear
      @files = []
      @removed = []
      switch_to_welcome
    end

    # Upstream's construct_short_thumbnail(): walk the files until six are
    # visible, then look ahead — if anything is still to come, give the last
    # slot up to the "+N" tile instead.
    def construct_short_thumbnail
      elements = 0
      visible = 0

      while visible < SHORT_STRIP_LENGTH && elements < @files.length
        unless @removed.include?(elements)
          visible += 1
        end
        elements += 1
      end

      remaining = (elements...@files.length).any? { |index| !@removed.include?(index) }
      if remaining
        elements -= 1
      end

      update_image_container(elements, remaining)
    end

    # Upstream's update_image_container(). A removed file still gets an empty
    # FlowBoxChild so the indices the filter and the remove handlers use keep
    # lining up with the store.
    def update_image_container(count, remaining)
      clear_flow_box(convert_page.image_container)

      @files.take(count).each_with_index do |file, index|
        if @removed.include?(index)
          convert_page.image_container.append(Gtk::FlowBoxChild.new)
        else
          convert_page.image_container.append(thumbnail_child(file, index))
        end
      end

      @elements = count

      if remaining
        convert_page.image_container.append(rest_child)
      end

      apply_container_width
      convert_page.image_container.invalidate_filter
    end

    # Upstream's update_full_image_container().
    def update_full_image_container
      clear_flow_box(all_images_page.flow_box)

      @files.each_with_index do |file, index|
        all_images_page.flow_box.append(thumbnail_child(file, index))
      end
    end

    def thumbnail_child(file, index)
      Gtk::FlowBoxChild.new.tap do |child|
        ImageThumbnail.new(
          texture:    file.texture,
          caption:    file.caption,
          dimensions: file.dimensions,
        ).tap do |thumbnail|
          child.child = thumbnail.build
          thumbnail.connect_remove_clicked { on_thumbnail_removed(index) }
        end
      end
    end

    def rest_child
      Gtk::FlowBoxChild.new.tap do |child|
        child.focusable = false
        ImageRest.new(files_count - (SHORT_STRIP_LENGTH - 1)).tap do |rest|
          child.child = rest.build
          rest.connect_clicked { navigation.push_by_tag(AllImagesPage::TAG) }
        end
      end
    end

    def on_thumbnail_removed(index)
      remove_file(index)
      convert_page.image_container.invalidate_filter
      all_images_page.flow_box.invalidate_filter
    end

    # Upstream's trailing match in update_image_container: one or two images
    # fill the width, three or more sit in a centred three-wide grid.
    def apply_container_width
      convert_page.image_container.tap do |box|
        if files_count.between?(1, 2)
          box.hexpand = true
          box.max_children_per_line = files_count
          box.halign = :fill
        else
          box.hexpand = false
          box.max_children_per_line = 3
          box.halign = :baseline
        end
      end
    end

    def clear_flow_box(box)
      while box.first_child
        box.remove(box.first_child)
      end
    end

    # --- Stack navigation -------------------------------------------------

    def switch_to_convert
      add_button.visible = true
      stack.visible_child_name = CONVERT_CHILD
    end

    def switch_to_converting
      add_button.visible = false
      stack.visible_child_name = CONVERTING_CHILD
    end

    def switch_to_welcome
      add_button.visible = false
      stack.visible_child_name = WELCOME_CHILD
    end

    def switch_to_invalid_image
      add_button.visible = false
      stack.visible_child_name = INVALID_CHILD
    end

    def switch_to_loading
      add_button.visible = false
      stack.visible_child_name = LOADING_CHILD
      loading_page.start
    end

    def switch_back_from_loading
      loading_page.stop
      all_images_page.stop_loading
      all_images_page.add_button.visible = true
    end

    # Upstream's switch_to_stack_loading_generally(): whichever of the two
    # spinners the user can actually see is the one that spins.
    def switch_to_loading_generally
      if on_main_page?
        switch_to_loading
      else
        all_images_page.add_button.visible = false
        all_images_page.show_loading
      end
    end

    def on_main_page? = navigation.visible_page&.tag == MAIN_TAG

    # --- Saving and converting --------------------------------------------

    # Upstream's save_files(): what the run will produce decides which dialog
    # is raised and what it suggests as a name.
    def save_files
      convert_page.selected_output.then do |output|
        active_files.first.then do |first|
          if output && first
            choose_destination(output, first)
          end
        end
      end
    end

    def choose_destination(output, first)
      File.dirname(first.path).then do |folder|
        save_format(output).then do |format|
          if format.directory?
            file_chooser.choose_folder(
              default_folder: folder,
              on_success:     method(:convert_start),
              on_error:       method(:save_error),
            )
          else
            file_chooser.save_output(
              default_name:   "#{default_name(output)}.#{format.extension}",
              format:         format,
              default_folder: folder,
              on_success:     method(:convert_start),
              on_error:       method(:save_error),
            )
          end
        end
      end
    end

    # Upstream writes "images" for a bundle and the first file's stem for a
    # single file.
    def default_name(output)
      if bundled?(output)
        'images'
      else
        active_files.first.stem
      end
    end

    def save_format(output)
      if bundled?(output)
        bundle_format(output)
      else
        OutputType.file(output)
      end
    end

    def bundle_format(output)
      if output.extension == 'pdf' && convert_page.single_pdf?
        OutputType.file(output)
      else
        OutputType.compression(convert_page.selected_compression || CompressionType::DIRECTORY)
      end
    end

    # The run produces more than one file: several inputs, or several frames
    # the export format cannot keep as an animation.
    def bundled?(output)
      active_files.length > 1 ||
        (active_files.sum(&:frame_count) > 1 && !output.supports_animation?)
    end

    def save_error(error)
      if error
        show_toast(error)
      end
    end

    # Upstream's convert_start().
    def convert_start(format, path)
      convert_page.convert_button.sensitive = false
      converting_page.reset
      convert_page.save_options

      @temp_dir = TempDir.create
      job_inputs(convert_page.selected_output).then do |inputs|
        outputs = inputs.map { |input| @temp_dir.file_path(output_job_file(input)) }
        run_jobs(
          inputs,
          outputs,
          format,
          path,
        )
      end

      switch_to_converting
    end

    def output_job_file(input)
      JobFile.new(
        file_type:    input[:output_type],
        desired_name: input[:output_name],
      )
    end

    def run_jobs(inputs, outputs, format, path)
      Magick.run_jobs(
        groups:      job_groups(inputs, outputs),
        children:    @children,
        on_progress: ->(done, total) { converting_page.progress(done, total) },
        on_failure:  ->(message) { convert_failed(message) },
        on_success:  -> { collect_output(format, path, outputs) },
      )
    end

    def job_groups(inputs, outputs)
      inputs.zip(outputs).map do |input, output|
        [
          Magick.generate_job(
            input_path:  input[:input_path],
            input_type:  input[:input_type],
            output_path: output,
            output_type: input[:output_type],
            dpi:         convert_page.dpi,
            defaults:    convert_page.job_defaults,
          ).command,
        ]
      end
    end

    # Upstream's job_input: the stems are made unique first (two files called
    # "cover" become "cover" and "cover_1"), then each file is expanded into
    # the frames the conversion will actually produce.
    def job_inputs(output_type)
      unique_stems.flat_map do |file, stem|
        frames_for(file, stem, output_type).map do |frame, name|
          {
            input_path:  frame,
            input_type:  file.kind,
            output_type: output_type,
            output_name: name,
          }
        end
      end
    end

    def unique_stems
      taken = []
      active_files.sort_by(&:stem).map do |file|
        unique_stem(file.stem, taken).then do |stem|
          taken << stem
          [file, stem]
        end
      end
    end

    def unique_stem(stem, taken)
      if taken.include?(stem)
        suffix = 1
        while taken.include?("#{stem}_#{suffix}")
          suffix += 1
        end
        "#{stem}_#{suffix}"
      else
        stem
      end
    end

    # Which `magick` inputs one file turns into. A PDF, and an animation whose
    # output cannot animate, become one input per page or frame; an animation
    # that stays animated is passed whole; everything else is read as frame 0,
    # which is what keeps a multi-layer TIFF from writing a dozen files.
    def frames_for(file, stem, output_type)
      extension = output_type.extension
      if file.kind.extension == 'pdf'
        numbered_frames(file, stem, extension)
      elsif file.frame_count == 1
        [["#{file.path}[0]", "#{stem}.#{extension}"]]
      elsif file.kind.supports_animation? && output_type.supports_animation?
        [[file.path, "#{stem}.#{extension}"]]
      elsif file.kind.supports_animation?
        numbered_frames(file, stem, extension)
      else
        [["#{file.path}[0]", "#{stem}.#{extension}"]]
      end
    end

    def numbered_frames(file, stem, extension)
      (0...file.frame_count).map do |frame|
        ["#{file.path}[#{frame}]", "#{stem}[#{frame}].#{extension}"]
      end
    end

    # Upstream's move_output().
    def collect_output(format, path, outputs)
      converting_page.collecting
      Magick.collect(
        output_type: format,
        path:        path,
        files:       outputs,
        children:    @children,
        on_finished: lambda do |error|
          if error
            convert_failed(error)
          else
            convert_success(format, path)
          end
        end,
      )
    end

    # Upstream's convert_failed(): the run is stopped, whatever is still
    # running is killed, and the child's stderr is shown verbatim.
    def convert_failed(message)
      convert_clean
      unless @children.canceled?
        @children.cancel
        ErrorDialog.new(window, message) { |text| copy_error(text) }.present
        switch_to_convert
      end
    end

    def copy_error(text)
      window.clipboard.set(text)
      show_toast(_('Error copied to clipboard'))
    end

    # Upstream's convert_success(): a toast with an Open button on it.
    def convert_success(format, path)
      convert_clean
      @children.cancel
      Adwaita::Toast.new(_('Image converted')).tap do |toast|
        toast.button_label = _('Open')
        toast.signal_connect('button-clicked') { open_result(format, path) }
        toast_overlay.add_toast(toast)
      end
      switch_to_convert
    end

    # Upstream asks the portal; the bindings' equivalent is a FileLauncher,
    # which hands a directory to the file manager and a file to its default
    # application.
    def open_result(format, path)
      Gtk::FileLauncher.new(Gio::File.open(path: path)).tap do |launcher|
        if format.directory?
          launcher.open_containing_folder(window, nil)
        else
          launcher.launch(window, nil)
        end
      end
    end

    def convert_clean
      @temp_dir.then do |dir|
        if dir
          dir.clean
          @temp_dir = nil
        end
      end
      convert_page.convert_button.sensitive = true
    end

    # Upstream's convert_cancel(): the Cancel button on the progress page.
    def convert_cancel
      StopConvertingDialog.new(window) do
        @children.cancel
        convert_clean
        switch_to_convert
        show_toast(_('Converting Cancelled'))
      end.present
    end

    # Upstream's close_request(): the geometry is recorded, and a run in
    # progress holds the window open until the user agrees to lose it.
    def on_close_request
      @settings.remember(window)
      if @children.canceled?
        false
      else
        StopConvertingDialog.new(window) do
          @children.cancel
          convert_clean
          window.close
        end.present
        true
      end
    end

    def show_toast(text) = toast_overlay.add_toast(Adwaita::Toast.new(text))
end
