# frozen_string_literal: true

require_relative "../lib/file_type"

# Upstream's src/filetypes.rs. The output-format list's *order* is load-bearing
# twice over: it is what the export combo row shows, and it is the number the
# output-format setting stores.
RSpec.describe FileType do
  it "offers the thirteen output formats in upstream's alphabetical order" do
    expect(described_class.output_formats.map(&:extension))
      .to eq(%w[avif bmp dds gif heic heif ico jpg jxl pdf png tiff webp])
  end

  it "normalises jpeg onto jpg, as upstream's from_string does" do
    expect(described_class.from_string("jpeg")).to eq(described_class.from_string("jpg"))
  end

  it "reads the non-standard image/jpg mimetype as jpg" do
    expect(described_class.from_mimetype("image/jpg").extension).to eq("jpg")
  end

  it "knows which outputs are lossy" do
    expect(described_class.from_string("png").lossy?).to be(false)
    expect(described_class.from_string("jpg").lossy?).to be(true)
  end

  it "knows which formats keep an alpha channel" do
    expect(described_class.from_string("png").supports_alpha?).to be(true)
    expect(described_class.from_string("jpg").supports_alpha?).to be(false)
  end

  it "knows which formats carry metadata" do
    expect(described_class.from_string("ico").supports_metadata?).to be(false)
    expect(described_class.from_string("png").supports_metadata?).to be(true)
  end

  it "returns nothing for a format it does not know" do
    expect(described_class.from_string("qoi")).to be_nil
  end
end

RSpec.describe CompressionType do
  it "offers ZIP and a directory outside a sandbox, in upstream's order" do
    expect(described_class.possible_output(false).map(&:extension)).to eq(%w[zip directory])
  end

  it "offers only ZIP inside a sandbox" do
    expect(described_class.possible_output(true).map(&:extension)).to eq(%w[zip])
  end

  it "puts the directory at the position the schema's Dir default names" do
    expect(described_class.possible_output(false).index(described_class::DIRECTORY)).to eq(1)
  end
end
