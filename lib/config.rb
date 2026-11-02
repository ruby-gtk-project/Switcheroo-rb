# frozen_string_literal: true

# Config holds the constants upstream's build system generates.
#
# Ported from upstream's src/config.rs.in, which meson fills in from
# meson.build: the application id, the gettext package, the locale directory,
# the package data directory, the build profile and the version. The port has
# no configure step, so the values are written here and the directories are
# resolved relative to the checkout, with an install-time override honoured for
# each one so an installed copy reads the installed files.
#
# VERSION is upstream's meson.build:3 and is the only place the app version is
# written: the About dialog and the metainfo release lookup both read it here.
#
module Config
  APP_ID = 'io.gitlab.adhami3310.Converter'
  APP_NAME = 'Switcheroo'
  GETTEXT_PACKAGE = 'switcheroo'
  VERSION = '2.6.0'
  PROFILE = ''

  class << self
    # Upstream's PKGDATADIR. The port reads its icons, its schema and its
    # metainfo straight out of data/ when running from a checkout.
    def pkgdatadir
      ENV.fetch('SWITCHEROO_PKGDATADIR', File.expand_path('../data', __dir__))
    end

    # Upstream's LOCALEDIR: a <lang>/LC_MESSAGES/<domain>.mo tree. `rake
    # locale` builds one at locale/ from po/*.po, and `rake install` puts one
    # under <prefix>/share/locale.
    def localedir
      ENV.fetch('SWITCHEROO_LOCALEDIR', File.expand_path('../locale', __dir__))
    end

    def icon_directory = File.join(pkgdatadir, 'icons')
    def metainfo_file = File.join(pkgdatadir, "#{APP_ID}.metainfo.xml.in.in")
    def schema_file = File.join(pkgdatadir, "#{APP_ID}.gschema.xml.in")
  end
end
