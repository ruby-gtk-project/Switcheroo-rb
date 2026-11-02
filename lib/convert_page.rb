# frozen_string_literal: true

require 'adwaita'

require_relative 'translations'

require_relative 'color'
require_relative 'file_type'
require_relative 'magick'

# ConvertPage is the options page: the thumbnails, the export format, and every
# knob that becomes a `magick` argument.
#
# Ported from the "stack_convert" StackPage of upstream's
# data/resources/blueprints/window.blp together with the WindowUI,
# ConvertArguments and SettingsStore parts of src/window.rs that only ever
# touch these widgets — the conditional visibility of each row, the two linked
# resize axes, and the readers that build the job arguments.
#
# Which rows are visible is entirely derived from the formats in play:
#
# * Quality — the export format is lossy.
# * Background Color — some input carries alpha. The swatch itself is reset
#   whenever the export format changes: to all but invisible black with an
#   alpha channel when the output supports alpha, to opaque white without one
#   when it does not.
# * Pixel Density Per Inch — some input is a PDF.
# * Resize Algorithm — the inputs are not all SVGs (where resizing is
#   rasterising, so no filter applies).
# * Remove Metadata — some input carries metadata.
# * Save To ZIP / Save as multi-page PDF — the run will produce more than one
#   file, i.e. several inputs, or several frames the export format cannot keep
#   as an animation.
#
# The colour button tells a screen-reader user which colour was picked, on
# every pick, through the `notify::rgba` handler below. It is not the same
# mechanism upstream uses and that difference is not hidden: upstream writes
# the accessible Label *property* of the button's first child
# (src/window.rs:525-530), and ruby-gobject-introspection cannot call
# gtk_accessible_update_property_value — it raises NotImplementedError on the
# GtkAccessibleProperty array, and Gtk::AccessibleList is bound without
# new_from_array, so the labelled-by relation cannot be written either.
# FINDINGS.md records both with the errors they raise. What is here instead is
# gtk_accessible_announce on the same child with the same msgid, so the colour
# reaches the screen reader as an announcement rather than as a label.
#
# The quality scale's `labelled-by` relation and the resize-unit dropdown's
# accessible label (window.blp:155-159, :243-247) are set here, through the
# GtkBuilder fragments below — the only route the bindings leave open.
#
class ConvertPage
  include Translations

  LINKED_ICON = 'chain-link-symbolic'
  LOOSE_ICON = 'chain-link-loose-symbolic'

  QUALITY_MINIMUM = 1
  QUALITY_MAXIMUM = 100
  ENTRY_WIDTH_CHARS = 8
  RESIZE_SPACING = 5

  def initialize(settings)
    @settings = settings
    @files = []
  end

  def build
    page.tap do |p|
      p.add(images_group)
      p.add(output_group)
      p.add(options_group)
      p.add(convert_group)

      images_group.add(image_container)

      build_output_group
      build_options_group

      convert_group.add(convert_button)

      load_options
      update_resize
    end
  end

  def connect_convert(&block)
    convert_button.signal_connect('clicked') { block.call }
  end

  # Upstream's update_options(), called once the probe has finished: the
  # percentage entries go back to 100, the pixel entries to the shared size of
  # the loaded images (or to nothing, when they disagree), and every
  # conditional row is re-evaluated.
  def update(files:, image_width:, image_height:)
    @files = files
    @image_width = image_width
    @image_height = image_height

    resize_scale_width_entry.text = '100'
    resize_scale_height_entry.text = '100'
    apply_pixel_entries
    update_output_options
    update_advanced_options
  end

  # --- What the window asks for when a conversion starts -------------------

  def selected_output = FileType.output_formats[output_filetype.selected]

  # Upstream's selected_compression(): nil while the row is hidden, because
  # then the run produces a single file and nothing is bundled.
  def selected_compression
    if output_compression_row.visible?
      if output_compression_switch.active?
        CompressionType::ZIP
      else
        CompressionType::DIRECTORY
      end
    end
  end

  def single_pdf? = single_pdf_switch.active?
  def quality = quality_scale.value.to_i
  def dpi = dpi_entry.text.to_i
  def background = Color.from_rgba(bgcolor_button.rgba)

  def resize_filter
    if resize_filter_default.active?
      Magick::ResizeFilter.default
    else
      Magick::ResizeFilter.point
    end
  end

  def strip_type = Magick::StripType.from_active(strip_switch.active?)

  def resize_argument
    if percentage_resize?
      Magick::ResizeArgument.percentage(
        resize_scale_width_entry.text.to_i,
        resize_scale_height_entry.text.to_i,
      )
    else
      Magick::ResizeArgument.exact_pixels(
        resize_width_entry.text.to_i,
        resize_height_entry.text.to_i,
      )
    end
  end

  # Upstream's magick_arguments: one job with the input and output left blank,
  # which generate_job() then fills in per file.
  def job_defaults
    Magick::ConvertJob.new(
      input_file:      '',
      output_file:     '',
      background:      background,
      quality:         quality,
      filter:          resize_filter,
      strip:           strip_type,
      resize_argument: resize_argument,
    )
  end

  # --- Settings ------------------------------------------------------------

  # Upstream's save_options(), save_selected_output() and
  # save_selected_compression(), all three called as a run starts.
  def save_options
    @settings['quality'] = quality
    @settings['dpi'] = dpi
    @settings['resize-type'] = resize_type_dropdown.selected
    selected_output.then do |output|
      if output
        @settings['output-format'] = FileType.output_formats.index(output)
      end
    end
    selected_compression.then do |compression|
      if compression
        @settings['compression-format'] =
          CompressionType.possible_output(false).index(compression)
      end
    end
  end

  # Upstream's load_options().
  def load_options
    quality_scale.value = @settings['quality']
    dpi_entry.text = @settings['dpi'].to_s
    resize_type_dropdown.selected = @settings['resize-type']
  end

  # --- Conditional visibility ---------------------------------------------

  # Upstream's update_output_options(): the model is rebuilt from scratch and
  # the previously chosen format — or the stored one, on the first pass — is
  # selected again.
  def update_output_options
    previous = selected_output || stored_output
    output_filetype.model = Gtk::StringList.new(FileType.output_formats.map(&:display_string))
    FileType.output_formats.index(previous).then do |index|
      if index
        output_filetype.selected = index
      end
    end
    update_compression_options
  end

  # Upstream's update_compression_options().
  def update_compression_options
    selected_output.then do |output|
      if output
        apply_compression_options(output)
      end
    end
  end

  # Upstream's update_advanced_options().
  def update_advanced_options
    selected_output.then do |output|
      if output
        apply_advanced_options(output)
      end
    end
  end

  # Upstream's update_resize(): the percentage pair and the pixel pair occupy
  # the same slot in the row, and only one pair is ever visible. The chain
  # link is only offered for pixels when the images share a size, since
  # without one there is no ratio to preserve.
  def update_resize
    resize_width_entry.visible = !percentage_resize?
    resize_height_entry.visible = !percentage_resize?
    resize_scale_width_entry.visible = percentage_resize?
    resize_scale_height_entry.visible = percentage_resize?
    link_axis.visible = percentage_resize? || !dimensions.nil?
  end

  # --- Memoized widget methods --------------------------------------------

  def page = @page ||= Adwaita::PreferencesPage.new
  def images_group = @images_group ||= Adwaita::PreferencesGroup.new
  def output_group = @output_group ||= Adwaita::PreferencesGroup.new
  def options_group = @options_group ||= Adwaita::PreferencesGroup.new

  def convert_group
    @convert_group ||= Adwaita::PreferencesGroup.new.tap do |group|
      group.valign = :end
      group.halign = :center
    end
  end

  def image_container
    @image_container ||= Gtk::FlowBox.new.tap do |box|
      box.homogeneous = true
      box.hexpand = true
      box.vexpand = false
      box.column_spacing = 12
      box.row_spacing = 12
      box.selection_mode = :none
    end
  end

  def output_filetype
    @output_filetype ||= Adwaita::ComboRow.new.tap do |row|
      row.title = _('Export Format')
      row.add_css_class('output-filetype-drop')
    end
  end

  def single_pdf_row
    @single_pdf_row ||= Adwaita::ActionRow.new.tap do |row|
      row.title = _('Save as multi-page PDF')
      row.activatable_widget = single_pdf_switch
    end
  end

  def single_pdf_switch
    @single_pdf_switch ||= Gtk::Switch.new.tap do |switch|
      switch.active = false
      switch.valign = :center
    end
  end

  def output_compression_row
    @output_compression_row ||= Adwaita::ActionRow.new.tap do |row|
      row.title = _('Save To ZIP')
      row.activatable_widget = output_compression_switch
    end
  end

  def output_compression_switch
    @output_compression_switch ||= Gtk::Switch.new.tap do |switch|
      switch.active = false
      switch.valign = :center
    end
  end

  # window.blp:146-170. The scale, its adjustment and the row it is labelled by
  # come from one builder fragment because the `labelled-by` relation can only
  # be attached by whatever creates the pair; everything else about the scale is
  # set here as usual.
  def quality_builder = @quality_builder ||= Gtk::Builder.new(string: quality_markup)

  def quality_row = @quality_row ||= quality_builder.get_object('quality_row')

  def quality_adjustment
    @quality_adjustment ||= quality_builder.get_object('percentage')
  end

  def quality_scale
    @quality_scale ||= quality_builder.get_object('quality').tap do |scale|
      scale.hexpand = true
      scale.vexpand = true
      scale.digits = 0
      scale.draw_value = true
      scale.value_pos = :right
    end
  end

  def bgcolor_row
    @bgcolor_row ||= Adwaita::ActionRow.new.tap do |row|
      row.title = _('Background Color')
      row.subtitle = _('Replaces original transparency layer')
      row.activatable_widget = bgcolor_button
    end
  end

  def color_dialog
    @color_dialog ||= Gtk::ColorDialog.new.tap do |dialog|
      dialog.with_alpha = true
    end
  end

  def bgcolor_button
    @bgcolor_button ||= Gtk::ColorDialogButton.new(color_dialog).tap do |btn|
      btn.valign = :center
      btn.rgba = transparent_rgba
    end
  end

  def dpi_row
    @dpi_row ||= Adwaita::ActionRow.new.tap do |row|
      row.title = _('Pixel Density Per Inch')
      row.activatable_widget = dpi_entry
    end
  end

  def dpi_bin = @dpi_bin ||= Adwaita::Bin.new

  def dpi_entry
    @dpi_entry ||= Gtk::Entry.new.tap do |entry|
      entry.valign = :center
    end
  end

  def resize_amount_row
    @resize_amount_row ||= Adwaita::ActionRow.new.tap do |row|
      row.title = _('Resize')
    end
  end

  def resize_box = @resize_box ||= Gtk::Box.new(:horizontal, RESIZE_SPACING)

  # The four entries carry upstream's placeholder and tooltip pairs exactly as
  # window.blp:200-247 sets them — including resize_scale_height_value, whose
  # placeholder reads "Width" while its tooltip reads "Height".
  def resize_width_entry
    @resize_width_entry ||= pixel_entry(_('Width'), _('Width'))
  end

  def resize_height_entry
    @resize_height_entry ||= pixel_entry(_('Height'), _('Height'))
  end

  def resize_scale_width_entry
    @resize_scale_width_entry ||= pixel_entry(_('Width'), _('Width'))
  end

  def resize_scale_height_entry
    @resize_scale_height_entry ||= pixel_entry(_('Width'), _('Height'))
  end

  def link_axis
    @link_axis ||= Gtk::ToggleButton.new.tap do |btn|
      btn.active = true
      btn.valign = :center
      btn.icon_name = LINKED_ICON
      btn.tooltip_text = _('Preserve aspect ratio')
      btn.add_css_class('raised')
      btn.add_css_class('circular')
      btn.add_css_class('lock')
    end
  end

  def resize_type_bin = @resize_type_bin ||= Adwaita::Bin.new
  def resize_type_box = @resize_type_box ||= Gtk::Box.new(:horizontal, 0)

  # window.blp:239-250: the dropdown carries both a tooltip and an
  # `accessibility { label: … }` block, and the label can only be attached by
  # the builder that creates it.
  def resize_type_dropdown
    @resize_type_dropdown ||=
      Gtk::Builder.new(string: resize_type_markup)
                  .get_object('resize_type').tap do |dd|
        dd.valign = :center
        dd.model = Gtk::StringList.new([_('%'), _('px')])
        dd.tooltip_text = resize_units_label
        dd.add_css_class('flat')
        dd.add_css_class('unit-drop')
      end
  end

  def resize_filter_row
    @resize_filter_row ||= Adwaita::ActionRow.new.tap do |row|
      row.title = _('Resize Algorithm')
    end
  end

  def resize_filter_box
    @resize_filter_box ||= Gtk::Box.new(:horizontal, 0).tap do |box|
      box.valign = :center
      box.add_css_class('linked')
    end
  end

  def resize_filter_default
    @resize_filter_default ||= Gtk::ToggleButton.new.tap do |btn|
      btn.label = _('Default')
      btn.active = true
    end
  end

  def resize_filter_pixel
    @resize_filter_pixel ||= Gtk::ToggleButton.new.tap do |btn|
      btn.label = _('Pixel Art')
      btn.active = false
    end
  end

  def strip_row
    @strip_row ||= Adwaita::ActionRow.new.tap do |row|
      row.title = _('Remove Metadata')
      row.activatable_widget = strip_switch
    end
  end

  def strip_switch
    @strip_switch ||= Gtk::Switch.new.tap do |switch|
      switch.active = false
      switch.valign = :center
    end
  end

  def convert_button
    @convert_button ||= Gtk::Button.new.tap do |btn|
      btn.label = _('_Convert')
      btn.use_underline = true
      btn.valign = :center
      btn.halign = :end
      btn.add_css_class('suggested-action')
      btn.add_css_class('pill')
      btn.add_css_class('long')
    end
  end

  private

    def build_output_group
      output_group.tap do |group|
        group.add(output_filetype)
        group.add(single_pdf_row)
        group.add(output_compression_row)

        single_pdf_row.add_suffix(single_pdf_switch)
        output_compression_row.add_suffix(output_compression_switch)

        output_filetype.signal_connect('notify::selected') { on_output_changed }
        single_pdf_switch.signal_connect('notify::active') { update_compression_options }
      end
    end

    def build_options_group
      options_group.tap do |group|
        group.add(quality_row)
        group.add(bgcolor_row)
        group.add(dpi_row)
        group.add(resize_amount_row)
        group.add(resize_filter_row)
        group.add(strip_row)

        bgcolor_row.add_suffix(bgcolor_button)
        bgcolor_button.signal_connect('notify::rgba') { announce_bgcolor }
        strip_row.add_suffix(strip_switch)

        dpi_row.add_suffix(dpi_bin)
        dpi_bin.child = dpi_entry

        build_resize_row
        build_resize_filter_row
      end
    end

    def build_resize_row
      resize_amount_row.tap do |row|
        row.add_suffix(resize_box)
        row.add_suffix(resize_type_bin)

        resize_box.tap do |box|
          box.append(resize_width_entry)
          box.append(resize_scale_width_entry)
          box.append(link_axis)
          box.append(resize_height_entry)
          box.append(resize_scale_height_entry)

          resize_width_entry.signal_connect('changed') { update_height_from_width }
          resize_height_entry.signal_connect('changed') { update_width_from_height }
          resize_scale_width_entry.signal_connect('changed') { mirror_scale(resize_scale_height_entry, resize_scale_width_entry) }
          resize_scale_height_entry.signal_connect('changed') { mirror_scale(resize_scale_width_entry, resize_scale_height_entry) }
          link_axis.signal_connect('clicked') { on_link_axis_clicked }
        end

        resize_type_bin.child = resize_type_box
        resize_type_box.append(resize_type_dropdown)
        resize_type_dropdown.signal_connect('notify::selected') { update_resize }
      end
    end

    def build_resize_filter_row
      resize_filter_row.tap do |row|
        row.add_suffix(resize_filter_box)

        resize_filter_box.tap do |box|
          box.append(resize_filter_default)
          box.append(resize_filter_pixel)

          # Upstream keeps the pair exclusive by hand rather than grouping
          # them, so each one un-toggles the other when they agree.
          resize_filter_default.signal_connect('toggled') do
            if resize_filter_default.active? == resize_filter_pixel.active?
              resize_filter_pixel.active = !resize_filter_default.active?
            end
          end
          resize_filter_pixel.signal_connect('toggled') do
            if resize_filter_pixel.active? == resize_filter_default.active?
              resize_filter_default.active = !resize_filter_pixel.active?
            end
          end
        end
      end
    end

    def on_output_changed
      update_advanced_options
      update_compression_options
      update_resize
    end

    # Upstream's bgcolor rgba-notify handler: the hex string is substituted into
    # the *translated* message, so the lookup happens before the sub.
    def announce_bgcolor
      bgcolor_button.first_child&.announce(
        _('New transparency layer color: {}')
          .sub('{}', Color.from_rgba(bgcolor_button.rgba).hex_string),
        :medium,
      )
    end

    def resize_units_label
      _('Choose between resizing with percentages or using exact pixels')
    end

    # The builder fragments the two accessibility blocks need. The strings are
    # looked up first and escaped into the markup, rather than left to
    # GtkBuilder's own translation-domain support, which goes through GLib's
    # gettext — an entry point ruby-glib2 does not expose here.
    def quality_markup
      <<~XML
        <interface>
          <object class="GtkAdjustment" id="percentage">
            <property name="lower">#{QUALITY_MINIMUM}</property>
            <property name="upper">#{QUALITY_MAXIMUM}</property>
            <property name="value">#{QUALITY_MAXIMUM}</property>
            <property name="step-increment">1</property>
            <property name="page-increment">10</property>
          </object>
          <object class="AdwActionRow" id="quality_row">
            <property name="title">#{escape_markup(_('Quality'))}</property>
            <child type="suffix">
              <object class="GtkScale" id="quality">
                <property name="orientation">horizontal</property>
                <property name="adjustment">percentage</property>
                <accessibility>
                  <relation name="labelled-by">quality_row</relation>
                </accessibility>
              </object>
            </child>
          </object>
        </interface>
      XML
    end

    def resize_type_markup
      <<~XML
        <interface>
          <object class="GtkDropDown" id="resize_type">
            <accessibility>
              <property name="label">#{escape_markup(resize_units_label)}</property>
            </accessibility>
          </object>
        </interface>
      XML
    end

    def escape_markup(text)
      text.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
    end

    def pixel_entry(placeholder, tooltip)
      Gtk::Entry.new.tap do |entry|
        entry.valign = :center
        entry.placeholder_text = placeholder
        entry.tooltip_text = tooltip
        entry.input_purpose = :digits
        entry.max_width_chars = ENTRY_WIDTH_CHARS
        entry.hexpand = false
      end
    end

    def percentage_resize? = resize_type_dropdown.selected.zero?

    def dimensions
      if @image_width && @image_height
        [@image_width, @image_height]
      end
    end

    def apply_pixel_entries
      dimensions.then do |dims|
        if dims
          resize_width_entry.text = dims[0].to_s
          resize_height_entry.text = dims[1].to_s
        else
          resize_width_entry.text = ''
          resize_height_entry.text = ''
        end
      end
    end

    def apply_compression_options(output)
      multiple_files = @files.length > 1
      multiple_frames = multiple_files || @files.sum(&:frame_count) > 1

      if multiple_files || (multiple_frames && !output.supports_animation?)
        show_compression_options(output)
      else
        output_compression_row.visible = false
        single_pdf_row.visible = false
      end
    end

    def show_compression_options(output)
      previous = selected_compression || stored_compression
      pdf_selected = output.extension == 'pdf'

      single_pdf_row.visible = pdf_selected
      output_compression_row.visible = !pdf_selected || !single_pdf_switch.active?
      output_compression_switch.active = previous == CompressionType::ZIP
    end

    def apply_advanced_options(output)
      @files.map(&:kind).then do |kinds|
        quality_row.visible = output.lossy?
        dpi_row.visible = kinds.any? { |kind| kind.extension == 'pdf' }
        strip_row.visible = kinds.any?(&:supports_metadata?)
        resize_filter_row.visible = !kinds.all? { |kind| kind.extension == 'svg' }
        bgcolor_row.visible = kinds.any?(&:supports_alpha?)
        if bgcolor_row.visible?
          apply_background_default(output)
        end
      end
    end

    # Upstream resets the swatch on every format change: an output that keeps
    # alpha starts all but invisible, one that cannot starts opaque white and
    # the dialog stops offering an alpha channel at all.
    def apply_background_default(output)
      if output.supports_alpha?
        bgcolor_button.rgba = transparent_rgba
        color_dialog.with_alpha = true
      else
        bgcolor_button.rgba = Gdk::RGBA.new(
          1.0,
          1.0,
          1.0,
          1.0,
        )
        color_dialog.with_alpha = false
      end
    end

    # Upstream uses an alpha of 0.0000001 rather than 0 so the button still
    # reports a colour rather than "none".
    def transparent_rgba
      Gdk::RGBA.new(
        0.0,
        0.0,
        0.0,
        0.0000001,
      )
    end

    # Upstream's load_selected_output() and load_selected_compression(): the
    # stored enum value is used as a *position* in the lists the combo row and
    # the compression switch offer, which is the same number its
    # save_selected_* counterparts wrote (src/window.rs:2119-2160).
    def stored_output = FileType.output_formats[@settings['output-format']]

    def stored_compression
      CompressionType.possible_output(false)[@settings['compression-format']] ||
        CompressionType::DIRECTORY
    end

    def linked? = link_axis.active? && link_axis.visible? && !dimensions.nil?

    # Upstream's link_axis handler: re-linking copies the height percentage
    # over the width one and then re-derives the pixel width, so the two
    # axes agree again from the moment the chain closes.
    def on_link_axis_clicked
      if linked?
        link_axis.icon_name = LINKED_ICON
        mirror_scale(resize_scale_width_entry, resize_scale_height_entry)
        update_width_from_height
      else
        link_axis.icon_name = LOOSE_ICON
      end
    end

    # Copies `source`'s percentage onto `target` while the axes are linked.
    def mirror_scale(target, source)
      if link_axis.active? && link_axis.visible?
        source.text.then do |text|
          if target.text != text && !text.empty?
            target.text = text
          end
        end
      end
    end

    # Upstream's update_height_from_width().
    def update_height_from_width
      if linked?
        sync_axis(
          resize_height_entry,
          resize_width_entry,
          method(:height_from_width),
          method(:width_from_height),
        )
      end
    end

    # Upstream's update_width_from_height().
    def update_width_from_height
      if linked?
        sync_axis(
          resize_width_entry,
          resize_height_entry,
          method(:width_from_height),
          method(:height_from_width),
        )
      end
    end

    # The two directions above are mirror images. `forward` derives the target
    # from the source, `backward` derives the source from the target: when the
    # target already implies the source's value the entry is left alone, which
    # is what stops the two 'changed' handlers from bouncing off each other.
    def sync_axis(target, source, forward, backward)
      source.text.then do |source_text|
        unless source_text.empty?
          unless backward.call(target.text.to_i).to_s == source_text
            forward.call(source_text.to_i).to_s.then do |new_value|
              if target.text != new_value && new_value != '0'
                target.text = new_value
              end
            end
          end
        end
      end
    end

    def width_from_height(height) = (height.to_f * @image_width / @image_height).round
    def height_from_width(width) = (width.to_f * @image_height / @image_width).round
end
