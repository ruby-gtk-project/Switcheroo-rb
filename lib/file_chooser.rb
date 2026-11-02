# frozen_string_literal: true

require 'adwaita'

require_relative 'file_type'
require_relative 'input_file'

# FileChooser puts up the three file dialogs the app needs.
#
# Ported from upstream's src/file_chooser.rs: open_files() picks the images to
# load, choose_output_file() picks where a single file (or a ZIP, or a merged
# PDF) is written, and choose_output_folder() picks the directory the loose
# results go into.
#
# Upstream awaits the *_future variants and reports its outcome through three
# callbacks (start, success, error); the Ruby bindings take a block that is
# called with the GAsyncResult instead, and the same three callbacks are passed
# in. A dismissed dialog raises GLib::Error, which is upstream's `Err(_)` arm:
# the error callback is called with nil, meaning "say nothing".
#
# The extension checks on the save dialog are upstream's: a name with no
# extension is "Unspecified filetype", one the app does not know is "Unknown
# filetype", and one that disagrees with the chosen export format is "Used the
# wrong filetype".
#
class FileChooser
  ACCEPT_LABEL = '_Select Images'
  IMAGES_FILTER_NAME = 'Images'

  UNSUPPORTED_FILETYPE = 'Unsupported filetype'
  UNSPECIFIED_FILETYPE = 'Unspecified filetype'
  UNKNOWN_FILETYPE = 'Unknown filetype'
  WRONG_FILETYPE = 'Used the wrong filetype'

  # Upstream's load_files(): turns the chosen GFiles into InputFiles, drops
  # everything that is not a readable input format, and reports the whole pick
  # as unsupported when nothing survives.
  def self.load_files(files, on_start:, on_success:, on_error:)
    on_start.call
    files.filter_map { |file| InputFile.new_for_file(file) }
         .select { |input| input.kind.input? }
         .then do |inputs|
      if inputs.empty?
        on_error.call(UNSUPPORTED_FILETYPE)
      else
        on_success.call(inputs)
      end
    end
  end

  def initialize(parent)
    @parent = parent
  end

  # Upstream's open_files(). `current_paths` is upstream's guard against
  # re-loading: picking the one file that is already open does nothing at all,
  # not even a reload.
  def open_images(current_paths:, on_start:, on_success:, on_error:)
    open_dialog.open_multiple(@parent, nil) do |_, result|
      chosen_files(open_dialog.open_multiple_finish(result)).then do |files|
        unless unchanged?(current_paths, files)
          self.class.load_files(
            files,
            on_start:   on_start,
            on_success: on_success,
            on_error:   on_error,
          )
        end
      end
    rescue GLib::Error
      on_error.call(nil)
    end
  end

  # Upstream's choose_output_file().
  def save_output(default_name:, format:, default_folder:, on_success:, on_error:)
    save_dialog(default_name, format, default_folder).then do |dialog|
      dialog.save(@parent, nil) do |_, result|
        validate_output(dialog.save_finish(result), format).then do |path, error|
          if error
            on_error.call(error)
          else
            on_success.call(format, path)
          end
        end
      rescue GLib::Error
        on_error.call(nil)
      end
    end
  end

  # Upstream's choose_output_folder(), which always reports a Directory output.
  def choose_folder(default_folder:, on_success:, on_error:)
    folder_dialog(default_folder).then do |dialog|
      dialog.select_folder(@parent, nil) do |_, result|
        dialog.select_folder_finish(result).then do |folder|
          on_success.call(OutputType.compression(CompressionType::DIRECTORY), folder.path)
        end
      rescue GLib::Error
        on_error.call(nil)
      end
    end
  end

  def open_dialog
    @open_dialog ||= Gtk::FileDialog.new.tap do |dialog|
      dialog.accept_label = ACCEPT_LABEL
      dialog.modal = true
      dialog.default_filter = images_filter
    end
  end

  def images_filter
    @images_filter ||= Gtk::FileFilter.new.tap do |filter|
      filter.name = IMAGES_FILTER_NAME
      FileType.input_formats.each { |file_type| filter.add_mime_type(file_type.mime) }
    end
  end

  private

    def save_dialog(default_name, format, default_folder)
      Gtk::FileDialog.new.tap do |dialog|
        dialog.modal = true
        dialog.default_filter = format_filter(format)
        dialog.initial_name = default_name
        if default_folder
          dialog.initial_folder = Gio::File.open(path: default_folder)
        end
      end
    end

    def folder_dialog(default_folder)
      Gtk::FileDialog.new.tap do |dialog|
        if default_folder
          dialog.initial_folder = Gio::File.open(path: default_folder)
        end
      end
    end

    def format_filter(format)
      Gtk::FileFilter.new.tap do |filter|
        filter.add_mime_type(format.mime)
      end
    end

    def chosen_files(list) = list.to_a

    def unchanged?(current_paths, files)
      current_paths.length == 1 &&
        files.length == 1 &&
        current_paths.first == files.first.path
    end

    # Returns [path, error]; exactly one of the two is set.
    def validate_output(file, format)
      file.path.then do |path|
        File.extname(path).delete_prefix('.').then do |extension|
          if extension.empty?
            [nil, UNSPECIFIED_FILETYPE]
          else
            validate_extension(path, extension, format)
          end
        end
      end
    end

    def validate_extension(path, extension, format)
      OutputType.from_string(extension).then do |chosen|
        if chosen.nil?
          [nil, UNKNOWN_FILETYPE]
        elsif chosen != format
          [nil, WRONG_FILETYPE]
        else
          [path, nil]
        end
      end
    end
end
