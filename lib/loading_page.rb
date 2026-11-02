# frozen_string_literal: true

require 'adwaita'

# LoadingPage is shown while the dropped or opened files are being probed.
#
# Ported from the "stack_loading" StackPage of upstream's
# data/resources/blueprints/window.blp: an empty Adw.StatusPage whose only
# child is a 32×32 spinner. The window starts and stops that spinner as it
# enters and leaves the loading state, which is why it is exposed.
#
class LoadingPage
  SPINNER_SIZE = 32

  def build
    status_page.tap do |page|
      page.child = spinner
    end
  end

  def status_page = @status_page ||= Adwaita::StatusPage.new

  def spinner
    @spinner ||= Gtk::Spinner.new.tap do |sp|
      sp.valign = :center
      sp.halign = :center
      sp.width_request = SPINNER_SIZE
      sp.height_request = SPINNER_SIZE
    end
  end

  def start = spinner.start
  def stop = spinner.stop
end
