# frozen_string_literal: true

require 'adwaita'

# Color is an 8-bit-per-channel RGBA colour.
#
# Ported from upstream's src/color.rs. Its only job is to turn the colour the
# ColorDialogButton hands back into the `#rrggbbaa` string ImageMagick wants
# for its `-background` / `-fill` argument — note the channel order, which puts
# alpha last even though the struct lists it first.
#
class Color
  attr_reader :red, :green, :blue, :alpha

  def initialize(red:, green:, blue:, alpha: 255)
    @red = red
    @green = green
    @blue = blue
    @alpha = alpha
  end

  def self.rgb(red, green, blue) = new(
    red:   red,
    green: green,
    blue:  blue,
  )

  def self.rgba(red, green, blue, alpha) = new(
    red:   red,
    green: green,
    blue:  blue,
    alpha: alpha,
  )

  # Gdk hands the channels over as floats in 0.0..1.0; upstream truncates
  # rather than rounds (`(255f32 * color.red()) as u8`), so this does too.
  def self.from_rgba(rgba)
    rgba(
      (255.0 * rgba.red).to_i,
      (255.0 * rgba.green).to_i,
      (255.0 * rgba.blue).to_i,
      (255.0 * rgba.alpha).to_i,
    )
  end

  def to_rgba
    Gdk::RGBA.new(
      @red / 255.0,
      @green / 255.0,
      @blue / 255.0,
      @alpha / 255.0,
    )
  end

  def hex_string = format('#%<r>02x%<g>02x%<b>02x%<a>02x', r: @red, g: @green, b: @blue, a: @alpha)
  def to_s = hex_string

  def ==(other)
    other.is_a?(Color) &&
      other.red == @red &&
      other.green == @green &&
      other.blue == @blue &&
      other.alpha == @alpha
  end
  alias eql? ==

  def hash = [@red, @green, @blue, @alpha].hash
end
