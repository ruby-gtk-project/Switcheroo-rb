# frozen_string_literal: true

# Config for development dependencies of this library
# i.e., not configured by this library
#
# SimpleCov & related config (must run BEFORE any other requires)
# NOTE: Gemfiles for non-coverage appraisals may not have kettle-soup-cover.
#       The rescue LoadError handles that scenario.
begin
  require "kettle-soup-cover"
  if Kettle::Soup::Cover::DO_COV
    # Requiring simplecov loads the project-local `.simplecov`.
    require "simplecov"
    require "kettle/soup/cover/config"
    SimpleCov.start
  end
rescue LoadError => error
  # check the error message and re-raise when unexpected
  unless error.message.include?("kettle")
    raise error
  end
end

# External RSpec & related config
#
# `kettle/test/rspec` installs the harness helpers documented in
# spec/README.md. It is a development-bundle gem, and the Nix dev shell the
# flake builds carries only the runtime closure plus rspec, so the suite the
# dev-shell banner names has to be able to run without it. Nothing in the
# suite calls a kettle helper today, so a missing kettle is tolerated exactly
# the way kettle-soup-cover above is — any other LoadError is still fatal.
begin
  require "kettle/test/rspec"
rescue LoadError => error
  unless error.message.include?("kettle")
    raise error
  end
end

# This library
require "switcheroo/rb"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
