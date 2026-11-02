# frozen_string_literal: true

require 'adwaita'

# InvalidImagePage is the error state for a file ImageMagick could not read.
#
# Ported from the "stack_invalid_image" StackPage of upstream's
# data/resources/blueprints/window.blp. The window shows it when `magick
# identify` produced no output for a file, which means either the file is
# corrupt or the ImageMagick delegate for its format is missing.
#
class InvalidImagePage
  ICON_NAME = 'im-symbolic'
  TITLE = 'Could not Load Image'
  DESCRIPTION = 'This image could be corrupted or may use an unsupported file format.'

  def build
    status_page
  end

  def status_page
    @status_page ||= Adwaita::StatusPage.new.tap do |page|
      page.icon_name = ICON_NAME
      page.title = TITLE
      page.description = DESCRIPTION
      page.hexpand = true
      page.vexpand = true
    end
  end
end
