# frozen_string_literal: true

require "gio2"

require_relative "../lib/settings"
require_relative "../lib/file_type"

# Upstream stores these keys in dconf under the schema the port now ships, and
# writes the three enum keys as the *position* of the chosen value in the list
# the widget offers (src/window.rs:2119-2160). These examples pin that stored
# representation, because it is what an upgrading user's dconf already holds.
RSpec.describe Settings do
  subject(:settings) { described_class.new(settings: backed) }

  let(:schema) do
    Settings.new.send(:schema)
  end

  let(:backed) do
    Gio::Settings.new(
      schema:  schema,
      backend: Gio.memory_settings_backend_new,
      path:    described_class::SCHEMA_PATH,
    )
  end

  it "finds the schema the port ships" do
    expect(schema.keys.sort).to eq(described_class::KEYS.sort)
  end

  it "reads the schema's declared defaults" do
    expect([settings["quality"], settings["dpi"], settings["window-width"]])
      .to eq([92, 300, 750])
  end

  it "reads the boolean key as a boolean" do
    expect(settings["is-maximized"]).to be(false)
  end

  it "round-trips an integer key" do
    settings["quality"] = 42

    expect(settings["quality"]).to eq(42)
  end

  it "round-trips a boolean key" do
    settings["is-maximized"] = true

    expect(settings.maximized?).to be(true)
  end

  it "stores the enum keys as upstream's position, not as a nick" do
    settings["output-format"] = FileType.output_formats.index(FileType.from_string("png"))

    expect(settings["output-format"]).to eq(FileType::OUTPUT_KEYS.index(:png))
  end

  it "reads an enum key back as a position into the list the widget offers" do
    settings["output-format"] = 3

    expect(FileType.output_formats[settings["output-format"]].extension).to eq("gif")
  end

  it "exposes a named accessor per key" do
    settings.quality = 7

    expect(settings.quality).to eq(7)
  end

  it "refuses a key the schema does not declare" do
    expect { settings["nonsense"] }.to raise_error(ArgumentError, /no key nonsense/)
  end
end
