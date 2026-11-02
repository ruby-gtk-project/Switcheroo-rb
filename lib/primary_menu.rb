# frozen_string_literal: true

require 'adwaita'

# PrimaryMenu is the model behind the hamburger button in the header bar.
#
# Ported from the `menu primary_menu` block of upstream's
# data/resources/blueprints/window.blp: two sections, the first acting on the
# window's images and the second on the app itself.
#
module PrimaryMenu
  WINDOW_ITEMS = [
    ['Paste From Clipboard', 'win.paste'],
    ['New Window', 'app.new-window'],
    ['Clear Window', 'win.clear'],
  ].freeze

  ABOUT_ITEMS = [
    ['Keyboard Shortcuts', 'win.show-help-overlay'],
    ['About Switcheroo', 'win.about'],
  ].freeze

  class << self
    def build
      Gio::Menu.new.tap do |menu|
        menu.append_section(nil, section(WINDOW_ITEMS))
        menu.append_section(nil, section(ABOUT_ITEMS))
      end
    end

    private

      def section(items)
        Gio::Menu.new.tap do |menu|
          items.each { |label, action| menu.append(label, action) }
        end
      end
  end
end
