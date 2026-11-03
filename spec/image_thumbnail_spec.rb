# frozen_string_literal: true

require "support/gtk_session"

GtkSession.load!

# The one measurement upstream's `measure()` vfunc exists to produce.
#
# `src/widgets/image_thumbnail.rs:120-131` overrides WidgetImpl::measure to
# return min = nat = 150 on the horizontal orientation whenever the file's
# dimensions are known, and to pass the vertical measure straight through. A
# Ruby subclass cannot carry that vfunc — FINDINGS.md §7 shows GTK answering
# with GtkWidget's own zero measurement under all three override spellings —
# so the port pins the width with `set_size_request(150, -1)` instead and
# leaves the natural width to the subtree.
#
# That is only a difference where the subtree's natural width exceeds 150,
# which means where the caption is wider than the picture. The examples below
# measure the real widget for every caption `InputFile#caption` can produce:
# `<FORMAT> · <W>×<H>`, where the format is an upper-cased extension of at
# most four characters and the dimensions are at most five digits each. If one
# of them ever reports more than 150, upstream's clamp has started to matter
# and the gap is real; today none does.
RSpec.describe ImageThumbnail do
  # measure() needs the widget in a realized hierarchy, so each example hangs
  # it off a window that is presented and then emptied again.
  def measure(thumbnail, orientation)
    window = Gtk::Window.new
    window.child = thumbnail
    window.present
    thumbnail.measure(orientation, -1).first(2)
  ensure
    window.child = nil
    window.destroy
  end

  def thumbnail(caption, dimensions: [1920, 1080])
    described_class.new(texture: nil, caption: caption, dimensions: dimensions).tap(&:build)
  end

  # The widest caption the app can build: the longest display string any
  # FileType has, against the largest dimensions ImageMagick will report.
  def widest_caption
    FileType::KEYS
      .map { |key| FileType.new(key).display_string }
      .max_by(&:length)
      .then { |format| "#{format} · 65535×65535" }
  end

  describe "the horizontal measurement" do
    it "is exactly 150 wide, minimum and natural, for a typical caption" do
      expect(measure(thumbnail("PNG · 1920×1080"), :horizontal)).to eq([150, 150])
    end

    it "is still exactly 150 wide for the widest caption the app can build" do
      expect(measure(thumbnail(widest_caption), :horizontal)).to eq([150, 150])
    end

    it "is exactly 150 wide for every format's caption at five-digit dimensions" do
      measurements = FileType::KEYS.to_h do |key|
        caption = "#{FileType.new(key).display_string} · 65535×65535"
        [caption, measure(thumbnail(caption), :horizontal)]
      end

      expect(measurements.values.uniq).to eq([[150, 150]])
    end
  end

  describe "the vertical measurement" do
    # The clamp upstream applies is horizontal only. A previous round pinned
    # the height at 150 as well, which squeezed the caption strip against the
    # bottom of every image; the tile is taller than the picture because the
    # caption strip sits under it.
    it "is taller than the picture, not clamped to 150" do
      expect(measure(thumbnail("PNG · 1920×1080"), :vertical).first).to be > 150
    end

    it "reports the same minimum and natural height" do
      measure(thumbnail("PNG · 1920×1080"), :vertical).then do |(minimum, natural)|
        expect(minimum).to eq(natural)
      end
    end
  end
end
