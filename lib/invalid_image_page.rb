# frozen_string_literal: true

require 'adwaita'

require_relative 'translations'

# InvalidImagePage is the error state for a file ImageMagick could not read.
#
# Ported from the "stack_invalid_image" StackPage of upstream's
# data/resources/blueprints/window.blp. The window shows it when `magick
# identify` produced no output for a file, which means either the file is
# corrupt or the ImageMagick delegate for its format is missing.
#
class InvalidImagePage
  include Translations

  ICON_NAME = 'im-symbolic'

  def build
    status_page
  end

  def status_page
    @status_page ||= Adwaita::StatusPage.new.tap do |page|
      page.icon_name = ICON_NAME
      page.title = _('Could not Load Image')
      page.description = _('This image could be corrupted or may use an unsupported file format.')
      page.hexpand = true
      page.vexpand = true
    end
  end
end
