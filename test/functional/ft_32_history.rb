
#
# Testing Ruote (OpenWFEru)
#
# Sun Oct  4 00:14:27 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/log/fs_history'
require 'ruote/part/no_op_participant'


class FtHistoryTest < Test::Unit::TestCase
  include FunctionalBase

  def test_launch

    pdef = Ruote.process_definition do
      alpha
      echo 'done.'
    end

    history = @engine.add_service(:s_history, Ruote::FsHistory)

    @engine.register_participant :alpha, Ruote::NoOpParticipant

    #noisy

    wfid0 = assert_trace(pdef, "done.")
    wfid1 = assert_trace(pdef, "done.\ndone.")

    lines = File.readlines(Dir['work/log/*'].first)

    assert_equal 8, lines.size
    #lines.each { |l| puts l }

    h = history.process_history(wfid0)
    #h.each { |r| p r }
    assert_equal 4, h.size
    assert_equal Time, h.first.first.class

    fei = h[1][-2]
    assert_equal Ruote::FlowExpressionId, fei.class
    assert_equal wfid0, fei.wfid
    assert_equal '0_0', fei.expid
    assert_equal 'engine', fei.engine_id
  end

  def test_subprocess

    pdef = Ruote.process_definition :name => 'test', :revision => '3' do
      sequence do
        sub0
        echo 'done.'
      end
      define 'sub0' do
        alpha
      end
    end

    @engine.add_service(:s_history, Ruote::FsHistory)

    @engine.register_participant :alpha, Ruote::NoOpParticipant

    #noisy

    wfid0 = assert_trace(pdef, "done.")

    sleep 0.100

    #dump_history

    h = @engine.history.process_history(wfid0)
    #h.each { |r| p r }
    assert_equal 5, h.size
  end

  def test_errors

    pdef = Ruote.process_definition :name => 'test' do
      nada
    end

    @engine.add_service(:s_history, Ruote::FsHistory)

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    #dump_history

    h = @engine.history.process_history(wfid)
    #h.each { |r| p r }
    assert_equal 2, h.size
  end

  protected

  def dump_history

    lines = File.readlines(Dir['work/log/*'].first)
    puts; lines.each { |l| puts l }
  end
end
