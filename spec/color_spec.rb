# frozen_string_literal: true

require "support/gtk_session"

GtkSession.load!

# Upstream's src/color.rs: the only job is the `#rrggbbaa` string ImageMagick
# wants, with alpha last even though the struct lists it first, and channels
# truncated rather than rounded.
RSpec.describe Color do
  it "writes alpha last" do
    expect(
      described_class.rgba(
        0x11,
        0x22,
        0x33,
        0x44,
      ).hex_string,
    ).to eq("#11223344")
  end

  it "pads single-digit channels" do
    expect(
      described_class.rgba(
        1,
        2,
        3,
        4,
      ).hex_string,
    ).to eq("#01020304")
  end

  it "round-trips through Gdk::RGBA" do
    color = described_class.rgba(
      0x80,
      0x00,
      0xff,
      0xcc,
    )

    expect(described_class.from_rgba(color.to_rgba)).to eq(color)
  end

  it "truncates the float channels rather than rounding them" do
    rgba = Gdk::RGBA.new(
      0.5,
      0.5,
      0.5,
      1.0,
    )

    # 255.0 * 0.5 is 127.5, which upstream's `as u8` cast takes to 127.
    expect(described_class.from_rgba(rgba).red).to eq(127)
  end

  it "reads the transparent default the convert page starts on as fully clear" do
    rgba = Gdk::RGBA.new(
      0.0,
      0.0,
      0.0,
      0.0000001,
    )

    expect(described_class.from_rgba(rgba).hex_string).to eq("#00000000")
  end
end
