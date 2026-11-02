# frozen_string_literal: true

require 'adwaita'

require_relative 'translations'

# PrimaryMenu is the model behind the hamburger button in the header bar.
#
# Ported from the `menu primary_menu` block of upstream's
# data/resources/blueprints/window.blp: two sections, the first acting on the
# window's images and the second on the app itself.
#
module PrimaryMenu
  # The gettext gem resolves a bound text domain through the *ancestors of the
  # receiver*, and for a message looked up from a class method the receiver is
  # this module itself. Including Translations only in `class << self` puts it
  # in the singleton's ancestors, where that lookup never looks, so every
  # message below came back as its own English msgid — with the German
  # catalogue loaded and every instance-side lookup in the port translating
  # correctly. It is included here as well so #ancestors carries it.
  include Translations

  class << self
    include Translations

    def build
      Gio::Menu.new.tap do |menu|
        menu.append_section(nil, section(window_items))
        menu.append_section(nil, section(about_items))
      end
    end

    private

      def window_items
        [
          [_('Paste From Clipboard'), 'win.paste'],
          [_('New Window'), 'app.new-window'],
          [_('Clear Window'), 'win.clear'],
        ]
      end

      def about_items
        [
          [_('Keyboard Shortcuts'), 'win.show-help-overlay'],
          [_('About Switcheroo'), 'win.about'],
        ]
      end

      def section(items)
        Gio::Menu.new.tap do |menu|
          items.each { |label, action| menu.append(label, action) }
        end
      end
  end
end
