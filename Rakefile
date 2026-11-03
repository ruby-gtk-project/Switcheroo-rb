# frozen_string_literal: true

# kettle-jem:freeze
# To retain chunks of comments & code during kettle-jem templating:
# Wrap custom sections with freeze markers (e.g., as above and below this comment chunk).
# kettle-jem will then preserve content between those markers across template runs.
# kettle-jem:unfreeze

# switcheroo-rb Rakefile v7.1.28 - 2026-10-11
# Ruby 2.3 (Safe Navigation) or higher required
#
# See LICENSE.md for license information.
#
# Copyright (c) 2026 ruby-gtk-project (github.com)
#
# Expected to work in any project that uses Bundler.
#
# Sets up tasks for appraisal2, floss_funding, kettle-jem, kettle-dev, rspec, minitest, rubocop_gradual, reek, yard, and stone_checksums.
#
# rake appraisal:install                      # Install Appraisal gemfiles (initial setup...
# rake appraisal:reset                        # Delete Appraisal lockfiles (gemfiles/*.gemfile.lock)
# rake appraisal:generate                     # Generate Appraisal gemfiles without resolving...
# rake appraisal:update                       # Generate and update Appraisal gemfiles
# rake bench                                  # Run all benchmarks (alias for bench:run)
# rake bench:list                             # List available benchmark scripts
# rake bench:run                              # Run all benchmark scripts (skips on CI)
# rake build:generate_checksums               # Generate both SHA256 & SHA512 checksums i...
# rake bundle:audit:check                     # Checks the Gemfile.lock for insecure depe...
# rake bundle:audit:update                    # Updates the bundler-audit vulnerability d...
# rake ci:act[opt]                            # Run 'act' with a selected workflow
# rake coverage                               # Run specs w/ coverage and open results in...
# rake default                                # Default tasks aggregator
# rake install                                # Build and install switcheroo-rb-1.0.0.gem in...
# rake install:local                          # Build and install switcheroo-rb-1.0.0.gem in...
# rake kettle:jem:install                     # Internal target used by `kettle-jem install`
# rake kettle:jem:selftest                    # Self-test: template switcheroo-rb against itse...
# rake kettle:jem:template                    # Internal target used by scoped `kettle-jem template --only`
# rake reek                                   # Check for code smells
# rake reek:update                            # Run reek and store the output into the RE...
# rake release[remote]                        # Create tag v1.0.0 and build and push kett...
# rake rubocop_gradual                        # Run RuboCop Gradual
# rake rubocop_gradual:autocorrect            # Run RuboCop Gradual with autocorrect (onl...
# rake rubocop_gradual:autocorrect_all        # Run RuboCop Gradual with autocorrect (saf...
# rake rubocop_gradual:check                  # Run RuboCop Gradual to check the lock file
# rake rubocop_gradual:force_update           # Run RuboCop Gradual to force update the l...
# rake rubocop_gradual_debug                  # Run RuboCop Gradual
# rake rubocop_gradual_debug:autocorrect      # Run RuboCop Gradual with autocorrect (onl...
# rake rubocop_gradual_debug:autocorrect_all  # Run RuboCop Gradual with autocorrect (saf...
# rake rubocop_gradual_debug:check            # Run RuboCop Gradual to check the lock file
# rake rubocop_gradual_debug:force_update     # Run RuboCop Gradual to force update the l...
# rake spec                                   # Run RSpec code examples
# rake test                                   # Run tests
# rake yard                                   # Generate YARD Documentation
# rake yard:lint                              # Lint YARD Documentation
#

# simplecov:disable
if !Dir[File.join(__dir__, "*.gemspec")].empty?
  require "bundler/gem_tasks"
end
# simplecov:enable

# Define a base default task early so other files can enhance it.
desc "Default tasks aggregator"
task :default do
  puts "Default task complete."
end

# Without this, a generated docs/ directory makes Rake resolve the bare
# name `docs` as an up-to-date file task, so `rake docs` exits 0 having
# regenerated nothing.
desc "Generate YARD documentation"
task docs: "yard"

