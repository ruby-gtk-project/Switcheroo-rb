# frozen_string_literal: true

require 'fileutils'
require 'securerandom'

require_relative 'file_type'

# TempDir is the scratch directory a conversion run writes its output into
# before the results are moved, zipped or merged into the destination.
#
# Ported from upstream's src/temp.rs. Upstream leans on the `tempfile` crate
# and on `ashpd::is_sandboxed()`; the sandbox check here looks for the
# /.flatpak-info file the Flatpak runtime always mounts, because inside a
# sandbox /tmp is not shared with the portal that later opens the result, so
# the directory has to live under XDG_CACHE_HOME/tmp instead.
#
# Upstream's `clean_dir` unwraps the removal, i.e. a failure to clean up is a
# panic. Here it is `FileUtils.rm_rf`, which is already tolerant.
#
class TempDir
  SANDBOX_MARKER = '/.flatpak-info'

  attr_reader :path

  def initialize(path)
    @path = path
  end

  class << self
    # Upstream's create_temporary_dir().
    def create
      FileUtils.mkdir_p(parent).then do
        File.join(parent, "switcheroo-#{SecureRandom.hex(8)}").then do |path|
          FileUtils.mkdir_p(path)
          new(path)
        end
      end
    end

    def sandboxed? = File.exist?(SANDBOX_MARKER)

    # Upstream's clean_dir().
    def clean(path) = FileUtils.rm_rf(path)

    def parent
      if sandboxed?
        File.join(ENV.fetch('XDG_CACHE_HOME', File.expand_path('~/.cache')), 'tmp')
      else
        ENV.fetch('TMPDIR', '/tmp')
      end
    end
  end

  # Upstream's get_temp_file_path(dir, identifier).
  def file_path(job_file) = File.join(@path, job_file.filename)

  def clean = self.class.clean(@path)
end

# JobFile names one file a conversion job writes.
#
# Ported from the JobFile struct of upstream's src/magick.rs: an id from a
# process-wide counter, an optional desired name, and the extension to fall
# back on. The desired name is what the window builds from the input file's
# stem, so "holiday.png" converted to JPG lands on "holiday.jpg"; without one
# the file gets the TEMPORARY_SWITCHEROO_<n> name, which is what the clipboard
# path and the probe path use.
#
class JobFile
  PASTED_IMAGE_NAME = 'Pasted Image'

  @count = 0
  @mutex = Mutex.new

  class << self
    def next_id = @mutex.synchronize { @count += 1 }

    # Upstream's JobFile::from_clipboard().
    def from_clipboard
      new(
        file_type:    FileType.from_string('png'),
        desired_name: "#{PASTED_IMAGE_NAME}.png",
      )
    end
  end

  attr_reader :id, :desired_name, :file_type

  def initialize(file_type:, desired_name: nil)
    @id = self.class.next_id
    @file_type = file_type
    @desired_name = desired_name
  end

  def filename
    if @desired_name
      @desired_name
    else
      "TEMPORARY_SWITCHEROO_#{@id}.#{@file_type.extension}"
    end
  end
end
