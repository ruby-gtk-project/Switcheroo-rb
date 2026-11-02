# frozen_string_literal: true

require 'json'
require 'fileutils'

# Settings holds the same keys as upstream's GSettings schema
# (data/io.gitlab.adhami3310.Converter.gschema.xml.in).
#
# Upstream uses GSettings, which needs a compiled schema installed into the
# system's glib-2.0/schemas directory. Requiring an install step to run the
# app from a checkout is worse than the alternative, so — following the same
# decision the gnome-contacts-rb port made — the same keys, defaults and
# semantics are backed by a small JSON file under XDG_CONFIG_HOME.
#
# The three enum keys are stored as their nicks rather than as integers.
# Upstream writes them with `set_enum` passing the *position* in
# FileType::output_formats() / CompressionType::possible_output(false), which
# does not agree with the nick ordering declared in the schema, so a fresh
# profile there starts on whatever format sits at the default enum's index.
# Storing the nick keeps the declared defaults ("jpg", "directory",
# "percentage") meaning what they say.
#
class Settings
  DEFAULTS = {
    'window-width'       => 750,
    'window-height'      => 750,
    'is-maximized'       => false,
    'quality'            => 92,
    'dpi'                => 300,
    'output-format'      => 'jpg',
    'compression-format' => 'directory',
    'resize-type'        => 'percentage',
  }.freeze

  def initialize(path: nil)
    @path = path || default_path
    @values = DEFAULTS.merge(read)
  end

  def [](key) = @values.fetch(key.to_s, DEFAULTS[key.to_s])

  def []=(key, value)
    @values[key.to_s] = value
    write
    value
  end

  def location = @path

  # Named accessors for every key, so callers do not repeat the string keys.
  DEFAULTS.each_key do |key|
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
    @values['is-maximized'] = window.maximized?
    unless window.maximized?
      @values['window-width'] = window.default_width
      @values['window-height'] = window.default_height
    end
    write
  end

  private

    def default_path
      File.join(
        ENV.fetch('XDG_CONFIG_HOME', File.expand_path('~/.config')),
        'switcheroo-rb',
        'settings.json',
      )
    end

    def read
      if File.exist?(@path)
        JSON.parse(File.read(@path))
      else
        {}
      end
    rescue JSON::ParserError => e
      warn "Error parsing #{@path}: #{e.message}"
      {}
    end

    def write
      FileUtils.mkdir_p(File.dirname(@path))
      File.write(@path, JSON.pretty_generate(@values))
    end
end
