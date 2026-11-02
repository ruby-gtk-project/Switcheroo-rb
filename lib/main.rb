#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'application'

# Entry point, ported from upstream's src/main.rs.
#
# Upstream's main() sets the locale up, binds the gettext domain, names the
# application and registers the GResource bundle before constructing the app.
# All of that happens in App itself here — the port has no resource bundle to
# register, and the rest belongs with the application object — so what is left
# is the single expression the house style asks for.
App.new.build.run
