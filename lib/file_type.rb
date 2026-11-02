# frozen_string_literal: true

# FileType, CompressionType and OutputType are the format model.
#
# Ported from upstream's src/filetypes.rs, which declares them as three glib
# enums. Upstream spells the capability questions as `matches!` arms over the
# enum (`is_lossy`, `supports_alpha`, …); here each capability is a frozen list
# of keys and the predicate is a membership test, which keeps the table in one
# readable block instead of fifteen match arms.
#
# These predicates drive nearly every conditional row on the convert page: the
# quality scale appears only for lossy outputs, the background colour row only
# when an input carries alpha, the metadata switch only when an input carries
# metadata, and so on.
#
class FileType
  # Upstream's FileType::iterator()/input_formats(), in upstream's order.
  KEYS = %i[png jpg jpeg webp svg heif heic bmp avif jxl tiff pdf gif ico dds].freeze

  # Upstream's output_formats(), which is alphabetical rather than declaration
  # order — the export-format combo row shows it exactly like this.
  OUTPUT_KEYS = %i[avif bmp dds gif heic heif ico jpg jxl pdf png tiff webp].freeze

  ANIMATION_KEYS = %i[webp gif heic heif].freeze
  LOSSY_KEYS = %i[jpg jpeg webp heif heic avif jxl tiff pdf dds].freeze
  ALPHA_KEYS = %i[png webp svg heif heic avif jxl pdf ico gif].freeze
  NO_METADATA_KEYS = %i[ico dds].freeze
  NO_PIXBUF_KEYS = %i[pdf dds ico].freeze

  MIMES = {
    png:  'image/png',
    jpg:  'image/jpeg',
    jpeg: 'image/jpeg',
    webp: 'image/webp',
    svg:  'image/svg+xml',
    heif: 'image/heif',
    heic: 'image/heic',
    bmp:  'image/bmp',
    avif: 'image/avif',
    jxl:  'image/jxl',
    tiff: 'image/tiff',
    pdf:  'application/pdf',
    gif:  'image/gif',
    ico:  'image/x-icon',
    dds:  'image/vnd-ms.dds',
  }.freeze

  # Upstream's from_mimetype(): both image/jpeg and the non-standard image/jpg
  # land on Jpg, so the mime table above cannot simply be inverted.
  MIME_OVERRIDES = {
    'image/jpeg' => :jpg,
    'image/jpg'  => :jpg,
  }.freeze

  # Upstream's from_string(): "jpeg" is accepted but normalises to Jpg.
  EXTENSION_OVERRIDES = {
    'jpeg' => :jpg,
  }.freeze

  attr_reader :key

  def initialize(key)
    @key = key
  end

  def extension = @key.to_s
  def display_string = extension.upcase
  def mime = MIMES.fetch(@key)
  def to_s = display_string

  def input? = KEYS.include?(@key)
  def output? = OUTPUT_KEYS.include?(@key)
  def supports_animation? = ANIMATION_KEYS.include?(@key)
  def lossy? = LOSSY_KEYS.include?(@key)
  def supports_alpha? = ALPHA_KEYS.include?(@key)
  def supports_metadata? = !NO_METADATA_KEYS.include?(@key)
  def supports_pixbuf? = !NO_PIXBUF_KEYS.include?(@key)

  def ==(other) = other.is_a?(FileType) && other.key == @key
  alias eql? ==
  def hash = @key.hash

  ALL = KEYS.to_h { |key| [key, new(key)] }.freeze

  class << self
    # Every format, in upstream's declaration order.
    def all = KEYS.map { |key| ALL.fetch(key) }

    # Upstream's input_formats(): the same list, used to build the "Images"
    # filter of the open dialog.
    def input_formats = all

    # Upstream's output_formats(): what the export-format combo row offers.
    def output_formats = OUTPUT_KEYS.map { |key| ALL.fetch(key) }

    def from_string(extension)
      extension.to_s.downcase.then do |text|
        EXTENSION_OVERRIDES.fetch(text, text.to_sym).then do |key|
          ALL[key]
        end
      end
    end

    def from_mimetype(mimetype)
      MIME_OVERRIDES[mimetype].then do |override|
        if override
          ALL.fetch(override)
        else
          ALL[MIMES.key(mimetype)]
        end
      end
    end
  end
end

# CompressionType is how several output files get bundled together.
#
# Ported from the CompressionType enum of upstream's src/filetypes.rs. Writing
# a plain directory is only offered outside a sandbox, where the app can see
# the chosen folder; upstream's possible_output(sandboxed) says the same.
#
class CompressionType
  KEYS = %i[zip directory].freeze

  MIMES = {
    zip:       'application/zip',
    directory: 'inode/directory',
  }.freeze

  DISPLAY_STRINGS = {
    zip:       'ZIP',
    directory: 'Directory',
  }.freeze

  attr_reader :key

  def initialize(key)
    @key = key
  end

  def extension = @key.to_s
  def mime = MIMES.fetch(@key)
  def display_string = DISPLAY_STRINGS.fetch(@key)
  def to_s = display_string
  def compression? = @key == :zip

  def ==(other) = other.is_a?(CompressionType) && other.key == @key
  alias eql? ==
  def hash = @key.hash

  ALL = KEYS.to_h { |key| [key, new(key)] }.freeze

  ZIP = ALL.fetch(:zip)
  DIRECTORY = ALL.fetch(:directory)

  class << self
    def all = KEYS.map { |key| ALL.fetch(key) }
    def compression_formats = [ZIP]
    def from_string(extension) = ALL[extension.to_s.downcase.to_sym]

    # Inside a sandbox only the ZIP output is reachable.
    def possible_output(sandboxed)
      if sandboxed
        [ZIP]
      else
        all
      end
    end
  end
end

# OutputType is what the save dialog is asked to produce: either a single image
# file of some FileType, or a bundle of several under a CompressionType.
#
# Ported from the OutputType enum of upstream's src/filetypes.rs.
#
class OutputType
  attr_reader :file_type, :compression_type

  def initialize(file_type: nil, compression_type: nil)
    @file_type = file_type
    @compression_type = compression_type
  end

  def self.file(file_type) = new(file_type: file_type)
  def self.compression(compression_type) = new(compression_type: compression_type)

  def self.from_string(extension)
    CompressionType.from_string(extension).then do |compression_type|
      if compression_type
        compression(compression_type)
      else
        FileType.from_string(extension).then do |file_type|
          if file_type
            file(file_type)
          end
        end
      end
    end
  end

  def file? = !@file_type.nil?
  def compression? = !@compression_type.nil?
  def directory? = @compression_type == CompressionType::DIRECTORY
  def kind = @file_type || @compression_type
  def mime = kind.mime
  def extension = kind.extension

  def ==(other)
    other.is_a?(OutputType) &&
      other.file_type == @file_type &&
      other.compression_type == @compression_type
  end
  alias eql? ==

  def hash = [@file_type, @compression_type].hash
end
