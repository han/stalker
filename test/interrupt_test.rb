require File.expand_path('../../lib/stalker', __FILE__)
require 'contest'
require 'mocha'
require 'thread'


class InterruptTest < Test::Unit::TestCase
  setup do
    Stalker.clear!
    $result = -1
    $handled = false
    Stalker.job('my.job') { |args| args["timeout"].to_i.times { sleep 1 }; $result = args["val"]; puts "done" }
    flush
    Thread.new do safe_harakiri end
  end

  def safe_harakiri(timeout=1)
    # puts
    # puts "katana in position, waiting for inspiration."
    sleep timeout
    # puts "today is a good day to die"
    Process.kill("TERM", $$)
  end

  def flush
    loop do
      begin
        Stalker.beanstalk.reserve(1).delete
      rescue Beanstalk::TimedOut
        break
      end
    end
  end

  test "receiving an interrupt signal will allow finishing a job" do
    begin
      Stalker.enqueue('my.job', "val" => "done", "timeout" => 2)
      Stalker.work
      # puts $result.inspect
      assert_equal "done", $result
    ensure
      flush
    end
  end

  test "receiving an interrupt signal will stop processing new jobs" do
    puts "starting test"
    begin
      Stalker.enqueue('my.job', "val" => "first", "timeout" => 2)
      Stalker.enqueue('my.job', "val" => "second", "timeout" => 2)
      Stalker.work
      assert_equal "first", $result
      next_job = Stalker.beanstalk.reserve(1)
      name, args = JSON.parse next_job.body
      assert_equal 'my.job', name
      assert_equal "second", args["val"]
      next_job.delete
    ensure
      flush
    end
  end

end
