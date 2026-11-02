# frozen_string_literal: true

require 'adwaita'

require_relative 'file_type'

# InputFile is one image the user has loaded.
#
# Ported from upstream's src/input_file.rs, where it is a GObject with "path",
# "kind" and "is-behind-sandbox" properties plus plain cells for the texture,
# the frame count and the dimensions. Nothing in the app binds to those
# properties — the window reads them directly — so here it is a plain Ruby
# object, and the gio::ListStore upstream keeps them in is a plain Array in
# AppWindow. The texture, frame count and dimensions are filled in after
# construction: `magick identify` supplies the frame count and dimensions, and
# a Gdk::Texture is loaded for the first ten thumbnail-able files.
#
# `new_for_file` returns nil when the file's content type is not an image
# Switcheroo understands, which is how upstream's Option<InputFile> signals an
# unsupported filetype.
#
class InputFile
  # Upstream treats anything outside /home as reached through the portal.
  SANDBOX_EXEMPT_PREFIX = '/home'

  attr_reader :path, :kind
  attr_accessor :texture, :frame_count, :width, :height

  def initialize(path:, kind:, behind_sandbox: true)
    @path = path
    @kind = kind
    @behind_sandbox = behind_sandbox
    @frame_count = 1
  end

  class << self
    # Upstream's InputFile::new(&gio::File).
    def new_for_file(file)
      file.path.then do |path|
        if path
          new_for_path(path)
        end
      end
    end

    def new_for_path(path)
      content_type_of(path).then do |mimetype|
        FileType.from_mimetype(mimetype).then do |kind|
          if kind
            new(
              path:           path,
              kind:           kind,
              behind_sandbox: !path.start_with?(SANDBOX_EXEMPT_PREFIX),
            )
          end
        end
      end
    end

    private

      def content_type_of(path)
        Gio::File.open(path: path)
                 .query_info(
                   Gio::FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE,
                   :none,
                 )
                 .content_type
      rescue GLib::Error
        nil
      end
  end

  def behind_sandbox? = @behind_sandbox
  def exists? = File.exist?(@path)
  def stem = File.basename(@path, '.*')

  def dimensions
    if @width && @height
      [@width, @height]
    end
  end

  def area
    dimensions.then do |dims|
      if dims
        dims[0] * dims[1]
      end
    end
  end

  # The caption upstream builds for each thumbnail: "PNG · 1920×1080", or just
  # the format when `magick identify` could not report a size.
  def caption
    dimensions.then do |dims|
      if dims
        "#{@kind.display_string} · #{dims[0]}×#{dims[1]}"
      else
        @kind.display_string
      end
    end
  end
end
