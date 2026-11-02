# frozen_string_literal: true

require_relative "rb/version"

module Switcheroo
  # Rb is the gem-shaped entry point: requiring "switcheroo/rb" gives the
  # version and the application object without pulling in the widget tree, so
  # the spec harness and anything that only needs to ask what version this is
  # can load it on a machine with no display.
  module Rb
    class << self
      # The gem's own version, which is not the app version upstream tags —
      # that one lives in Config::VERSION, ported from upstream's meson.build.
      def version = VERSION

      # The application object, loaded on demand because it requires GTK.
      def application
        require_relative "../switcheroo"
        ::Switcheroo::Application
      end
    end
  end
end
