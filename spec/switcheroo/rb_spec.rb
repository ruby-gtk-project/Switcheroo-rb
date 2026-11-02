# frozen_string_literal: true

require_relative "../../lib/switcheroo/rb"

# The one example that needs no display: it exercises the harness itself, which
# could not run at all before lib/switcheroo/rb.rb existed — spec_helper.rb
# requires "switcheroo/rb" and died in the require.
RSpec.describe Switcheroo::Rb do
  it "reports the gem version" do
    expect(described_class.version).to eq(Switcheroo::Rb::Version::VERSION)
  end

  it "matches the version the gemspec reads" do
    expect(described_class.version).to match(/\A\d+\.\d+\.\d+/)
  end
end
