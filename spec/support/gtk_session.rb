# frozen_string_literal: true

# GtkSession loads the port's widget tree for the examples that need one.
#
# `require "adwaita"` calls gtk_init, which fails with Gtk::InitError when
# there is no display, so every example that touches a widget would be
# unrunnable on a headless machine. GTK ships a display server that needs no
# graphics hardware — gtk4-broadwayd — so when no X11 or Wayland display is
# present and that binary is on PATH, one is started here and torn down with
# the suite.
#
# Nothing is skipped: if neither a real display nor gtk4-broadwayd is
# available, gtk_init fails and the examples fail with it, which is the honest
# outcome. The port's plain-Ruby examples do not go through this file at all.
module GtkSession
  DISPLAY_NUMBER = 93
  SOCKET = "#{ENV.fetch("XDG_RUNTIME_DIR", "/tmp")}/broadway#{DISPLAY_NUMBER + 1}.socket"
  STARTUP_TIMEOUT = 10

  class << self
    def load!
      @load ||= begin
        unless display?
          provide_display
        end
        require "switcheroo"
        Adwaita.init
        true
      end
    end

    # A Gtk::Application the window examples can be built against. It is never
    # run, only registered: `AppWindow#build` needs an application to belong
    # to, and GTK warns about a window added to one that has not emitted
    # ::startup yet.
    def application
      @application ||= begin
        load!
        Gtk::Application.new("io.gitlab.adhami3310.Converter.Spec", :non_unique)
                        .tap(&:register)
      end
    end

    private

      def display? = !ENV["DISPLAY"].to_s.empty? || !ENV["WAYLAND_DISPLAY"].to_s.empty?

      def provide_display
        @pid = Process.spawn(
          "gtk4-broadwayd",
          ":#{DISPLAY_NUMBER}",
          out: File::NULL,
          err: File::NULL,
        )
        at_exit { stop }
        wait_for_socket
        ENV["GDK_BACKEND"] = "broadway"
        ENV["BROADWAY_DISPLAY"] = ":#{DISPLAY_NUMBER}"
      end

      def wait_for_socket
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + STARTUP_TIMEOUT
        until File.socket?(SOCKET)
          if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
            raise "gtk4-broadwayd did not open #{SOCKET} within #{STARTUP_TIMEOUT}s"
          end

          sleep 0.05
        end
      end

      def stop
        if @pid
          Process.kill("TERM", @pid)
          Process.wait(@pid)
          @pid = nil
        end
      rescue Errno::ESRCH, Errno::ECHILD
        @pid = nil
      end
  end
end
