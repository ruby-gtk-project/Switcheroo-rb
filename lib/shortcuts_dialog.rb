# frozen_string_literal: true

require 'adwaita'

# ShortcutsDialog lists the keyboard shortcuts.
#
# A direct port of the `Adw.ShortcutsDialog help_overlay` block of upstream's
# data/resources/blueprints/window.blp: one "General" section with six items.
#
# Upstream names an action per item and lets Adwaita look the accelerator up
# from the application; this does the same, so the accelerators shown are
# whichever ones Application bound.
#
class ShortcutsDialog < Adwaita::ShortcutsDialog
  ITEMS = [
    ['Show Shortcuts', 'win.show-help-overlay'],
    ['Quit', 'app.quit'],
    ['New Window', 'app.new-window'],
    ['Clear Window', 'win.clear'],
    ['Paste From Clipboard', 'win.paste'],
    ['Add Images', 'win.add'],
  ].freeze

  def build
    tap do |dialog|
      dialog.add(general_section)

      general_section.tap do |section|
        ITEMS.each { |title, action| section.add(item(title, action)) }
      end
    end
  end

  def general_section
    @general_section ||= Adwaita::ShortcutsSection.new.tap do |section|
      section.title = 'General'
    end
  end

  private

  # Positional, not keyword, arguments — even though the error a no-argument
  # new raises advertises the signatures as "title: utf8, accelerator: utf8".
  # The accelerator slot takes an action name just as well, which is what the
  # blueprint's `action-name` does.
    def item(title, action)
      Adwaita::ShortcutsItem.new(title, '').tap do |shortcut|
        shortcut.action_name = action
      end
    end
end
