# frozen_string_literal: true

require 'adwaita'

require_relative 'app_window'
require_relative 'config'
require_relative 'input_file'
require_relative 'settings'
require_relative 'style'
require_relative 'translations'

# App is the application object.
#
# Ported from upstream's src/main.rs and src/application.rs, plus the few
# constants src/config.rs.in generates at build time. It registers under the
# upstream app id with HANDLES_OPEN, so opening images from the file manager
# reaches this process; it takes a --new-window option that a second launch
# uses to ask the running instance for another window; and it binds the seven
# accelerators upstream's setup_accels() does.
#
# I had built this on `Gtk::Application` and written that the bindings' Adwaita
# application is unusable, without checking, and without checking what
# `adw_application` does for the user that a bare `Adwaita.init` does not — the
# colour-scheme and high-contrast tracking its style manager installs, and the
# Adwaita option group in `--help`. It is an `Adwaita::Application` now, which
# is what upstream subclasses, and it works: `Adwaita::Application.new`,
# `#register` and `Adwaita::ApplicationWindow.new(app)` were all driven under
# this version of the bindings before this was written.
# Upstream: src/application.rs, `Converter(adw::Application)`.
#
# The icon search path is upstream's too, added in the window's constructed():
# the nine icons the app ships are not in the system theme, so the theme has to
# be told where they live.
#
class App
  include Translations

  APP_ID = Config::APP_ID
  APP_NAME = Config::APP_NAME

  # Upstream's setup_accels().
  ACCELERATORS = {
    'app.new-window'        => ['<Control>n'],
    'app.quit'              => ['<Control>q'],
    'win.clear'             => ['<Control>r'],
    'win.add'               => ['<Control>o'],
    'win.close'             => ['<Control>w'],
    'win.paste'             => ['<Control>v'],
    'win.show-help-overlay' => ['<Control>question'],
  }.freeze

  NEW_WINDOW_OPTION = 'new-window'

  def initialize(app_id: APP_ID, flags: :handles_open, settings: nil)
    @app_id = app_id
    @flags = flags
    @settings = settings || Settings.new
    @windows = []
  end

  def build
    app.tap do |a|
      a.add_main_option(
        NEW_WINDOW_OPTION,
        'w'.ord,
        :none,
        :none,
        _('Open a new window'),
        nil,
      )

      setup_actions

      a.signal_connect('startup') { on_startup }
      a.signal_connect('activate') { on_activate }
      a.signal_connect('open') { |_, files, _| on_open(files) }
      a.signal_connect('handle-local-options') { |_, options| on_local_options(options) }
    end
  end

  def run = app.run(ARGV)

  def app
    @app ||= begin
      GLib.application_name = _(APP_NAME)
      Adwaita::Application.new(@app_id, @flags)
    end
  end

  private

    def on_startup
      Style.load
      add_icon_search_path
      Gtk::Window.set_default_icon_name(@app_id)
    end

    # Upstream's activate(): an existing window is raised, otherwise a new one
    # is opened.
    def on_activate
      app.active_window.then do |window|
        if window
          window.present
        else
          present_main_window
        end
      end
    end

    # Upstream's open(): the files that still exist become InputFiles and go
    # to whichever window is now in front.
    def on_open(files)
      present_main_window.then do |window|
        window.open_files(
          files.select(&:exist?)
               .map { |file| InputFile.new_for_file(file) },
        )
      end
    end

    # Upstream's handle_local_options(): --new-window on a second launch is
    # answered by the already-running instance, and this one exits.
    def on_local_options(options)
      if options.contains?(NEW_WINDOW_OPTION)
        app.register
        if app.remote?
          app.activate_action(NEW_WINDOW_OPTION, nil)
          0
        else
          -1
        end
      else
        -1
      end
    end

    # Upstream's setup_gactions().
    def setup_actions
      Gio::SimpleAction.new('quit', nil).tap do |action|
        action.signal_connect('activate') { app.quit }
        app.add_action(action)
      end

      Gio::SimpleAction.new(NEW_WINDOW_OPTION, nil).tap do |action|
        action.signal_connect('activate') { present_main_window }
        app.add_action(action)
      end

      ACCELERATORS.each { |name, accels| app.set_accels_for_action(name, accels) }
    end

    def present_main_window
      AppWindow.new(app, @settings).tap do |window|
        @windows << window
        window.build
        window.present
      end
    end

    # Upstream's constructed(): PKGDATADIR/icons, which here is the data/icons
    # directory next to lib/.
    def add_icon_search_path
      Gdk::Display.default.then do |display|
        if display
          Gtk::IconTheme.get_for_display(display).add_search_path(icon_directory)
        end
      end
    end

    def icon_directory = Config.icon_directory
end
