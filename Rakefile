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
