# frozen_string_literal: true

require 'adwaita'

require_relative 'translations'

# AllImagesPage is the second navigation page: every loaded image, four to a
# row, reachable from the "+N / Show All" tile.
#
# Ported from the "all_images" Adw.NavigationPage of upstream's
# data/resources/blueprints/window.blp. It carries its own add button and its
# own loading spinner, because files can be added from this page while the
# first page is not visible — upstream's switch_to_stack_loading_generally()
# picks whichever of the two spinners the user can actually see.
#
class AllImagesPage
  include Translations

  TAG = 'all_images'
  IMAGES_CHILD = 'all_images'
  LOADING_CHILD = 'stack_loading'
  ADD_ICON = 'plus-large-symbolic'
  SPINNER_SIZE = 32
  CHILDREN_PER_LINE = 4
  SPACING = 12
  MARGIN = 16

  def build
    page.tap do
      toolbar_view.tap do |tv|
        tv.add_top_bar(header_bar)
        tv.content = window_handle

        header_bar.pack_start(add_button)

        window_handle.child = stack

        stack.tap do |st|
          st.add_named(scroller, IMAGES_CHILD)
          st.add_named(loading_status_page, LOADING_CHILD)

          scroller.child = flow_box

          loading_status_page.child = spinner
        end
      end
    end
  end

  # Upstream's all_images_stack.set_visible_child_name calls.
  def show_images = stack.visible_child_name = IMAGES_CHILD

  def show_loading
    stack.visible_child_name = LOADING_CHILD
    spinner.start
  end

  def stop_loading = spinner.stop

  # NavigationPage takes its child and title positionally in the Ruby
  # bindings, so the toolbar view has to exist first.
  def page
    @page ||= Adwaita::NavigationPage.new(toolbar_view, _('All Images')).tap do |nav|
      nav.tag = TAG
    end
  end

  def toolbar_view = @toolbar_view ||= Adwaita::ToolbarView.new
  def header_bar = @header_bar ||= Adwaita::HeaderBar.new

  def add_button
    @add_button ||= Gtk::Button.new.tap do |btn|
      btn.icon_name = ADD_ICON
      btn.tooltip_text = _('Add Images (Ctrl+O)')
      btn.action_name = 'win.add'
      btn.add_css_class('flat')
    end
  end

  def window_handle
    @window_handle ||= Gtk::WindowHandle.new.tap do |handle|
      handle.vexpand = true
    end
  end

  def stack
    @stack ||= Gtk::Stack.new.tap do |st|
      st.transition_type = :crossfade
    end
  end

  def scroller
    @scroller ||= Gtk::ScrolledWindow.new.tap do |sw|
      sw.vexpand = true
      sw.hexpand = true
    end
  end

  def flow_box
    @flow_box ||= Gtk::FlowBox.new.tap do |box|
      box.homogeneous = true
      box.halign = :center
      box.valign = :start
      box.column_spacing = SPACING
      box.row_spacing = SPACING
      box.margin_top = MARGIN
      box.margin_bottom = MARGIN
      box.margin_start = MARGIN
      box.margin_end = MARGIN
      box.max_children_per_line = CHILDREN_PER_LINE
      box.selection_mode = :none
    end
  end

  def loading_status_page = @loading_status_page ||= Adwaita::StatusPage.new

  def spinner
    @spinner ||= Gtk::Spinner.new.tap do |sp|
      sp.valign = :center
      sp.halign = :center
      sp.width_request = SPINNER_SIZE
      sp.height_request = SPINNER_SIZE
    end
  end
end