# simplecov:disable
### MONOREPO FAMILY TASKS
if Dir.exist?(File.join(__dir__, "gems"))
  def family_gem_dirs
    Dir.glob(
      File.join(
        __dir__,
        "gems",
        "*",
        "*.gemspec",
      ),
    )
      .map { |path| File.dirname(path) }
      .uniq
      .sort_by { |path| File.basename(path) }
  end

  def run_kettle_family(*args)
    sh(
      "bundle",
      "exec",
      "kettle-family",
      *args,
    )
  end

  namespace :family do
    desc "List released Ruby subgems"
    task :list do
      family_gem_dirs.each { |path| puts File.basename(path) }
    end

    desc "Run release readiness checks for the Ruby gem family"
    task :readiness do
      run_kettle_family("check")
    end

    desc "Run tests for the Ruby gem family"
    task :test do
      run_kettle_family("test", "--execute")
    end

    desc "Run lint for the Ruby gem family"
    task :lint do
      run_kettle_family("lint", "--execute")
    end

    desc "Generate YARD docs for the Ruby gem family"
    task :docs do
      run_kettle_family("docs", "--execute")
    end

    desc "Report release state for the Ruby gem family"
    task :release_state do
      run_kettle_family("release-state")
    end

    desc "Run the Ruby gem family release planner"
    task :release do
      run_kettle_family("release")
    end

    desc "Execute the Ruby gem family release"
    task :release_execute do
      run_kettle_family("release", "--execute")
    end
  end
end
# simplecov:enable

# External gems that define tasks - add here!
begin
  require "kettle/dev"
  unless Kettle::Dev::RUNNING_AS == "rake"
    Kettle::Dev.install_tasks
  end
rescue LoadError
  warn("NOTE: kettle-dev isn't installed, or is disabled for #{RUBY_VERSION} in the current environment")
end

### TEMPLATING TASKS
# These tasks are installed for the `kettle-jem` executable. Run full templating
# through `kettle-jem install`; use `kettle-jem template --only PATH` only for
# scoped file updates. The executable prepares the environment and then
# delegates here when rake orchestration is needed.
kettle_jem_selftest_unavailable_note = nil
begin
  require "kettle/jem"
  if Kettle::Jem.respond_to?(:install_tasks)
    Kettle::Jem.install_tasks
  else
    kettle_jem_selftest_unavailable_note = "NOTE: kettle-jem #{Kettle::Jem::Version::VERSION} does not provide rake tasks in this environment"
  end
rescue LoadError
  kettle_jem_selftest_unavailable_note = "NOTE: kettle-jem isn't installed, or is disabled for #{RUBY_VERSION} in the current environment"
end

if kettle_jem_selftest_unavailable_note
  desc("(stub) kettle:jem:selftest is unavailable")
  task("kettle:jem:selftest") do
    warn(kettle_jem_selftest_unavailable_note)
  end
end

### RELEASE TASKS
# Setup stone_checksums
begin
  require "stone_checksums"
rescue LoadError
  desc("(stub) build:generate_checksums is unavailable")
  task("build:generate_checksums") do
    warn("NOTE: stone_checksums isn't installed, or is disabled for #{RUBY_VERSION} in the current environment")
  end
end

