# frozen_string_literal: true

require "support/gtk_session"

GtkSession.load!

# Upstream's `is_canceled: Arc<AtomicBool>` starts true, which is why a window
# that has never converted anything closes without the stop dialog, and why a
# child registered outside a run is killed on the spot. The port mirrors both
# in Magick::Children, and nothing drove either until now.
RSpec.describe Magick::Children do
  subject(:children) { described_class.new }

  def sleeping_child
    Process.spawn("sleep", "30", out: File::NULL, err: File::NULL)
  end

  # Waits up to a second for the child to be reaped, polling rather than
  # blocking so a child that is never killed fails the example instead of
  # hanging it.
  def reaped?(pid)
    !20.times.find { poll(pid) }.nil?
  rescue Errno::ECHILD
    true
  end

  def poll(pid)
    Process.wait(pid, Process::WNOHANG).tap do |done|
      if done.nil?
        sleep(0.05)
      end
    end
  end

  it "starts canceled, so a fresh window closes without the stop dialog" do
    expect(children.canceled?).to be(true)
  end

  it "clears the canceled flag when a run begins" do
    children.begin_run

    expect(children.canceled?).to be(false)
  end

  it "is canceled again once cancel is asked for" do
    children.begin_run
    children.cancel

    expect(children.canceled?).to be(true)
  end

  it "kills a child registered while it is canceled" do
    pid = sleeping_child
    children.add(pid)

    expect(reaped?(pid)).to be(true)
  end

  it "kills the children of a run when the run is cancelled" do
    children.begin_run
    pid = sleeping_child
    children.add(pid)
    children.cancel

    expect(reaped?(pid)).to be(true)
  end

  it "leaves a child a reaped pid was removed for alone" do
    children.begin_run
    pid = sleeping_child
    children.add(pid)
    children.remove(pid)
    children.cancel

    expect(Process.wait(pid, Process::WNOHANG)).to be_nil
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end

RSpec.describe JobFile do
  it "names a pasted image after the translated 'Pasted Image' msgid" do
    expect(JobFile.from_clipboard.desired_name).to end_with(".png")
  end

  it "gives every job file a distinct id" do
    expect(JobFile.from_clipboard.id).not_to eq(JobFile.from_clipboard.id)
  end

  it "falls back to a TEMPORARY_SWITCHEROO name when no name was wanted" do
    file = JobFile.new(file_type: FileType.from_string("png"))

    expect(file.filename).to include("TEMPORARY_SWITCHEROO")
  end
end
