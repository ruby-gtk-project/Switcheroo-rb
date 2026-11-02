# frozen_string_literal: true

require 'gettext'

require_relative 'config'

# Translations binds the port to upstream's gettext catalogues.
#
# Upstream calls setlocale/bindtextdomain/textdomain in src/main.rs and then
# marks its messages with gettextrs' gettext() and pgettext(). ruby-glib2 here
# does not expose the C entry points (`GLib.respond_to?(:bindtextdomain)` is
# false), so the lookups go through the `gettext` gem, which reads the same
# compiled `.mo` catalogues from the same `<lang>/LC_MESSAGES/<domain>.mo`
# layout. The msgids are upstream's bytes, so the 20 catalogues in po/ answer
# them unchanged.
#
# `_()` is upstream's gettext() and `p_(context, id)` is its pgettext(), which
# the seven shortcut-window messages need because they carry a msgctxt.
#
# A class that shows text includes this module; one that looks a message up
# from a class method extends it as well, because the gem resolves the bound
# domain through the ancestors of the receiver's class.
#
module Translations
  include GetText

  bindtextdomain(Config::GETTEXT_PACKAGE, path: Config.localedir)
end
