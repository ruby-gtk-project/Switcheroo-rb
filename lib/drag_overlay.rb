# frozen_string_literal: true

require 'adwaita'

require_relative 'translations'

# DragOverlay tints the whole window while files are hovering over it.
#
# Ported from upstream's src/drag_overlay.rs (itself borrowed from GNOME
# Characters): an Adw.Bin holding a Gtk.Overlay, with a crossfading
# Gtk.Revealer over the content that holds an Adw.StatusPage reading "Drop Here
# to Open". The revealer is untargetable so it never swallows the drop.
#
# The window hands over a Gtk.DropTarget it has already configured; this class
# watches that target's current-drop property and reveals the status page for
# exactly as long as a drag is over the widget, then adds the target as a
# controller so the drop itself is handled by the window's callback.
#
# The CSS node has upstream's real node name, `dragoverlay`
# (src/drag_overlay.rs:30), not a style class standing in for one:
# `Gtk::Widget.set_css_name` works on a `type_register`'d subclass, driven as
# `w.css_name => "dragoverlay"` after `set_css_name('dragoverlay')` in
# `type_register`'s block. `lib/style.rb`'s `dragoverlay` rule matches the
# node directly.
# Upstream: src/drag_overlay.rs:30.
# Port: lib/drag_overlay.rb:30, lib/style.rb:34.
#
class DragOverlay < Adwaita::Bin
  include Translations

  type_register
  set_css_name('dragoverlay')

  STATUS_CSS_CLASS = 'drag-overlay-status-page'
  ICON_NAME = 'document-send-symbolic'

  def initialize(title = nil)
    super()
    @title = title || _('Drop Here to Open')
  end

  def build
    tap do |bin|
      bin.child = overlay

      overlay.tap do |ov|
        ov.add_overlay(revealer)

        revealer.child = status_page
      end
    end
  end

  # What the window puts inside the overlay: everything the drag can land on.
  def content=(widget)
    overlay.child = widget
  end

  # Upstream's set_drop_target(): one target at a time, and revealing the
  # status page for as long as that target holds a drop.
  def drop_target=(target)
    detach_drop_target
    @drop_target = target
    @handler_id = target.signal_connect('notify::current-drop') do
      revealer.reveal_child = !target.current_drop.nil?
    end
    add_controller(target)
  end

  attr_reader :drop_target

  def overlay = @overlay ||= Gtk::Overlay.new

  def revealer
    @revealer ||= Gtk::Revealer.new.tap do |rev|
      rev.can_target = false
      rev.transition_type = :crossfade
      rev.reveal_child = false
    end
  end

  def status_page
    @status_page ||= Adwaita::StatusPage.new.tap do |page|
      page.icon_name = ICON_NAME
      page.title = @title
      page.add_css_class(STATUS_CSS_CLASS)
    end
  end

  private

    def detach_drop_target
      @drop_target.then do |target|
        if target
          remove_controller(target)
          target.signal_handler_disconnect(@handler_id)
          @handler_id = nil
        end
      end
    end
end
