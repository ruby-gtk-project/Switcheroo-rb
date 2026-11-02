# frozen_string_literal: true

require "support/gtk_session"

GtkSession.load!

# The convert page's conditional rows and its two linked resize axes, driven
# for real. Which rows are visible is derived entirely from the formats in
# play, and the two percentage entries mirror each other only while the chain
# is closed.
RSpec.describe ConvertPage do
  subject(:page) { described_class.new(settings) }

  let(:settings) do
    Settings.new(
      settings: Gio::Settings.new(
        schema:  Settings.new.send(:schema),
        backend: Gio.memory_settings_backend_new,
        path:    Settings::SCHEMA_PATH,
      ),
    )
  end

  def input(extension, frames: 1)
    InputFile.new(
      path: "/tmp/image.#{extension}",
      kind: FileType.from_string(extension),
    ).tap { |file| file.frame_count = frames }
  end

  def select_output(extension)
    page.output_filetype.selected = FileType.output_formats.index(FileType.from_string(extension))
  end

  before { page.build }

  describe "the conditional rows" do
    it "shows the quality row only for a lossy output" do
      page.update(files: [input("png")], image_width: 10, image_height: 10)
      select_output("jpg")

      expect(page.quality_row.visible?).to be(true)
    end

    it "hides the quality row for a lossless output" do
      page.update(files: [input("png")], image_width: 10, image_height: 10)
      select_output("png")

      expect(page.quality_row.visible?).to be(false)
    end

    it "shows the DPI row only when a PDF is loaded" do
      page.update(files: [input("png")], image_width: 10, image_height: 10)
      select_output("png")
      expect(page.dpi_row.visible?).to be(false)

      page.update(files: [input("pdf", frames: 2)], image_width: 10, image_height: 10)
      select_output("png")
      expect(page.dpi_row.visible?).to be(true)
    end

    it "hides the resize-algorithm row when every input is an SVG" do
      page.update(files: [input("svg")], image_width: 10, image_height: 10)
      select_output("png")

      expect(page.resize_filter_row.visible?).to be(false)
    end

    it "shows the resize-algorithm row as soon as one input is not an SVG" do
      page.update(files: [input("svg"), input("png")], image_width: 10, image_height: 10)
      select_output("png")

      expect(page.resize_filter_row.visible?).to be(true)
    end

    it "hides the metadata row when no input can carry metadata" do
      page.update(files: [input("ico")], image_width: 10, image_height: 10)
      select_output("png")

      expect(page.strip_row.visible?).to be(false)
    end

    it "shows the background-colour row when an input carries alpha" do
      page.update(files: [input("png")], image_width: 10, image_height: 10)
      select_output("jpg")

      expect(page.bgcolor_row.visible?).to be(true)
    end

    it "offers no bundling for a single single-frame file" do
      page.update(files: [input("png")], image_width: 10, image_height: 10)
      select_output("jpg")

      expect(page.output_compression_row.visible?).to be(false)
    end

    it "offers bundling once more than one file is loaded" do
      page.update(files: [input("png"), input("png")], image_width: 10, image_height: 10)
      select_output("jpg")

      expect(page.output_compression_row.visible?).to be(true)
    end

    it "offers the multi-page PDF switch only when PDF is the output" do
      page.update(files: [input("png"), input("png")], image_width: 10, image_height: 10)
      select_output("pdf")

      expect(page.single_pdf_row.visible?).to be(true)
    end
  end

  describe "the resize unit" do
    it "shows the percentage entries and hides the pixel ones at 100%" do
      page.resize_type_dropdown.selected = 0
      page.update_resize

      expect(page.resize_scale_width_entry.visible?).to be(true)
      expect(page.resize_width_entry.visible?).to be(false)
    end

    it "swaps them when exact pixels are chosen" do
      page.resize_type_dropdown.selected = 1
      page.update_resize

      expect(page.resize_scale_width_entry.visible?).to be(false)
      expect(page.resize_width_entry.visible?).to be(true)
    end
  end

  describe "#mirror_scale" do
    before do
      page.update(files: [input("png")], image_width: 400, image_height: 200)
      page.resize_type_dropdown.selected = 0
      page.update_resize
    end

    it "copies the source percentage onto the target while the chain is closed" do
      page.link_axis.active = true
      page.resize_scale_width_entry.text = "50"
      page.send(:mirror_scale, page.resize_scale_height_entry, page.resize_scale_width_entry)

      expect(page.resize_scale_height_entry.text).to eq("50")
    end

    it "leaves the target alone once the chain is open" do
      page.link_axis.active = false
      page.resize_scale_height_entry.text = "100"
      page.resize_scale_width_entry.text = "50"
      page.send(:mirror_scale, page.resize_scale_height_entry, page.resize_scale_width_entry)

      expect(page.resize_scale_height_entry.text).to eq("100")
    end

    it "does not copy an empty source over a set target" do
      page.link_axis.active = true
      page.resize_scale_height_entry.text = "100"
      page.resize_scale_width_entry.text = ""
      page.send(:mirror_scale, page.resize_scale_height_entry, page.resize_scale_width_entry)

      expect(page.resize_scale_height_entry.text).to eq("100")
    end
  end

  describe "the stored options" do
    it "round-trips quality, dpi and the resize unit through the schema" do
      page.update(files: [input("png")], image_width: 10, image_height: 10)
      page.quality_scale.value = 40
      page.dpi_entry.text = "150"
      page.resize_type_dropdown.selected = 1
      page.save_options

      described_class.new(settings).tap do |reloaded|
        reloaded.build
        reloaded.load_options

        expect(reloaded.quality).to eq(40)
        expect(reloaded.dpi).to eq(150)
        expect(reloaded.resize_type_dropdown.selected).to eq(1)
      end
    end

    it "stores the export format as its position in the list the combo offers" do
      page.update(files: [input("png")], image_width: 10, image_height: 10)
      select_output("webp")
      page.save_options

      expect(FileType.output_formats[settings["output-format"]].extension).to eq("webp")
    end
  end
end
