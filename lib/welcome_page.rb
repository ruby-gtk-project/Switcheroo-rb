# frozen_string_literal: true

require 'adwaita'

require_relative 'translations'

# WelcomePage is the empty state, shown until an image is loaded.
#
# Ported from the "stack_welcome_page" StackPage of upstream's
# data/resources/blueprints/window.blp: an Adw.StatusPage carrying the app
# icon with the icon-dropshadow style, and one suggested pill button.
#
# Upstream connects open_button's clicked signal to the same add_dialog() the
# win.add action runs; the button here names that action instead, so the
# keyboard shortcut and the button cannot drift apart.
#
class WelcomePage
  include Translations

  ICON_NAME = 'io.gitlab.adhami3310.Converter'

  def build
    status_page.tap do |page|
      page.child = button_box

      button_box.append(open_button)
    end
  end

  def status_page
    @status_page ||= Adwaita::StatusPage.new.tap do |page|
      page.icon_name = ICON_NAME
      page.title = _('Switcheroo')
      page.description = _('Drag and drop images here')
      page.hexpand = true
      page.vexpand = true
      page.add_css_class('icon-dropshadow')
    end
  end

  def button_box = @button_box ||= Gtk::Box.new(:vertical, 12)

  def open_button
    @open_button ||= Gtk::Button.new.tap do |btn|
      btn.label = _('_Open Images…')
      btn.use_underline = true
      btn.valign = :center
      btn.halign = :center
      btn.action_name = 'win.add'
      btn.add_css_class('suggested-action')
      btn.add_css_class('pill')
    end
  end
end
