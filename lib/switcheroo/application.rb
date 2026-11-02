# frozen_string_literal: true

require_relative "../application"

module Switcheroo
  # The gem-facing name for the application object, which is what
  # `exe/switcheroo` launches.
  #
  # The port keeps the flat one-file-per-upstream-file layout the pilot port
  # established, so the implementation is the top-level App in
  # lib/application.rb (ported from upstream's src/application.rs) and this is
  # only the name it answers to inside the gem's namespace.
  Application = ::App
end
