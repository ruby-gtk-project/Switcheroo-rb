# frozen_string_literal: true

# Switcheroo — the Ruby GTK4/Libadwaita port.
#
# Requiring this file loads the whole port without launching it; lib/main.rb is
# the launcher. One upstream source file maps to one lib/<thing>.rb, so the
# requires below read as the upstream file list: the format and colour models,
# the ImageMagick backend, the window and its pages, and the dialogs.
require_relative "config"
require_relative "translations"
require_relative "color"
require_relative "file_type"
require_relative "input_file"
require_relative "settings"
require_relative "style"
require_relative "temp_dir"
require_relative "magick"
require_relative "file_chooser"
require_relative "primary_menu"
require_relative "drag_overlay"
require_relative "image_rest"
require_relative "image_thumbnail"
require_relative "welcome_page"
require_relative "loading_page"
require_relative "invalid_image_page"
require_relative "converting_page"
require_relative "convert_page"
require_relative "all_images_page"
require_relative "about_dialog"
require_relative "shortcuts_dialog"
require_relative "stop_converting_dialog"
require_relative "error_dialog"
require_relative "app_window"
require_relative "application"
require_relative "switcheroo/application"
