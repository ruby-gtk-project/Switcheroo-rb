# frozen_string_literal: true

require 'fileutils'

require 'gio2'

# Settings is upstream's GSettings, reached through the same schema.
#
# Ported from upstream's use of `gio::Settings` in src/window.rs together with
# data/io.gitlab.adhami3310.Converter.gschema.xml.in, which the port now ships
# verbatim. The keys, their types, their defaults and the three enums are the
# schema's, so a user upgrading from upstream Switcheroo keeps every stored
# preference: both sides read and write
# /io/gitlab/adhami3310/Converter/ in dconf, and `gsettings`, `dconf-editor`,
# `gsettings reset-recursively` and backup tools see the same keys.
#
# The three enum keys are read and written with get_enum/set_enum, carrying the
# same integers upstream carries: the position of the chosen value in
# FileType::output_formats(), CompressionType::possible_output(false) and the
# resize-unit dropdown. Upstream's output-format indices do not line up with
# the value numbers its own schema declares; the port reproduces that rather
# than diverging from it, and FINDINGS.md records the suspected upstream bug.
#
# Running from a checkout needs the schema compiled somewhere GLib will look.
# If the installed schema is present (the Rake install task puts it in
# <prefix>/share/glib-2.0/schemas) it is used; otherwise the shipped
# .gschema.xml.in is compiled into XDG_CACHE_HOME and read from there, so the
# same dconf keys are reached either way.
#
class Settings
  SCHEMA_ID = 'io.gitlab.adhami3310.Converter'
  SCHEMA_PATH = '/io/gitlab/adhami3310/Converter/'
  GETTEXT_PACKAGE = 'switcheroo'

  SCHEMA_SOURCE_FILE = File.expand_path(
    "../data/#{SCHEMA_ID}.gschema.xml.in",
    __dir__,
  )

  INTEGER_KEYS = %w[window-width window-height quality dpi].freeze
  BOOLEAN_KEYS = %w[is-maximized].freeze
  ENUM_KEYS = %w[output-format compression-format resize-type].freeze
  KEYS = (INTEGER_KEYS + BOOLEAN_KEYS + ENUM_KEYS).freeze

  def initialize(settings: nil)
    @settings = settings
  end

  def [](key)
    key.to_s.then do |name|
      case kind_of_key(name)
      when :integer then settings.get_int(name)
      when :boolean then settings.get_boolean(name)
      else settings.get_enum(name)
      end
    end
  end

  def []=(key, value)
    key.to_s.then do |name|
      case kind_of_key(name)
      when :integer then settings.set_int(name, value.to_i)
      when :boolean then settings.set_boolean(name, value ? true : false)
      else settings.set_enum(name, value.to_i)
      end
    end
    value
  end

  def location = SCHEMA_PATH

  # Named accessors for every key, so callers do not repeat the string keys.
  KEYS.each do |key|
    method_name = key.tr('-', '_')
    define_method(method_name) { self[key] }
    define_method(:"#{method_name}=") { |value| self[key] = value }
  end

  def maximized? = self['is-maximized'] == true

  # Upstream's AppWindow::load_window_size().
  def apply_to(window)
    window.set_default_size(self['window-width'], self['window-height'])
    if maximized?
      window.maximize
    end
  end

  # Upstream's AppWindow::save_window_size(), called from close-request. The
  # size is only recorded when the window is not maximized, so the restored
  # size is the one the user actually chose.
  def remember(window)
    self['is-maximized'] = window.maximized?
    unless window.maximized?
      self['window-width'] = window.default_width
      self['window-height'] = window.default_height
    end
  end

  def settings
    @settings ||= Gio::Settings.new(schema: schema, path: SCHEMA_PATH)
  end

  private

    def kind_of_key(name)
      if INTEGER_KEYS.include?(name)
        :integer
      elsif BOOLEAN_KEYS.include?(name)
        :boolean
      elsif ENUM_KEYS.include?(name)
        :enum
      else
        raise ArgumentError, "#{SCHEMA_ID} has no key #{name}"
      end
    end

    def schema = installed_schema || compiled_schema

    def installed_schema
      Gio::SettingsSchemaSource.default&.lookup(SCHEMA_ID, true)
    end

    # The schema the port ships, compiled on demand so a checkout reaches the
    # same dconf path an installed copy does.
    def compiled_schema
      compile_schema
      Gio::SettingsSchemaSource.new(schema_cache_directory, nil, true)
                               .lookup(SCHEMA_ID, false)
    end

    def compile_schema
      FileUtils.mkdir_p(schema_cache_directory)
      File.write(
        File.join(schema_cache_directory, "#{SCHEMA_ID}.gschema.xml"),
        File.read(SCHEMA_SOURCE_FILE)
            .gsub('@app-id@', SCHEMA_ID)
            .gsub('@gettext-package@', GETTEXT_PACKAGE),
      )
      system('glib-compile-schemas', schema_cache_directory, out: File::NULL)
    end

    def schema_cache_directory
      File.join(
        ENV.fetch('XDG_CACHE_HOME', File.expand_path('~/.cache')),
        'switcheroo-rb',
        'schemas',
      )
    end
end
