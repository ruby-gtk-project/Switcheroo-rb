# frozen_string_literal: true

require 'adwaita'

# ImageRest is the "+N / Show All" tile that ends the short thumbnail strip.
#
# Ported from upstream's src/widgets/image_rest.rs and its template
# data/resources/blueprints/image-rest.blp: a FlowBoxChild holding one big
# square button whose label is the number of images the strip did not show.
# Clicking it pushes the "All Images" navigation page.
#
# The blueprint gives the button both an icon name and an explicit child box;
# the child is what GTK actually shows, so only the child is built here.
#
class ImageRest < Gtk::FlowBoxChild
  TILE_SIZE = 150
  SHOW_ALL_LABEL = 'Show All'

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

  def count_label
    @count_label ||= Gtk::Label.new("+#{@count}").tap do |label|
      label.add_css_class('large_number')
    end
  end

  def show_all_label = @show_all_label ||= Gtk::Label.new(SHOW_ALL_LABEL)

  private

    def tooltip = "Show #{@count} more images"
end
