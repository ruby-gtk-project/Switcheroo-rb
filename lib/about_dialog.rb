# frozen_string_literal: true

require 'rexml/document'

require 'adwaita'

require_relative 'config'
require_relative 'translations'

# AboutDialog is the About window.
#
# Ported from upstream's src/widgets/about_window.rs. Upstream builds the
# dialog with adw_about_dialog_new_from_appdata(), which reads the name, the
# icon, the summary, the developer, the licence, the three URLs libadwaita
# recognises and the release notes for the version it is handed out of the
# metainfo XML inside the GResource bundle. The port ships that same metainfo
# file (data/io.gitlab.adhami3310.Converter.metainfo.xml.in.in) and this class
# reads it, so the dialog is built from the appdata rather than from a second
# copy of its values: there is one metainfo file and one VERSION
# (Config::VERSION, upstream's meson.build:3), and the "What's New" section is
# whichever <release> matches it.
#
# The port has no GResource bundle for from_appdata to read, so the parse is
# done here with REXML and the fields are set through the same properties
# from_appdata sets. The translatable fields — the name and the summary — are
# looked up after they are read, because the metainfo carries the English
# source strings the catalogues are keyed on.
#
# Everything upstream adds on top of the appdata — the developer list, the
# translator credits, the two sibling apps, the two acknowledgement sections
# and the ImageMagick legal section — is added the same way it is upstream.
#
class AboutDialog
  include Translations

  # The SPDX identifiers the metainfo can carry, mapped onto Gtk::License as
  # libadwaita's from_appdata maps them.
  LICENSE_TYPES = {
    'GPL-2.0-only'  => :gpl_2_0_only,
    'GPL-2.0+'      => :gpl_2_0,
    'GPL-3.0-only'  => :gpl_3_0_only,
    'GPL-3.0+'      => :gpl_3_0,
    'LGPL-2.1-only' => :lgpl_2_1_only,
    'LGPL-3.0-only' => :lgpl_3_0_only,
    'AGPL-3.0-only' => :agpl_3_0_only,
    'Apache-2.0'    => :apache_2_0,
    'MPL-2.0'       => :mpl_2_0,
    'MIT'           => :mit_x11,
    'BSD-3-Clause'  => :bsd_3,
  }.freeze

  # Non-translatable, so upstream keeps it as a const.
  DEVELOPERS = ['Khaleel Al-Adhami <khaleel.aladhami@gmail.com>'].freeze

  def initialize(parent)
    @parent = parent
  end

  def present
    dialog.tap do |about|
      other_apps.each do |app_id, name, summary|
        about.add_other_app(app_id, name, summary)
      end

      acknowledgements.each do |title, names|
        about.add_acknowledgement_section(title, names)
      end

      about.add_legal_section(
        'ImageMagick',
        nil,
        :mit_x11,
        nil,
      )
      about.present(@parent)
    end
  end

  def dialog
    @dialog ||= Adwaita::AboutDialog.new.tap do |about|
      about.application_name = _(appdata.name)
      about.application_icon = appdata.id
      about.developer_name = appdata.developer_name
      about.version = Config::VERSION
      about.comments = _(appdata.summary)
      about.license_type = LICENSE_TYPES.fetch(appdata.project_license, :unknown)
      about.website = appdata.url('homepage')
      about.issue_url = appdata.url('bugtracker')
      about.support_url = appdata.url('help')
      about.developers = DEVELOPERS
      about.translator_credits = _('translator-credits')

      appdata.release_notes(Config::VERSION).then do |notes|
        if notes
          about.release_notes = notes
          about.release_notes_version = Config::VERSION
        end
      end
    end
  end

  def appdata = @appdata ||= Appdata.new(Config.metainfo_file)

  # Appdata reads the AppStream metainfo the port ships.
  #
  # Only the fields adw_about_dialog_new_from_appdata() consumes are exposed,
  # so the dialog above cannot drift away from what upstream's call produces.
  # The @app-id@ and @gettext-package@ placeholders meson would substitute are
  # resolved the same way Settings resolves them in the schema.
  class Appdata
    def initialize(path)
      @path = path
    end

    def id = text('/component/id').sub('@app-id@', Config::APP_ID)
    def name = text('/component/name')
    def summary = text('/component/summary')
    def developer_name = text('/component/developer/name')
    def project_license = text('/component/project_license')

    def url(type)
      document.elements["/component/url[@type='#{type}']"]&.text&.strip
    end

    # from_appdata shows the notes of the one release whose version matches,
    # which is why the About dialog's "What's New" follows Config::VERSION.
    def release_notes(version)
      document
        .elements["/component/releases/release[@version='#{version}']/description"]
        .then do |description|
          if description
            inner_markup(description)
          end
        end
    end

    private

      def document = @document ||= REXML::Document.new(File.read(@path))

      def text(path) = document.elements[path]&.text.to_s.strip

      # AdwAboutDialog's release-notes property takes the AppStream subset of
      # the description markup, which is what the element already holds.
      def inner_markup(element)
        element.children.map { |child| child.to_s }.join.strip
      end
  end

  private

    def other_apps
      [
        # Translators: Metainfo for the app Impression. <https://gitlab.com/adhami3310/Impression>
        ['io.gitlab.adhami3310.Impression', _('Impression'), _('Create bootable drives')],
        # Translators: Metainfo for the app Footage. <https://gitlab.com/adhami3310/Footage>
        ['io.gitlab.adhami3310.Footage', _('Footage'), _('Polish your videos')],
      ]
    end

    def acknowledgements
      {
        _('Code and Design Borrowed from') => [
          'GTK-Rust-Template https://gitlab.gnome.org/World/Rust/gtk-rust-template',
          'Amberol https://gitlab.gnome.org/World/amberol',
          'Upscaler https://gitlab.gnome.org/World/Upscaler',
          'Avvie https://github.com/Taiko2k/Avvie',
          'Bottles https://github.com/bottlesdevs/Bottles',
          'Loupe https://gitlab.gnome.org/GNOME/loupe',
          'Totem https://gitlab.gnome.org/GNOME/totem',
        ],
        _('Sample Image from')             => [
          'Samuel Custodio https://github.com/samuelcust/flappy-bird-assets',
        ],
      }
    end
end
