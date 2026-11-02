# frozen_string_literal: true

require "support/gtk_session"

GtkSession.load!

# The window's state machine, driven for real. Every behaviour below is one the
# .reports/component-parity.md verdicts were read off the source for and could
# not be confirmed, because nothing ran them.
RSpec.describe AppWindow do
  subject(:window) { described_class.new(GtkSession.application, settings) }

  let(:settings) do
    Settings.new(
      settings: Gio::Settings.new(
        schema:  Settings.new.send(:schema),
        backend: Gio.memory_settings_backend_new,
        path:    Settings::SCHEMA_PATH,
      ),
    )
  end

  def input(name, extension: "png", frames: 1)
    InputFile.new(
      path: "/tmp/#{name}.#{extension}",
      kind: FileType.from_string(extension),
    ).tap { |file| file.frame_count = frames }
  end

  def load(*files)
    window.instance_variable_set(:@files, files)
    window.instance_variable_set(:@removed, [])
  end

  describe "#unique_stems" do
    it "turns two files called cover into cover and cover_1" do
      load(input("cover"), input("cover", extension: "jpg"))

      expect(window.send(:unique_stems).map(&:last)).to eq(%w[cover cover_1])
    end

    it "keeps counting when the disambiguated name is also taken" do
      load(input("cover"), input("cover", extension: "jpg"), input("cover", extension: "webp"))

      expect(window.send(:unique_stems).map(&:last)).to eq(%w[cover cover_1 cover_2])
    end

    it "leaves distinct stems alone" do
      load(input("a"), input("b"))

      expect(window.send(:unique_stems).map(&:last)).to eq(%w[a b])
    end

    it "ignores the files the user removed" do
      load(input("cover"), input("cover", extension: "jpg"))
      window.send(:remove_file, 0)

      expect(window.send(:unique_stems).map(&:last)).to eq(%w[cover])
    end
  end

  describe "#frames_for" do
    let(:png) { FileType.from_string("png") }
    let(:gif) { FileType.from_string("gif") }

    it "reads an ordinary single-frame file as frame zero" do
      expect(
        window.send(
          :frames_for,
          input("a"),
          "a",
          png,
        ),
      )
        .to eq([["/tmp/a.png[0]", "a.png"]])
    end

    it "expands a PDF one input per page" do
      file = input("doc", extension: "pdf", frames: 3)

      expect(
        window.send(
          :frames_for,
          file,
          "doc",
          png,
        ).map(&:last),
      )
        .to eq(["doc[0].png", "doc[1].png", "doc[2].png"])
    end

    it "passes an animation whole when the output can animate" do
      file = input("loop", extension: "gif", frames: 4)

      expect(
        window.send(
          :frames_for,
          file,
          "loop",
          gif,
        ),
      )
        .to eq([["/tmp/loop.gif", "loop.gif"]])
    end

    it "expands an animation per frame when the output cannot animate" do
      file = input("loop", extension: "gif", frames: 4)

      expect(
        window.send(
          :frames_for,
          file,
          "loop",
          png,
        ).length,
      ).to eq(4)
    end

    it "reads a multi-layer file that cannot animate as frame zero only" do
      file = input("layers", extension: "tiff", frames: 12)

      expect(
        window.send(
          :frames_for,
          file,
          "layers",
          png,
        ),
      )
        .to eq([["/tmp/layers.tiff[0]", "layers.png"]])
    end
  end

  describe "#remove_file" do
    before { window.build }

    it "keeps the store intact so later indices still name the right file" do
      load(input("a"), input("b"), input("c"))
      window.send(:remove_file, 1)
      window.send(:remove_file, 2)

      expect(window.send(:active_files).map(&:stem)).to eq(%w[a])
    end

    it "counts only the files that are still there" do
      load(input("a"), input("b"), input("c"))
      window.send(:remove_file, 0)

      expect(window.send(:files_count)).to eq(2)
    end

    it "clears the window when the last thumbnail goes" do
      load(input("a"))
      window.send(:remove_file, 0)

      expect(window.instance_variable_get(:@files)).to be_empty
    end
  end

  describe "#construct_short_thumbnail" do
    before { window.build }

    def tiles
      container = window.convert_page.image_container
      count = 0
      child = container.first_child
      while child
        count += 1
        child = child.next_sibling
      end
      count
    end

    it "shows every file when they all fit" do
      load(*Array.new(4) { |i| input("f#{i}") })
      window.send(:construct_short_thumbnail)

      expect(tiles).to eq(4)
    end

    it "fills all six slots when exactly six files are loaded" do
      load(*Array.new(6) { |i| input("f#{i}") })
      window.send(:construct_short_thumbnail)

      expect(tiles).to eq(6)
    end

    it "gives the sixth slot up to the +N tile when a seventh file remains" do
      load(*Array.new(7) { |i| input("f#{i}") })
      window.send(:construct_short_thumbnail)

      # Five thumbnails plus the "+N" tile.
      expect(tiles).to eq(6)
    end

    it "keeps an empty child in the place of a removed file" do
      load(*Array.new(3) { |i| input("f#{i}") })
      window.send(:remove_file, 0)

      expect(tiles).to eq(3)
    end
  end

  describe "the flow box width switch" do
    before { window.build }

    it "lets one or two images fill the width" do
      load(input("a"), input("b"))
      window.send(:apply_container_width)

      expect(window.convert_page.image_container.max_children_per_line).to eq(2)
      expect(window.convert_page.image_container.hexpand?).to be(true)
    end

    it "puts three or more into a three-wide grid that does not expand" do
      load(*Array.new(5) { |i| input("f#{i}") })
      window.send(:apply_container_width)

      expect(window.convert_page.image_container.max_children_per_line).to eq(3)
      expect(window.convert_page.image_container.hexpand?).to be(false)
    end
  end
end
