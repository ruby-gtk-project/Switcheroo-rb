# frozen_string_literal: true

require 'adwaita'

# Style is the app's stylesheet.
#
# Ported from upstream's data/resources/style.css, rule for rule. Upstream
# ships it inside the GResource bundle and loads it from there; the port has no
# bundle, so the CSS lives here as a string and goes in through a
# Gtk::CssProvider at the display's application priority.
#
# The rules are what makes the thumbnails read as cards (rounded `card-content`
# with a tinted `image-caption` strip), what keeps the chain-link toggle square
# (`lock`), what gives the Convert button its wide padding (`long`), what makes
# the "+N" count large (`large_number`), and what stops the unit and
# export-format dropdowns from reserving a menu-width popover (`unit-drop`,
# `output-filetype-drop`).
#
module Style
  CSS = <<~CSS
    row.property label.title {
      opacity: 0.55;
      font-size: smaller;
    }

    row.property label.subtitle {
      opacity: 1;
      font-size: 11pt;
    }

    /* DragOverlay's real CSS node name, matching upstream's class_init
       (src/drag_overlay.rs:30). See lib/drag_overlay.rb. */
    dragoverlay {
      box-shadow: none;
    }

    .drag-overlay-status-page {
      background-color: alpha(var(--accent-bg-color), 0.5);
      color: var(--accent-fg-color);
    }

    .card-content {
      border-radius: 60px;
    }

    flowboxchild:focus {
      border-radius: 15px;
    }

    .image-caption {
      border-top: 1px solid var(--border-color);
      background-color: var(--thumbnail-bg-color);
      padding: 2pt 0;
    }

    .image-remove {
      margin: 5px;
    }

    .image-remove:focus {
      outline-color: alpha(var(--accent-color), 0.5);
    }

    .image-rest-button:focus {
      outline-offset: 2px;
    }

    value {
      min-width: 2em;
    }

    .lock {
      min-height: 30px;
      min-width: 30px;
    }

    .large_number {
      font-size: 36pt;
    }

    .unit-drop .menu contents {
      min-width: 0px;
    }

    .long {
      padding-right: 70px;
      padding-left: 70px;
    }

    .no-padding {
      padding: 0;
    }

    .output-filetype-drop popover > contents {
      min-width: 7em;
    }

    @media (prefers-contrast: more) {
      .image-remove:focus {
        outline-color: alpha(var(--accent-color), 0.8);
      }
    }
  CSS

  class << self
    # Installs the stylesheet on the default display. Calling it more than once
    # is harmless: the same provider object is reused.
    def load
      Gdk::Display.default.then do |display|
        if display
          Gtk::StyleContext.add_provider_for_display(
            display,
            provider,
            Gtk::StyleProvider::PRIORITY_APPLICATION,
          )
        end
      end
    end

    def provider
      @provider ||= Gtk::CssProvider.new.tap do |css|
        css.load(data: CSS)
      end
    end
  end
end
