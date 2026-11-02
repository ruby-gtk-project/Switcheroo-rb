# frozen_string_literal: true

require 'adwaita'

# ConvertingPage is the progress state during a conversion run.
#
# Ported from the "stack_converting" StackPage of upstream's
# data/resources/blueprints/window.blp, together with the progress helpers of
# src/window.rs: set_convert_progress() writes "done/total" over the bar and
# moves the fraction, and set_collecting_progress() replaces the text with
# "Collecting files" for the final move/zip/merge step.
#
class ConvertingPage
  TITLE = 'Converting'
  DESCRIPTION = 'This could take a while'
  LOADING_TEXT = 'Loading…'
  COLLECTING_TEXT = 'Collecting files'
  CANCEL_LABEL = '_Cancel'

  def build
    status_page.tap do |page|
      page.child = content_box

      content_box.tap do |box|
        box.append(progress_bar)
        box.append(cancel_button)
      end
    end
  end

  def connect_cancel(&block)
    cancel_button.signal_connect('clicked') { block.call }
  end

  # Upstream's convert_start(): the bar is reset before the first job reports.
  def reset
    progress_bar.text = LOADING_TEXT
    progress_bar.fraction = 0.0
  end

  # Upstream's set_convert_progress().
  def progress(done, total)
    progress_bar.text = "#{done}/#{total}"
    progress_bar.fraction = done.to_f / total
  end

  # Upstream's set_collecting_progress().
  def collecting
    progress_bar.text = COLLECTING_TEXT
  end

  def status_page
    @status_page ||= Adwaita::StatusPage.new.tap do |page|
      page.title = TITLE
      page.description = DESCRIPTION
    end
  end

  def content_box = @content_box ||= Gtk::Box.new(:vertical, 36)

  def progress_bar
    @progress_bar ||= Gtk::ProgressBar.new.tap do |bar|
      bar.valign = :center
      bar.halign = :center
      bar.show_text = true
      bar.text = LOADING_TEXT
    end
  end

  def cancel_button
    @cancel_button ||= Gtk::Button.new.tap do |btn|
      btn.label = CANCEL_LABEL
      btn.use_underline = true
      btn.valign = :center
      btn.halign = :center
      btn.add_css_class('destructive-action')
      btn.add_css_class('pill')
    end
  end
end
