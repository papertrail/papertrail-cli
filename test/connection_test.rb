require 'test_helper'

class ConnectionTest < Minitest::Test
  let(:connection_options) { { :token => 'dummy' } }
  let(:connection) { Papertrail::Connection.new(connection_options) }

  def test_each_event
    skip
  end
end
