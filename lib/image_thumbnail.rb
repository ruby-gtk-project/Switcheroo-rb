# frozen_string_literal: true

require 'adwaita'

# ImageThumbnail is one loaded image as it appears in the two flow boxes.
#
# Ported from upstream's src/widgets/image_thumbnail.rs and its template
# data/resources/blueprints/image-thumbnail.blp: a rounded card holding either
# the image itself (a Gtk.Picture, content-fit cover) or, when no texture could
# be loaded, a generic image icon, with the format-and-size caption on a tinted
# strip underneath and a circular OSD trash button floating in the top right.
#
# Upstream's imp overrides measure() to answer 150×150 for the horizontal
# orientation whenever the file's dimensions are known, and size_allocate() to
# hand the whole allocation to its root box. The Ruby bindings cannot override
# a widget's vfuncs, so the same clamp is expressed as a fixed size request on
# the card with expansion switched off, which is what upstream's measure was
# there to produce: every tile is exactly THUMBNAIL_SIZE wide whatever the
# image's aspect ratio.
#
class ImageThumbnail < Adwaita::Bin
  THUMBNAIL_SIZE = 150
  FALLBACK_ICON = 'image-symbolic'
  REMOVE_ICON = 'user-trash-symbolic'
  REMOVE_TOOLTIP = 'Remove image'

  def initialize(texture:, caption:, dimensions: nil)
    super()
    @texture = texture
    @caption = caption
    @dimensions = dimensions
    add_css_class('card')
    add_css_class('image-thumbnail')
    self.overflow = :hidden
    clamp_to_thumbnail_size
  end

  def build
    tap do |thumbnail|
      thumbnail.child = root

      root.tap do |r|
        r.append(child_box)

        child_box.tap do |cb|
          cb.append(overlay)

          overlay.tap do |ov|
            ov.child = content_box
            ov.add_overlay(remove_button)

            content_box.tap do |box|
              box.append(image_box)
              box.append(caption_bin)

              image_box.tap do |ib|
                ib.append(picture)
                ib.append(image)
              end

              caption_bin.tap do |bin|
                bin.child = caption_box

                caption_box.append(caption_label)
              end
            end
          end
        end
      end

      # Upstream's "image" property setter: a texture shows the Picture and
      # hides the Image, and no texture does the opposite.
      picture.visible = !@texture.nil?
      image.visible = @texture.nil?
    end
  end

  def connect_remove_clicked(&block)
    remove_button.signal_connect('clicked') { block.call }
  end

  def root
    @root ||= Gtk::Box.new(:horizontal, 0).tap do |box|
      box.add_css_class('card-content')
    end
  end

  def child_box
    @child_box ||= Gtk::Box.new(:horizontal, 0).tap do |box|
      box.add_css_class('image-container')
    end
  end

  def overlay = @overlay ||= Gtk::Overlay.new

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 0).tap do |box|
      box.hexpand = true
      box.vexpand = true
    end
  end

  def image_box = @image_box ||= Gtk::Box.new(:horizontal, 0)

  def picture
    @picture ||= Gtk::Picture.new.tap do |pic|
      pic.paintable = @texture
      pic.content_fit = :cover
      pic.width_request = THUMBNAIL_SIZE
      pic.height_request = THUMBNAIL_SIZE
      pic.hexpand = true
      pic.vexpand = true
    end
  end

  def image
    @image ||= Gtk::Image.new.tap do |img|
      img.icon_name = FALLBACK_ICON
      img.icon_size = :large
      img.width_request = THUMBNAIL_SIZE
      img.height_request = THUMBNAIL_SIZE
      img.hexpand = true
      img.vexpand = true
    end
  end

  def caption_bin
    @caption_bin ||= Adwaita::Bin.new.tap do |bin|
      bin.hexpand = true
      bin.vexpand = false
      bin.overflow = :hidden
      bin.add_css_class('image-caption')
      bin.add_css_class('caption')
    end
  end

  def caption_box
    @caption_box ||= Gtk::Box.new(:horizontal, 0).tap do |box|
      box.halign = :center
      box.valign = :center
    end
  end

  def caption_label = @caption_label ||= Gtk::Label.new(@caption)

  def remove_button
    @remove_button ||= Gtk::Button.new.tap do |btn|
      btn.icon_name = REMOVE_ICON
      btn.tooltip_text = REMOVE_TOOLTIP
      btn.valign = :start
      btn.halign = :end
      btn.add_css_class('circular')
      btn.add_css_class('image-remove')
      btn.add_css_class('osd')
    end
  end

  private

    # Upstream's measure() override: a file whose dimensions are known is
    # reported as exactly 150 wide, so a wide photo and a tall one take the
    # same room in the flow box.
    def clamp_to_thumbnail_size
      if @dimensions
        set_size_request(THUMBNAIL_SIZE, THUMBNAIL_SIZE)
        self.hexpand = false
        self.vexpand = false
      end
    end
end
