# frozen_string_literal: true

require 'adwaita'

# StopConvertingDialog asks whether to abandon a running conversion.
#
# Ported from the two identical adw::AlertDialog blocks of upstream's
# src/window.rs: close_dialog(), raised when the window is closed mid-run, and
# convert_cancel(), raised by the Cancel button on the progress page. Both put
# up the same question with the same destructive _Stop response; only what
# happens afterwards differs, so the caller passes that in.
#
class StopConvertingDialog
  HEADING = 'Stop converting?'
  BODY = 'You will lose all progress.'

  RESPONSES = {
    'cancel' => '_Cancel',
    'stop'   => '_Stop',
  }.freeze

  def initialize(parent, &on_stop)
    @parent = parent
    @on_stop = on_stop
  end

  def present
    dialog.tap do |alert|
      RESPONSES.each { |id, label| alert.add_response(id, label) }
      alert.set_response_appearance('stop', :destructive)

      alert.signal_connect('response') do |_, response|
        if response == 'stop'
          @on_stop.call
        end
      end

      alert.present(@parent)
    end
  end

  def dialog = @dialog ||= Adwaita::AlertDialog.new(HEADING, BODY)
end
