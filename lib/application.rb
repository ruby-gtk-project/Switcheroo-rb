# frozen_string_literal: true

require 'adwaita'

require_relative 'app_window'
require_relative 'input_file'
require_relative 'settings'
require_relative 'style'

# App is the application object.
#
# Ported from upstream's src/main.rs and src/application.rs, plus the few
# constants src/config.rs.in generates at build time. It registers under the
# upstream app id with HANDLES_OPEN, so opening images from the file manager
# reaches this process; it takes a --new-window option that a second launch
# uses to ask the running instance for another window; and it binds the seven
# accelerators upstream's setup_accels() does.
#
# Upstream is an adw::Application subclass. The Ruby bindings' Adwaita
# application is unusable, so this is a Gtk::Application with Adwaita
# initialised by hand — every Adwaita widget inside it works regardless.
#
# The icon search path is upstream's too, added in the window's constructed():
# the seven symbolic icons the app ships are not in the system theme, so the
# theme has to be told where they live.
#
class App
  APP_ID = 'io.gitlab.adhami3310.Converter'
  APP_NAME = 'Switcheroo'
  GETTEXT_DOMAIN = 'switcheroo'

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
  NEW_WINDOW_DESCRIPTION = 'Open a new window'

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
        NEW_WINDOW_DESCRIPTION,
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
      Adwaita.init
      GLib.application_name = APP_NAME
      Gtk::Application.new(@app_id, @flags)
    end
  end

  private

    def on_startup
      bind_text_domain
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
          Gtk::IconTheme.for_display(display).add_search_path(icon_directory)
        end
      end
    end

    def icon_directory = File.expand_path('../data/icons', __dir__)

    # ruby-glib2 exposes the C gettext entry points only when it was built
    # against libintl; where it was not, the catalogues in po/ go unused and
    # every string stays the English literal it is in the source.
    def bind_text_domain
      if GLib.respond_to?(:bindtextdomain)
        GLib.bindtextdomain(GETTEXT_DOMAIN, locale_directory)
        GLib.textdomain(GETTEXT_DOMAIN)
      end
    end

    def locale_directory = File.expand_path('../po', __dir__)
end
