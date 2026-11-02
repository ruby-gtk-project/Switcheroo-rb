# frozen_string_literal: true

require 'etc'
require 'fileutils'
require 'open3'

require 'adwaita'

require_relative 'color'
require_relative 'file_type'
require_relative 'temp_dir'
require_relative 'translations'

# Magick is the ImageMagick backend: the frame/dimension probe, the argument
# builder, and the job runner that spawns and supervises the child processes.
#
# Ported from upstream's src/magick.rs, plus the three argument enums upstream
# happens to declare in src/window.rs (ResizeFilter, StripType) and in
# src/magick.rs (ResizeArgument).
#
# Upstream reaches for tokio, async-channel, shared_child and futures to run
# the jobs. The port uses what Ruby and GLib already have: a bounded pool of
# Ruby threads runs the commands, each thread pushes events onto a Queue, and a
# GLib timeout on the main loop drains that queue, so every callback runs on
# the main thread and may touch widgets directly.
#
module Magick
  BINARY = 'magick'

  # Upstream's ZIP_BINARY_NAME, declared in src/main.rs.
  ZIP_BINARY = 'zip'

  # How often the main loop drains the worker queue, in milliseconds.
  DRAIN_INTERVAL = 50

  # `magick identify` prints one line per frame, and the first line carries
  # " WIDTHxHEIGHT " between the format and the page geometry.
  DIMENSIONS_PATTERN = / (\d+)x(\d+) /

  # ResizeFilter picks the interpolation ImageMagick uses when scaling.
  #
  # Ported from the ResizeFilter enum of upstream's src/window.rs: the default
  # adds no argument at all and lets ImageMagick choose, while "Pixel Art"
  # pins the Point filter so hard edges survive.
  class ResizeFilter
    DEFAULT = :default
    POINT = :point

    attr_reader :key

    def initialize(key)
      @key = key
    end

    def self.default = new(DEFAULT)
    def self.point = new(POINT)

    def self.from_index(index)
      if index.zero?
        default
      else
        point
      end
    end

    def display_string
      if @key == POINT
        'Point'
      end
    end

    def arguments
      display_string.then do |name|
        if name
          ['-filter', name]
        else
          []
        end
      end
    end
  end

  # StripType says whether to drop metadata.
  #
  # Ported from the StripType enum of upstream's src/window.rs. Stripping also
  # applies the orientation first, so a rotated photo does not come out
  # sideways once its Exif rotation is gone.
  class StripType
    NONE = :none
    STRIP_ALL = :strip_all

    attr_reader :key

    def initialize(key)
      @key = key
    end

    def self.none = new(NONE)
    def self.strip_all = new(STRIP_ALL)

    def self.from_active(active)
      if active
        strip_all
      else
        none
      end
    end

    def arguments
      if @key == STRIP_ALL
        ['-auto-orient', '-strip']
      else
        []
      end
    end
  end

  # ResizeArgument is either a percentage of the original size or an exact
  # pixel size.
  #
  # Ported from the ResizeArgument enum of upstream's src/magick.rs. The exact
  # form appends "!" so ImageMagick does not preserve the aspect ratio — the
  # link-axis toggle on the convert page has already decided what the two
  # numbers should be.
  class ResizeArgument
    PERCENTAGE = :percentage
    EXACT_PIXELS = :exact_pixels

    attr_reader :key, :width, :height

    def initialize(key:, width:, height:)
      @key = key
      @width = width
      @height = height
    end

    def self.percentage(width, height) = new(
      key:    PERCENTAGE,
      width:  width,
      height: height,
    )

    def self.exact_pixels(width, height) = new(
      key:    EXACT_PIXELS,
      width:  width,
      height: height,
    )

    def self.default = percentage(100, 100)

    def percentage? = @key == PERCENTAGE
    def exact_pixels? = @key == EXACT_PIXELS

    def arguments
      if percentage?
        ['-resize', "#{@width}%x#{@height}%"]
      else
        ['-resize', "#{@width}x#{@height}!"]
      end
    end
  end

  # ConvertJob is one `magick` invocation.
  #
  # Ported from the MagickConvertJob struct of upstream's src/magick.rs,
  # including the per-input-format special cases of its get_command(): an SVG
  # is rasterised through -size/-density instead of -resize, a PDF carries the
  # chosen pixel density, and an animation that stays an animation is coalesced
  # and had its transparency filled rather than being flattened frame by frame.
  class ConvertJob
    attr_reader :input_file, :output_file, :background, :quality, :filter, :strip, :resize_argument, :density

    def initialize(options)
      @input_file = options.fetch(:input_file)
      @output_file = options.fetch(:output_file)
      @background = options.fetch(:background)
      @quality = options.fetch(:quality)
      @filter = options.fetch(:filter)
      @strip = options.fetch(:strip)
      @resize_argument = options.fetch(:resize_argument)
      @density = options.fetch(:density, nil)
      @first_frame = options.fetch(:first_frame, false)
      @remove_alpha = options.fetch(:remove_alpha, false)
    end

    def first_frame? = @first_frame
    def remove_alpha? = @remove_alpha

    def with(overrides) = self.class.new(to_h.merge(overrides))

    def to_h
      {
        input_file:      @input_file,
        output_file:     @output_file,
        background:      @background,
        quality:         @quality,
        filter:          @filter,
        strip:           @strip,
        resize_argument: @resize_argument,
        density:         @density,
        first_frame:     @first_frame,
        remove_alpha:    @remove_alpha,
      }
    end

    def command
      if first_frame?
        flatten_command
      else
        coalesce_command
      end
    end

    # The extension of the input, with any "[frame]" suffix dropped.
    def input_extension = @input_file.split('.').last.to_s.split('[').first.to_s.downcase

    private

      def flatten_command
        [
          BINARY,
          *size_arguments,
          '-background', @background.hex_string,
          @input_file,
          '-flatten',
          *alpha_arguments,
          '-quality', @quality.to_s,
          *@filter.arguments,
          *resize_arguments,
          *@strip.arguments,
          @output_file,
        ]
      end

      def coalesce_command
        [
          BINARY,
          @input_file,
          '-coalesce',
          '-fill', @background.hex_string,
          '-opaque', 'none',
          '-quality', @quality.to_s,
          *@filter.arguments,
          *resize_arguments,
          @output_file,
        ]
      end

      def alpha_arguments
        if remove_alpha?
          ['-alpha', 'off']
        else
          []
        end
      end

      # An SVG has no pixels to resize: it is rasterised at the requested size
      # (or at a density scaled from the requested percentage) instead.
      def resize_arguments
        if input_extension == 'svg'
          []
        else
          @resize_argument.arguments
        end
      end

      def size_arguments
        if input_extension == 'svg'
          svg_size_arguments
        elsif input_extension == 'pdf'
          pdf_size_arguments
        else
          []
        end
      end

      def svg_size_arguments
        if @resize_argument.exact_pixels?
          ['-size', "#{@resize_argument.width}x#{@resize_argument.height}"]
        else
          ['-density', ((@resize_argument.width / 100.0) * 96.0).to_i.to_s]
        end
      end

      def pdf_size_arguments
        if @density
          ['-density', @density.to_s]
        else
          []
        end
      end
  end

  # Children tracks the child processes a run has spawned, so the cancel button
  # and the close-request guard can kill them.
  #
  # This is the port of upstream's `current_jobs: RefCell<Vec<Arc<SharedChild>>>`
  # together with its `is_canceled: Arc<AtomicBool>`.
  class Children
    def initialize
      @mutex = Mutex.new
      @pids = []
      @canceled = true
    end

    def canceled? = @mutex.synchronize { @canceled }

    def begin_run
      @mutex.synchronize do
        @canceled = false
        @pids = []
      end
    end

    def add(pid)
      @mutex.synchronize do
        if @canceled
          kill(pid)
        else
          @pids << pid
        end
      end
    end

    def remove(pid) = @mutex.synchronize { @pids.delete(pid) }

    # Upstream kills every tracked child and falls back to reaping it when the
    # kill fails, which is what a process that has already exited looks like.
    def cancel
      @mutex.synchronize do
        @canceled = true
        @pids.each { |pid| kill(pid) }
        @pids = []
      end
    end

    private

      def kill(pid)
        Process.kill('TERM', pid)
      rescue Errno::ESRCH, Errno::EPERM
        begin
          Process.wait(pid)
        rescue Errno::ECHILD, Errno::ESRCH
          nil
        end
      end
  end

  class << self
    include Translations

    # Upstream's count_frames(): `magick identify` prints one line per frame,
    # and no output at all means ImageMagick could not identify the file —
    # either it is corrupt or a delegate library is missing. That is reported
    # as nil so the window can show its "Could not Load Image" page rather
    # than carrying on and building jobs for a file that has no frames.
    def identify(path)
      capture_output([BINARY, 'identify', path]).then do |output|
        if output
          parse_identify(output)
        end
      end
    end

    # Probes every path on a background thread and hands the results back on
    # the main loop, in the same order. A nil entry means that path could not
    # be identified.
    def probe(paths, &callback)
      run_in_background(-> { paths.map { |path| identify(path) } }, &callback)
    end

    # Upstream's generate_job(): one ConvertJob per input, with the per-format
    # flags its match arms pick.
    def generate_job(options)
      input_type = options.fetch(:input_type)
      output_type = options.fetch(:output_type)
      base = options.fetch(:defaults).with(
        input_file:  options.fetch(:input_path),
        output_file: options.fetch(:output_path),
      )

      if input_type.extension == 'pdf'
        base.with(density: options.fetch(:dpi))
      elsif input_type.supports_animation? && output_type.supports_animation?
        base.with(first_frame: false)
      else
        base.with(
          first_frame:  true,
          remove_alpha: !input_type.supports_alpha? && output_type.supports_alpha?,
        )
      end
    end

    # Runs groups of commands: the commands within a group run in order (that
    # is one input file's frames), the groups themselves run in parallel over a
    # pool sized to the machine. `on_progress` fires once per finished command,
    # `on_failure` on the first non-zero exit with that command's stderr, and
    # `on_success` once every command has finished.
    def run_jobs(options)
      groups = options.fetch(:groups)
      children = options.fetch(:children)
      queue = Queue.new
      total = groups.sum(&:length)

      children.begin_run
      spawn_pool(groups, children, queue)

      drain(
        queue:       queue,
        total:       total,
        children:    children,
        on_progress: options.fetch(:on_progress),
        on_failure:  options.fetch(:on_failure),
        on_success:  options.fetch(:on_success),
      )
    end

    # Upstream's move_output(): a single image is moved, a multi-page PDF is
    # merged by `magick`, a directory output moves every file into place, and a
    # ZIP output shells out to `zip -jFSm0`.
    def collect(options)
      run_in_background(-> { collect_now(options) }, &options.fetch(:on_finished))
    end

    # Moves a file, falling back to copy + delete when source and destination
    # live on different filesystems. Upstream's move_file() does the same,
    # because std::fs::rename fails with EXDEV across mounts.
    def move_file(from, to)
      File.rename(from, to)
    rescue SystemCallError
      FileUtils.cp(from, to)
      File.unlink(from)
    end

    private

      def parse_identify(output)
        output.lines.then do |lines|
          if lines.empty?
            nil
          else
            [lines.length, parse_dimensions(lines.first)]
          end
        end
      end

      def parse_dimensions(first_line)
        DIMENSIONS_PATTERN.match(first_line).then do |found|
          if found
            [found[1].to_i, found[2].to_i]
          end
        end
      end

      # Upstream looks only at what `magick identify` printed, not at how it
      # exited: a file it managed to describe at all is usable, however many
      # warnings it raised doing so.
      def capture_output(argv)
        Open3.capture2(*argv).first
      rescue SystemCallError
        nil
      end

      # Runs `work` on a Ruby thread and delivers its value to `callback` on
      # the GLib main loop, which is where every widget touch has to happen.
      def run_in_background(work, &callback)
        Queue.new.tap do |queue|
          Thread.new do
            queue.push(work.call)
          end

          GLib::Timeout.add(DRAIN_INTERVAL) do
            if queue.empty?
              true
            else
              callback.call(queue.pop)
              false
            end
          end
        end
      end

      def spawn_pool(groups, children, queue)
        pending = Queue.new
        groups.each { |group| pending.push(group) }
        [Etc.nprocessors, groups.length].min.then do |workers|
          workers.times { Thread.new { work_off(pending, children, queue) } }
        end
      end

      def work_off(pending, children, queue)
        until pending.empty?
          pop_pending(pending).then do |group|
            if group
              run_group(group, children, queue)
            end
          end
        end
      end

      def pop_pending(pending)
        pending.pop(true)
      rescue ThreadError
        nil
      end

      def run_group(group, children, queue)
        group.each do |command|
          if children.canceled?
            break
          end

          error = run_command(command, children)
          if error
            queue.push([:failure, error])
            break
          end

          queue.push([:progress, nil])
        end
      end

      # Spawns one command, registers its pid so a cancel can kill it, and
      # returns its stderr when it fails. Upstream's wait_for_child() reports
      # the same thing.
      def run_command(command, children)
        Open3.popen3(*command) do |stdin, stdout, stderr, wait_thread|
          stdin.close
          children.add(wait_thread.pid)
          [stdout.read, stderr.read].join.then do |output|
            children.remove(wait_thread.pid)
            if wait_thread.value.success?
              nil
            else
              output
            end
          end
        end
      rescue SystemCallError
        # Upstream's wait_for_child(): a spawn that never produced a child has
        # no stderr to report, so the one translated sentence stands in for it
        # (src/magick.rs:301).
        _('Unknown IO error happened')
      end

      def drain(options)
        queue = options.fetch(:queue)
        total = options.fetch(:total)
        children = options.fetch(:children)
        done = 0

        GLib::Timeout.add(DRAIN_INTERVAL) do
          if children.canceled?
            false
          elsif queue.empty?
            true
          else
            queue.pop.then do |kind, payload|
              if kind == :failure
                options.fetch(:on_failure).call(payload)
                false
              else
                done += 1
                options.fetch(:on_progress).call(done, total)
                if done == total
                  options.fetch(:on_success).call
                  false
                else
                  true
                end
              end
            end
          end
        end
      end

      def collect_now(options)
        output_type = options.fetch(:output_type)
        path = options.fetch(:path)
        files = options.fetch(:files)
        children = options.fetch(:children)

        if output_type.file? && output_type.file_type.extension == 'pdf' && files.length > 1
          run_command([BINARY, *files, path], children)
        elsif output_type.file?
          move_one(files.first, path)
        elsif output_type.directory?
          move_all(files, path)
        else
          run_command([ZIP_BINARY, '-jFSm0', path, *files], children)
        end
      end

      def move_one(file, path)
        move_file(file, path)
        nil
      rescue SystemCallError => e
        "move: #{e.message}"
      end

      def move_all(files, path)
        files.each { |file| move_file(file, File.join(path, File.basename(file))) }
        nil
      rescue SystemCallError => e
        "move: #{e.message}"
      end
  end
end