### APPLICATION INSTALL TASKS
# Ported from upstream's meson.build, data/meson.build and po/meson.build.
# Upstream's `meson install` compiles the catalogues, merges the translated
# launcher keys back into the desktop entry, installs the icons into a theme
# directory, installs the AppStream metainfo and the D-Bus service file, and
# compiles and registers the GSettings schema. These tasks do the same, so the
# port can be installed instead of only run from a checkout.
namespace :app do
  APP_ID = "io.gitlab.adhami3310.Converter"
  GETTEXT_PACKAGE = "switcheroo"
  DATA_DIR = File.expand_path("data", __dir__)
  PO_DIR = File.expand_path("po", __dir__)
  LOCALE_DIR = File.expand_path("locale", __dir__)

  def app_prefix = ENV.fetch("PREFIX", File.expand_path("~/.local"))
  def app_datadir = File.join(app_prefix, "share")
  def app_bindir = File.join(app_prefix, "bin")
  def app_linguas = File.read(File.join(PO_DIR, "LINGUAS")).split

  def app_sh(*command)
    warn(command.join(" "))
    unless system(*command)
      raise("command failed: #{command.join(" ")}")
    end
  end

  # Substitute the placeholders meson's configure_file would fill in. The port
  # has one profile, so @icon@ and @app-id@ both resolve to the release id.
  def app_configure(source, destination, substitutions)
    require "fileutils"
    FileUtils.mkdir_p(File.dirname(destination))
    File.write(
      destination,
      substitutions.reduce(File.read(source)) { |text, (from, to)| text.gsub(from, to) },
    )
  end

  # The list of extractable sources, read from po/POTFILES.in the way meson's
  # i18n.gettext() reads it: comment lines dropped, everything else a path
  # relative to the source root.
  def app_potfiles
    File.readlines(File.join(PO_DIR, "POTFILES.in"), chomp: true)
        .reject { |line| line.start_with?("#") || line.strip.empty? }
  end

  # Upstream's `switcheroo-pot` target is one xgettext run, because every file
  # in its POTFILES.in is a language GNU xgettext extracts itself. This port's
  # sources are Ruby, and GNU xgettext's `--language=Ruby` only shells out to
  # rxgettext, so the extraction is split in two and joined with msgcat:
  # rxgettext for lib/*.rb, xgettext for the three metadata files, which are
  # extracted by the same ITS rules upstream extracts them by.
  desc "Regenerate po/#{GETTEXT_PACKAGE}.pot from po/POTFILES.in"
  task :pot do
    require "fileutils"

    potfiles = app_potfiles
    ruby_sources = potfiles.grep(/\.rb\z/)
    data_sources = potfiles - ruby_sources
    pot = File.join(PO_DIR, "#{GETTEXT_PACKAGE}.pot")

    # The two intermediates are written to the source root rather than to a
    # temp directory, because rxgettext writes each `#:` reference relative to
    # the directory its output file lives in: from /tmp that gives
    # `../../../home/you/…/lib/foo.rb`, and from here it gives `lib/foo.rb`,
    # which is the form upstream's references take.
    ruby_pot = File.expand_path(".pot-ruby.tmp", __dir__)
    data_pot = File.expand_path(".pot-data.tmp", __dir__)

    begin
      app_sh(
        "rxgettext",
        "--output=#{ruby_pot}",
        "--package-name=#{GETTEXT_PACKAGE}",
        "--sort-by-file",
        *ruby_sources,
      )
      app_sh(
        "xgettext",
        "--output=#{data_pot}",
        "--from-code=UTF-8",
        "--package-name=#{GETTEXT_PACKAGE}",
        "--sort-by-file",
        *data_sources,
      )
      # xgettext leaves `charset=CHARSET` in the header it writes, which every
      # later tool warns about. The Ruby catalogue's header wins the msgcat
      # below, but msgcat still reads this one, so name the encoding the
      # `--from-code` above already asserted.
      File.write(data_pot, File.read(data_pot).sub("charset=CHARSET", "charset=UTF-8"))

      # --use-first keeps the first catalogue's header rather than stitching
      # the two headers together, so the result has one well-formed header.
      app_sh(
        "msgcat",
        "--output=#{pot}",
        "--use-first",
        "--sort-by-file",
        ruby_pot,
        data_pot,
      )
    ensure
      FileUtils.rm_f([ruby_pot, data_pot])
    end

    warn("wrote #{pot}")
  end

  # Upstream's commented-out `switcheroo-update-po` target. The language list
  # is po/LINGUAS, which is what meson's i18n.gettext() iterates and what
  # app:locale and app:install already iterate, so po/zh_cn.po — present in
  # the tree but absent from LINGUAS, exactly as upstream has it — is left
  # alone here too.
  desc "Merge po/#{GETTEXT_PACKAGE}.pot into every catalogue named in po/LINGUAS"
  task update_po: :pot do
    app_linguas.each do |lang|
      app_sh(
        "msgmerge",
        "--update",
        "--backup=none",
        "--previous",
        File.join(PO_DIR, "#{lang}.po"),
        File.join(PO_DIR, "#{GETTEXT_PACKAGE}.pot"),
      )
    end
  end

  desc "Compile po/*.po into a locale/<lang>/LC_MESSAGES/#{GETTEXT_PACKAGE}.mo tree"
  task :locale do
    require "fileutils"
    app_linguas.each do |lang|
      directory = File.join(LOCALE_DIR, lang, "LC_MESSAGES")
      FileUtils.mkdir_p(directory)
      app_sh(

        "msgfmt",
        "--check-format",
        "-o",

        File.join(directory, "#{GETTEXT_PACKAGE}.mo"),
        File.join(PO_DIR, "#{lang}.po"),

      )
    end
  end

  desc "Remove the compiled locale tree"
  task :clean_locale do
    require "fileutils"
    FileUtils.rm_rf(LOCALE_DIR)
  end

  desc "Install the app's data files and catalogues under PREFIX (default ~/.local)"
  task install: :locale do
    require "fileutils"

    # Catalogues: upstream's po/meson.build.
    app_linguas.each do |lang|
      destination = File.join(
        app_datadir,
        "locale",
        lang,
        "LC_MESSAGES",
      )
      FileUtils.mkdir_p(destination)
      FileUtils.cp(
        File.join(
          LOCALE_DIR,
          lang,
          "LC_MESSAGES",
          "#{GETTEXT_PACKAGE}.mo",
        ),
        destination,
      )
    end

    # Desktop entry: upstream's i18n.merge_file, which folds the translated
    # Name, GenericName, Comment and Keywords into the installed file.
    FileUtils.mkdir_p(File.join(app_datadir, "applications"))
    app_configure(
      File.join(DATA_DIR, "switcheroo.desktop.in"),
      "tmp/switcheroo.desktop.in",
      { "@icon@" => APP_ID },
    )
    app_sh(

      "msgfmt",
      "--desktop",
      "--template=tmp/switcheroo.desktop.in",
      "-d",

      PO_DIR,
      "-o",

      File.join(app_datadir, "applications", "#{APP_ID}.desktop"),

    )

    # AppStream metainfo: upstream's i18n.merge_file with type xml.
    FileUtils.mkdir_p(File.join(app_datadir, "metainfo"))
    app_configure(
      File.join(DATA_DIR, "#{APP_ID}.metainfo.xml.in.in"),
      "tmp/#{APP_ID}.metainfo.xml.in",
      { "@app-id@" => APP_ID, "@gettext-package@" => GETTEXT_PACKAGE },
    )
    app_sh(

      "msgfmt",
      "--xml",
      "--template=tmp/#{APP_ID}.metainfo.xml.in",
      "-d",

      PO_DIR,
      "-o",

      File.join(app_datadir, "metainfo", "#{APP_ID}.metainfo.xml"),

    )

    # D-Bus service file, which the desktop entry's DBusActivatable=true needs.
    FileUtils.mkdir_p(File.join(app_datadir, "dbus-1", "services"))
    app_configure(
      File.join(DATA_DIR, "#{APP_ID}.service.in"),
      File.join(
        app_datadir,
        "dbus-1",
        "services",
        "#{APP_ID}.service",
      ),
      { "@app-id@" => APP_ID, "@bindir@" => app_bindir },
    )

    # GSettings schema, so the keys are in dconf and gsettings/dconf-editor
    # can describe them.
    schema_dir = File.join(app_datadir, "glib-2.0", "schemas")
    FileUtils.mkdir_p(schema_dir)
    app_configure(
      File.join(DATA_DIR, "#{APP_ID}.gschema.xml.in"),
      File.join(schema_dir, "#{APP_ID}.gschema.xml"),
      { "@app-id@" => APP_ID, "@gettext-package@" => GETTEXT_PACKAGE },
    )
    app_sh("glib-compile-schemas", schema_dir)

    # Icons, into a theme directory the icon theme will find.
    FileUtils.mkdir_p(File.join(app_datadir, "icons"))
    FileUtils.cp_r(
      File.join(DATA_DIR, "icons", "hicolor"),
      File.join(app_datadir, "icons"),
      remove_destination: true,
    )

    warn(
      "installed under #{app_prefix}; " \
               "run with SWITCHEROO_LOCALEDIR=#{File.join(app_datadir, "locale")}",
    )
  end
end

desc "Compile po/*.po into locale/ (alias for app:locale)"
task locale: "app:locale"

desc "Install the app under PREFIX (alias for app:install)"
task install: "app:install"

desc "Regenerate po/switcheroo.pot (alias for app:pot)"
task pot: "app:pot"

desc "Refresh po/switcheroo.pot and merge it into every catalogue (alias for app:update_po)"
task update_po: "app:update_po"
