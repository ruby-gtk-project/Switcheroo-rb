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
