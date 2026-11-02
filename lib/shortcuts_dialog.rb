# frozen_string_literal: true

require 'adwaita'

require_relative 'translations'

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
  include Translations

  def build
    tap do |dialog|
      dialog.add(general_section)

      general_section.tap do |section|
        items.each { |title, action| section.add(item(title, action)) }
      end
    end
  end

  def general_section
    @general_section ||= Adwaita::ShortcutsSection.new.tap do |section|
      section.title = p_('shortcut window', 'General')
    end
  end

  private

    # Upstream marks all seven of these with a "shortcut window" msgctxt, so
    # they are looked up with p_() and not _(): the catalogues are keyed on the
    # context as well as the text.
    def items
      [
        [p_('shortcut window', 'Show Shortcuts'), 'win.show-help-overlay'],
        [p_('shortcut window', 'Quit'), 'app.quit'],
        [p_('shortcut window', 'New Window'), 'app.new-window'],
        [p_('shortcut window', 'Clear Window'), 'win.clear'],
        [p_('shortcut window', 'Paste From Clipboard'), 'win.paste'],
        [p_('shortcut window', 'Add Images'), 'win.add'],
      ]
    end

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
