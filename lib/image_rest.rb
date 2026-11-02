# frozen_string_literal: true

require 'adwaita'

require_relative 'translations'

# ImageRest is the "+N / Show All" tile that ends the short thumbnail strip.
#
# Ported from upstream's src/widgets/image_rest.rs and its template
# data/resources/blueprints/image-rest.blp: a FlowBoxChild holding one big
# square button whose label is the number of images the strip did not show.
# Clicking it pushes the "All Images" navigation page.
#
# I dropped the `+N` tile button's `icon-name`, because I am an idiot who
# decided a property I did not need today would never be needed. It is set
# again now.
# Upstream: data/resources/blueprints/image-rest.blp:9,
# `icon-name: "view-more-horizontal-symbolic"`.
#
class ImageRest < Gtk::FlowBoxChild
  include Translations

  TILE_SIZE = 150
  ICON_NAME = 'view-more-horizontal-symbolic'

  def initialize(count)
    super()
    @count = count
    self.focusable = false
    add_css_class('no-padding')
  end

  def build
    tap do |rest|
      rest.child = bin

      bin.child = button

      button.tap do |btn|
        btn.child = content_box
        btn.tooltip_text = tooltip

        content_box.tap do |box|
          box.append(count_label)
          box.append(show_all_label)
        end
      end
    end
  end

  def connect_clicked(&block)
    button.signal_connect('clicked') { block.call }
  end

  def bin = @bin ||= Adwaita::Bin.new

  def button
    @button ||= Gtk::Button.new.tap do |btn|
      btn.icon_name = ICON_NAME
      btn.hexpand = true
      btn.vexpand = true
      btn.width_request = TILE_SIZE
      btn.height_request = TILE_SIZE
      btn.add_css_class('image-container')
      btn.add_css_class('card')
      btn.add_css_class('image-rest-button')
    end
  end

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 0).tap do |box|
      box.halign = :center
      box.valign = :center
    end
  end

  # Upstream's msgid is literally `+{}` and the count is substituted into the
  # *translated* string (src/widgets/image_rest.rs:65), so the lookup has to
  # happen first: interpolating into the literal would build a key no
  # catalogue holds, and `format`/`%s` would build a different one again.
  def count_label
    @count_label ||= Gtk::Label.new(_('+{}').sub('{}', @count.to_s)).tap do |label|
      label.add_css_class('large_number')
    end
  end

  def show_all_label = @show_all_label ||= Gtk::Label.new(_('Show All'))

  private

    def tooltip = _('Show {} more images').sub('{}', @count.to_s)
end
