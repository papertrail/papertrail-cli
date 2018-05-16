require 'test_helper'

class ConnectionTest < Minitest::Test
  let(:connection_options) { { :token => 'dummy' } }
  let(:connection) { Papertrail::Connection.new(connection_options) }

  def test_start_finish
    assert_same connection, connection.start
    assert_nil connection.finish

    block_args = nil
    connection.start {|*args| block_args = args}
    assert_equal [connection], block_args

    assert_raises { connection.finish }
  end

  def test_each_event
    skip
  end
end
