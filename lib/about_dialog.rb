# frozen_string_literal: true

require 'adwaita'

# AboutDialog is the About window.
#
# Ported from upstream's src/widgets/about_window.rs. Upstream builds the
# dialog with adw_about_dialog_new_from_appdata(), which reads the name,
# summary, licence and URLs out of the metainfo XML inside the GResource
# bundle. The port has no bundle, so the same fields are set directly from the
# values data/io.gitlab.adhami3310.Converter.metainfo.xml.in.in declares, and
# everything upstream adds on top of the appdata — the developer list, the
# translator credits, the two sibling apps, the two acknowledgement sections
# and the ImageMagick legal section — is added the same way it is upstream.
#
class AboutDialog
  APP_NAME = 'Switcheroo'
  APP_ICON = 'io.gitlab.adhami3310.Converter'
  VERSION = '2.6.0'
  COMMENTS = 'Convert and manipulate images'
  COPYRIGHT = '© 2023 Khaleel Al-Adhami'
  LICENSE_TYPE = :gpl_3_0_only
  WEBSITE = 'https://apps.gnome.org/Converter/'
  ISSUE_URL = 'https://gitlab.com/adhami3310/Switcheroo/-/issues'
  SUPPORT_URL = 'https://matrix.to/#/@khaleela:gnome.org'

  # Non-translatable, so upstream keeps it as a const.
  DEVELOPERS = ['Khaleel Al-Adhami <khaleel.aladhami@gmail.com>'].freeze

  OTHER_APPS = [
    ['io.gitlab.adhami3310.Impression', 'Impression', 'Create bootable drives'],
    ['io.gitlab.adhami3310.Footage', 'Footage', 'Polish your videos'],
  ].freeze

  ACKNOWLEDGEMENTS = {
    'Code and Design Borrowed from' => [
      'GTK-Rust-Template https://gitlab.gnome.org/World/Rust/gtk-rust-template',
      'Amberol https://gitlab.gnome.org/World/amberol',
      'Upscaler https://gitlab.gnome.org/World/Upscaler',
      'Avvie https://github.com/Taiko2k/Avvie',
      'Bottles https://github.com/bottlesdevs/Bottles',
      'Loupe https://gitlab.gnome.org/GNOME/loupe',
      'Totem https://gitlab.gnome.org/GNOME/totem',
    ],
    'Sample Image from'             => [
      'Samuel Custodio https://github.com/samuelcust/flappy-bird-assets',
    ],
  }.freeze

  def initialize(parent)
    @parent = parent
  end

  def present
    dialog.tap do |about|
      OTHER_APPS.each do |app_id, name, summary|
        about.add_other_app(app_id, name, summary)
      end

      ACKNOWLEDGEMENTS.each do |title, names|
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
      about.application_name = APP_NAME
      about.application_icon = APP_ICON
      about.version = VERSION
      about.comments = COMMENTS
      about.copyright = COPYRIGHT
      about.license_type = LICENSE_TYPE
      about.website = WEBSITE
      about.issue_url = ISSUE_URL
      about.support_url = SUPPORT_URL
      about.developers = DEVELOPERS
      about.translator_credits = 'translator-credits'
    end
  end
end
