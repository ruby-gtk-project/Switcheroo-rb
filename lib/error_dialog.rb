# frozen_string_literal: true

require 'adwaita'

# ErrorDialog shows what ImageMagick complained about.
#
# Ported from the adw::AlertDialog built in convert_failed() in upstream's
# src/window.rs: the child process's stderr, verbatim, in a monospace label
# inside a scrolled card that grows from 200 to 400 pixels tall, with a Copy to
# Clipboard response beside Close.
#
class ErrorDialog
  HEADING = 'Error While Processing'

  RESPONSES = {
    'ok'   => '_Close',
    'copy' => '_Copy to Clipboard',
  }.freeze

  MIN_HEIGHT = 200
  MAX_HEIGHT = 400

  def initialize(parent, message, &on_copy)
    @parent = parent
    @message = message
    @on_copy = on_copy
  end

  def present
    dialog.tap do |alert|
      RESPONSES.each { |id, label| alert.add_response(id, label) }
      alert.set_response_appearance('copy', :suggested)
      alert.extra_child = scroller

      scroller.child = message_label

      alert.signal_connect('response') do |_, response|
        if response == 'copy'
          @on_copy.call(@message)
        end
      end

      alert.present(@parent)
    end
  end

  def dialog = @dialog ||= Adwaita::AlertDialog.new(HEADING, nil)

  def scroller
    @scroller ||= Gtk::ScrolledWindow.new.tap do |sw|
      sw.min_content_height = MIN_HEIGHT
      sw.max_content_height = MAX_HEIGHT
      sw.add_css_class('card')
    end
  end

  def message_label
    @message_label ||= Gtk::Label.new(@message).tap do |label|
      label.margin_top = 12
      label.margin_bottom = 12
      label.margin_start = 12
      label.margin_end = 12
      label.xalign = 0.0
      label.yalign = 0.0
      label.wrap = true
      label.wrap_mode = :word_char
      label.add_css_class('monospace')
    end
  end
end
